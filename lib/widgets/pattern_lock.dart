import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class PatternLock extends StatefulWidget {
  final Function(List<int>) onPatternComplete;
  final String? errorMessage;

  const PatternLock({
    super.key,
    required this.onPatternComplete,
    this.errorMessage,
  });

  @override
  State<PatternLock> createState() => _PatternLockState();
}

class _PatternLockState extends State<PatternLock> {
  final List<int> _pattern = [];
  final Set<int> _visited = {};
  Offset? _currentDragPosition;

  void _onPanUpdate(DragUpdateDetails details, Size gridSize, Offset gridOffset) {
    setState(() {
      _currentDragPosition = details.globalPosition;
    });

    final localPos = details.globalPosition - gridOffset;
    final cellSize = gridSize.width / 3;

    for (int i = 0; i < 9; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      final cellCenter = Offset(
        col * cellSize + cellSize / 2,
        row * cellSize + cellSize / 2,
      );

      final distance = (localPos - cellCenter).distance;
      if (distance < cellSize / 2 && !_visited.contains(i)) {
        _visited.add(i);
        _pattern.add(i);
        Vibration.vibrate(duration: 20, amplitude: 50);
        break;
      }
    }
  }

  void _onPanEnd() {
    if (_pattern.length >= 4) {
      widget.onPatternComplete(_pattern);
    } else {
      Vibration.vibrate(duration: 200, amplitude: 128);
    }
    setState(() {
      _pattern.clear();
      _visited.clear();
      _currentDragPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              widget.errorMessage!,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        SizedBox(
          width: 300,
          height: 300,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanUpdate: (details) {
                  final renderBox = context.findRenderObject() as RenderBox;
                  final gridOffset = renderBox.localToGlobal(Offset.zero);
                  _onPanUpdate(details, constraints.biggest, gridOffset);
                },
                onPanEnd: (_) => _onPanEnd(),
                child: CustomPaint(
                  painter: PatternPainter(
                    pattern: _pattern,
                    visited: _visited,
                    currentDragPosition: _currentDragPosition,
                    primaryColor: primaryColor,
                  ),
                  child: Container(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PatternPainter extends CustomPainter {
  final List<int> pattern;
  final Set<int> visited;
  final Offset? currentDragPosition;
  final Color primaryColor;

  PatternPainter({
    required this.pattern,
    required this.visited,
    required this.currentDragPosition,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 3;
    final dotPaint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final visitedPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 9; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      final center = Offset(
        col * cellSize + cellSize / 2,
        row * cellSize + cellSize / 2,
      );

      canvas.drawCircle(
        center,
        visited.contains(i) ? 20 : 15,
        visited.contains(i) ? visitedPaint : dotPaint,
      );
    }

    for (int i = 0; i < pattern.length - 1; i++) {
      final start = _getCenter(pattern[i], cellSize);
      final end = _getCenter(pattern[i + 1], cellSize);
      canvas.drawLine(start, end, linePaint);
    }

    if (pattern.isNotEmpty && currentDragPosition != null) {
      final lastCenter = _getCenter(pattern.last, cellSize);
      canvas.drawLine(lastCenter, currentDragPosition!, linePaint);
    }
  }

  Offset _getCenter(int index, double cellSize) {
    final row = index ~/ 3;
    final col = index % 3;
    return Offset(
      col * cellSize + cellSize / 2,
      row * cellSize + cellSize / 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
