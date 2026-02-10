import 'package:flutter/material.dart';

class EventBanner extends StatelessWidget {
  final String event;

  const EventBanner({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.error, Colors.transparent],
        ),
        border: Border(
          left: BorderSide(color: theme.colorScheme.error, width: 4),
        ),
      ),
      child: Text(
        event,
        style: theme.textTheme.displayMedium?.copyWith(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
