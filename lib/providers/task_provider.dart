import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  String? _userId;

  List<Task> get tasks {
    switch (_filter) {
      case TaskFilter.completed:
        return _tasks.where((t) => t.isCompleted).toList();
      case TaskFilter.pending:
        return _tasks.where((t) => !t.isCompleted).toList();
      case TaskFilter.all:
        return _tasks;
    }
  }

  TaskFilter get filter => _filter;

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  CollectionReference get _tasksRef => _firestore.collection('tasks');

  /// Call once when the signed-in user changes (e.g. from a wrapper widget)
  /// to start listening to that user's tasks in real time.
  void bindToUser(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _tasksRef
        .where('userId', isEqualTo: userId)
        .orderBy('dueDate')
        .snapshots()
        .listen((snapshot) {
      _tasks = snapshot.docs.map((doc) => Task.fromSnapshot(doc)).toList();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Task stream error: $e');
    });
  }

  void clear() {
    _tasks = [];
    _userId = null;
    notifyListeners();
  }

  Future<void> addTask({
    required String userId,
    required String title,
    required String description,
    required DateTime dueDate,
    required TaskPriority priority,
  }) async {
    final id = const Uuid().v4();
    final task = Task(
      id: id,
      userId: userId,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    await _tasksRef.doc(id).set(task.toMap());
    await _notificationService.scheduleTaskReminders(task);
  }

  Future<void> updateTask(Task updated) async {
    await _tasksRef.doc(updated.id).update(updated.toMap());
    await _notificationService.cancelTaskReminders(updated.id);
    if (!updated.isCompleted) {
      await _notificationService.scheduleTaskReminders(updated);
    }
  }

  Future<void> toggleComplete(Task task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updated);
  }

  Future<void> deleteTask(Task task) async {
    await _tasksRef.doc(task.id).delete();
    await _notificationService.cancelTaskReminders(task.id);
  }
}
