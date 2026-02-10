import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../managers/profile_manager.dart';

class HUDScreen extends StatefulWidget {
  final TaskItem task;
  final int initialElapsed;
  final int initialQuestion;
  final int initialCorrect;
  final int initialScore;
  final int questionCount;

  const HUDScreen({
    super.key,
    required this.task,
    this.initialElapsed = 0,
    this.initialQuestion = 1,
    this.initialCorrect = 0,
    this.initialScore = 0,
    this.questionCount = 15,
  });

  @override
  State<HUDScreen> createState() => _HUDScreenState();
}

class _HUDScreenState extends State<HUDScreen> {
  late int _elapsedSeconds;
  late int _questionTime;
  late int _currentQuestion;
  late int _correctCount;
  late int _score;

  Timer? _timer;
  bool _showReport = false;

  final TextEditingController _marksController = TextEditingController();
  final TextEditingController _totalMarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();

    _elapsedSeconds = widget.initialElapsed;
    _questionTime = 0;
    _currentQuestion = widget.initialQuestion;
    _correctCount = widget.initialCorrect;
    _score = widget.initialScore;

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _marksController.dispose();
    _totalMarksController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds++;
        _questionTime++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showReport) {
      return _buildReportView();
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.98),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.task.mode.toUpperCase()} ACTIVE',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  letterSpacing: 4,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _formatTime(_elapsedSeconds),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              if (widget.task.mode == 'training') ...[
                const SizedBox(height: 10),
                Text(
                  'Q_$_currentQuestion | ${_formatTime(_questionTime)} | SCR: ${_score >= 0 ? "+$_score" : _score}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _score >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
                    fontSize: 16,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                widget.task.text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 30),
              _buildControls(theme),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _abort,
                child: Text(
                  'ABORT OPERATION',
                  style: TextStyle(color: const Color(0xFF555555), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    if (widget.task.mode == 'training') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _actionButton(theme, 'CORRECT\n(+4)', _handleCorrect, theme.colorScheme.primary)),
              const SizedBox(width: 10),
              Expanded(child: _actionButton(theme, 'RETRY\n(-1)', _handleRetry, theme.colorScheme.error)),
              const SizedBox(width: 10),
              Expanded(child: _actionButton(theme, 'SKIP\n(0)', _handleSkip, const Color(0xFF444444))),
            ],
          ),
          const SizedBox(height: 10),
          _actionButton(
            theme,
            'TAKE BREAK (SAVE)',
            _takeBreak,
            const Color(0xFFFFBB00),
            fullWidth: true,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _actionButton(
            theme,
            'TERMINATE SESSION',
            _finish,
            theme.colorScheme.primary,
            fullWidth: true,
          ),
          const SizedBox(height: 10),
          _actionButton(
            theme,
            'TAKE BREAK (SAVE)',
            _takeBreak,
            const Color(0xFFFFBB00),
            fullWidth: true,
          ),
        ],
      );
    }
  }

  Widget _actionButton(ThemeData theme, String text, VoidCallback onPressed, Color borderColor, {bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 60,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor, width: 2),
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            color: borderColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _handleCorrect() {
    Vibration.vibrate(duration: 20);
    setState(() {
      _correctCount++;
      _score += 4;
      _advanceQuestion();
    });
  }

  void _handleRetry() {
    Vibration.vibrate(duration: 50, amplitude: 128);
    Vibration.vibrate(duration: 50, amplitude: 128);
    setState(() {
      _score -= 1;
    });
  }

  void _handleSkip() {
    Vibration.vibrate(duration: 20);
    setState(() {
      _advanceQuestion();
    });
  }

  void _advanceQuestion() {
    _questionTime = 0;
    if (_currentQuestion < widget.questionCount) {
      _currentQuestion++;
    } else {
      _finish();
    }
  }

  void _finish() {
    if (widget.task.mode == 'online_test') {
      setState(() => _showReport = true);
    } else {
      _submit();
    }
  }

  void _takeBreak() {
    final profileManager = context.read<ProfileManager>();
    profileManager.pauseTask(PausedTask(
      task: widget.task,
      elapsedSeconds: _elapsedSeconds,
      lastQuestionIndex: _currentQuestion,
      lastCorrectCount: _correctCount,
      lastScore: _score,
    ));
    Navigator.of(context).pop();
  }

  void _abort() {
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    const uuid = Uuid();
    final profileManager = context.read<ProfileManager>();

    final log = StudyLog(
      id: uuid.v4(),
      timestamp: DateTime.now(),
      date: _formatDate(DateTime.now()),
      type: widget.task.mode,
      duration: _elapsedSeconds,
      taskName: widget.task.text,
      questionsTotal: widget.task.mode == 'training' ? widget.questionCount : 0,
      questionsCorrect: _correctCount,
      marksScored: _score,
      marksTotal: 0,
    );

    await profileManager.logSession(log);

    final updated = TaskItem(
      id: widget.task.id,
      text: widget.task.text,
      tag: widget.task.tag,
      mode: widget.task.mode,
      done: true,
      createdAt: widget.task.createdAt,
    );
    await profileManager.updateTask(updated);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Widget _buildReportView() {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TEST COMPLETED',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _marksController,
                keyboardType: TextInputType.number,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'MARKS SCORED',
                  labelStyle: TextStyle(color: theme.colorScheme.secondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.secondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _totalMarksController,
                keyboardType: TextInputType.number,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'TOTAL MARKS',
                  labelStyle: TextStyle(color: theme.colorScheme.secondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.secondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    final scored = int.tryParse(_marksController.text) ?? 0;
                    final total = int.tryParse(_totalMarksController.text) ?? 0;
                    _submitTest(scored, total);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'LOG RESULTS',
                    style: theme.textTheme.displayMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitTest(int scored, int total) async {
    const uuid = Uuid();
    final profileManager = context.read<ProfileManager>();

    final log = StudyLog(
      id: uuid.v4(),
      timestamp: DateTime.now(),
      date: _formatDate(DateTime.now()),
      type: 'test',
      duration: _elapsedSeconds,
      taskName: widget.task.text,
      marksScored: scored,
      marksTotal: total,
    );

    await profileManager.logSession(log);

    final updated = TaskItem(
      id: widget.task.id,
      text: widget.task.text,
      tag: widget.task.tag,
      mode: widget.task.mode,
      done: true,
      createdAt: widget.task.createdAt,
    );
    await profileManager.updateTask(updated);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
