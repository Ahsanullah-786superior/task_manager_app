import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskFilterBar extends StatelessWidget {
  final TaskFilter selected;
  final ValueChanged<TaskFilter> onChanged;

  const TaskFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: TaskFilter.values.map((f) {
          final isSelected = f == selected;
          final label = switch (f) {
            TaskFilter.all => 'All',
            TaskFilter.completed => 'Completed',
            TaskFilter.pending => 'Pending',
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onChanged(f),
            ),
          );
        }).toList(),
      ),
    );
  }
}
