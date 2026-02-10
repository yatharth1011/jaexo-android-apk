import 'package:flutter/material.dart';
import '../models/profile.dart';

class PausedTaskBanner extends StatelessWidget {
  final TaskItem task;
  final int elapsedSeconds;
  final VoidCallback onResume;

  const PausedTaskBanner({
    super.key,
    required this.task,
    required this.elapsedSeconds,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = Duration(seconds: elapsedSeconds);
    final timeStr = '${time.inHours.toString().padLeft(2, '0')}:'
        '${(time.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(time.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF222222), Colors.transparent],
        ),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'PAUSED: ${task.text} ($timeStr)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFFFBB00),
                fontSize: 12,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: onResume,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.error),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
            child: Text(
              'RESUME',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
