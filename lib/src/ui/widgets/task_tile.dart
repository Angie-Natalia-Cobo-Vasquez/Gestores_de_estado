import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task_model.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = task.completed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: completed
            ? theme.colorScheme.primary.withOpacity(0.12)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: completed
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withOpacity(0.4),
                      width: 2,
                    ),
                    color: completed
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: completed
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: (theme.textTheme.titleMedium ?? const TextStyle())
                            .copyWith(
                          decoration:
                              completed ? TextDecoration.lineThrough : null,
                          color: completed
                              ? theme.colorScheme.primary.darken()
                              : theme.textTheme.titleMedium?.color ??
                                  const Color(0xFF1B3A65),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Actualizada ${DateFormat('dd MMM • HH:mm', 'es').format(task.updatedAt.toLocal())}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Editar',
                  icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: Icon(Icons.delete_outline, color: Colors.redAccent.shade200),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _ColorUtils on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
