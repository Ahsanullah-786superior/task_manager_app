import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high }

enum TaskFilter { all, completed, pending }

TaskPriority priorityFromString(String value) {
  switch (value) {
    case 'high':
      return TaskPriority.high;
    case 'medium':
      return TaskPriority.medium;
    default:
      return TaskPriority.low;
  }
}

String priorityToString(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return 'high';
    case TaskPriority.medium:
      return 'medium';
    case TaskPriority.low:
      return 'low';
  }
}

class Task {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    this.isCompleted = false,
    required this.createdAt,
  });

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priorityToString(priority),
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      priority: priorityFromString(map['priority'] ?? 'low'),
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory Task.fromSnapshot(DocumentSnapshot snap) {
    return Task.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }
}
