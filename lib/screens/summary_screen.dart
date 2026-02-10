import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:vibration/vibration.dart';

class SummaryScreen extends StatefulWidget {
  final Map<String, dynamic> stats;

  const SummaryScreen({super.key, required this.stats});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    Vibration.vibrate(duration: 100);
    Future.delayed(const Duration(milliseconds: 50), () => Vibration.vibrate(duration: 100));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayTime = (widget.stats['today_time'] as int) / 3600;
    final accuracy = widget.stats['accuracy'] as double;
    final subjects = widget.stats['subject_breakdown'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'MISSION REPORT',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 350,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.secondary),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow(
                          theme,
                          'TIME',
                          '${todayTime.toStringAsFixed(2)}h',
                        ),
                        const Divider(color: Color(0xFF333333)),
                        _buildStatRow(
                          theme,
                          'ACCURACY',
                          '${accuracy.toStringAsFixed(0)}%',
                        ),
                        const Divider(color: Color(0xFF333333)),
                        const SizedBox(height: 20),
                        Text(
                          'SUBJECT BREAKDOWN',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...subjects.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.key,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  '${((e.value as int) / 60).toStringAsFixed(0)}m',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'RETURN TO BASE',
                        style: theme.textTheme.displayMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 24),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
