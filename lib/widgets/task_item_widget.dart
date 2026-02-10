import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../models/profile.dart';

class TaskItemWidget extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onToggle;
  final Function(TaskItem) onUpdate;
  final VoidCallback onDelete;
  final Function(int) onReorder;
  final VoidCallback onEngage;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onUpdate,
    required this.onDelete,
    required this.onReorder,
    required this.onEngage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF191919).withOpacity(0.7),
        border: Border.all(
          color: task.done ? theme.colorScheme.secondary : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                color: theme.colorScheme.secondary,
                onPressed: () {
                  onReorder(-1);
                  Vibration.vibrate(duration: 15);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                color: theme.colorScheme.secondary,
                onPressed: () {
                  onReorder(1);
                  Vibration.vibrate(duration: 15);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              task.done ? Icons.check_box : Icons.check_box_outline_blank,
              color: theme.colorScheme.primary,
            ),
            onPressed: onToggle,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: TextEditingController(text: task.text)
                    ..selection = TextSelection.collapsed(offset: task.text.length),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: task.done ? TextDecoration.lineThrough : null,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    onUpdate(TaskItem(
                      id: task.id,
                      text: value,
                      tag: task.tag,
                      mode: task.mode,
                      done: task.done,
                      createdAt: task.createdAt,
                    ));
                  },
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        task.tag,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: task.mode,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
                      dropdownColor: Colors.black,
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(value: 'offline', child: Text('OFFLINE')),
                        DropdownMenuItem(value: 'focus', child: Text('FOCUS')),
                        DropdownMenuItem(value: 'training', child: Text('TRAINING')),
                        DropdownMenuItem(value: 'online_test', child: Text('ONLINE TEST')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          onUpdate(TaskItem(
                            id: task.id,
                            text: task.text,
                            tag: task.tag,
                            mode: value,
                            done: task.done,
                            createdAt: task.createdAt,
                          ));
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!task.done && task.mode != 'offline')
            OutlinedButton(
              onPressed: onEngage,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.error),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              ),
              child: Text(
                'ENGAGE',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 10,
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.delete, color: const Color(0xFF333333)),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    backgroundColor: Colors.black,
                    title: Text('DELETE TASK?', style: theme.textTheme.displayMedium),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text('YES', style: TextStyle(color: theme.colorScheme.error)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('NO', style: TextStyle(color: theme.colorScheme.primary)),
                      ),
                    ],
                  );
                },
              );
              if (confirmed == true) {
                onDelete();
              }
            },
          ),
        ],
      ),
    );
  }
}
