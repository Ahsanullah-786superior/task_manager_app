import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/task_provider.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/task_tile.dart';
import 'add_edit_task_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => context.read<app_auth.AuthProvider>().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          TaskFilterBar(
            selected: taskProvider.filter,
            onChanged: (f) => taskProvider.setFilter(f),
          ),
          Expanded(
            child: tasks.isEmpty
                ? _EmptyState(filter: taskProvider.filter)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskTile(
                        task: task,
                        onToggleComplete: () =>
                            taskProvider.toggleComplete(task),
                        onEdit: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddEditTaskScreen(task: task),
                          ),
                        ),
                        onDelete: () => taskProvider.deleteTask(task),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final TaskFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      TaskFilter.all => 'No tasks yet.\nTap "Add Task" to create one.',
      TaskFilter.completed => 'No completed tasks yet.',
      TaskFilter.pending => 'No pending tasks. Nice work!',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
