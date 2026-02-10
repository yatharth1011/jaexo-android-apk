import 'package:flutter/material.dart';

class BatteryBar extends StatelessWidget {
  final int level;
  final bool isCharging;

  const BatteryBar({
    super.key,
    required this.level,
    required this.isCharging,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCharging ? Colors.green : theme.colorScheme.primary;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 2,
        color: Colors.black,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: level / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
