import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import '../managers/profile_manager.dart';
import '../managers/battery_manager.dart';
import '../managers/music_manager.dart';
import '../managers/sync_manager.dart';
import '../data/schedule_2026.dart';
import '../models/profile.dart';
import '../widgets/command_deck.dart';
import '../widgets/task_item_widget.dart';
import '../widgets/battery_bar.dart';
import '../widgets/paused_task_banner.dart';
import '../widgets/event_banner.dart';
import 'hud_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _currentDate = DateTime.now();
  bool _deckOpen = false;
  Timer? _shakeTimer;
  final FocusNode _screenFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _shakeTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _triggerShake();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncManager = context.read<SyncManager>();
      syncManager.connect();
    });
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    _screenFocusNode.dispose();
    super.dispose();
  }

  void _triggerShake() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileManager = context.watch<ProfileManager>();
    final batteryManager = context.watch<BatteryManager>();

    final tasks = profileManager.getTasksForDate(_currentDate);
    final stats = profileManager.calculateStats(_currentDate);
    final scheduleItem = Schedule2026.getItemForDate(_currentDate);

    final targetHours = scheduleItem?.target ?? 5;
    final todayTime = (stats['today_time'] as int) / 3600;
    final targetMet = targetHours > 0 && todayTime >= targetHours;
    final displayCoins = (stats['total_coins'] as int) + (targetMet ? 500 : 0);

    return KeyboardListener(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent && !_isTextFieldFocused()) {
          if (event.logicalKey == LogicalKeyboardKey.space) {
            setState(() => _deckOpen = !_deckOpen);
            Vibration.vibrate(duration: 20);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _changeDate(-1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _changeDate(1);
          } else if (event.character?.toLowerCase() == 'a') {
            _addTask();
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            BatteryBar(level: batteryManager.level, isCharging: batteryManager.isCharging),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(theme, targetMet, stats, displayCoins, targetHours),
                    CommandDeck(
                      isOpen: _deckOpen,
                      onToggle: () => setState(() => _deckOpen = !_deckOpen),
                      onThemeChange: (t) => profileManager.setTheme(t),
                      onResetDay: () => _resetDay(profileManager),
                    ),
                    if (scheduleItem != null)
                      EventBanner(event: scheduleItem.event),
                    ..._buildPausedBanners(profileManager),
                    const SizedBox(height: 10),
                    _buildTaskList(tasks, profileManager),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'add',
              backgroundColor: theme.colorScheme.primary,
              onPressed: _addTask,
              child: const Icon(Icons.add, color: Colors.black),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'summary',
              backgroundColor: theme.colorScheme.secondary,
              onPressed: () => _openSummary(stats),
              child: const Icon(Icons.bar_chart, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    bool targetMet,
    Map<String, dynamic> stats,
    int displayCoins,
    int targetHours,
  ) {
    final batteryManager = context.watch<BatteryManager>();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'JAEXO ULTIMATE ${targetMet ? "🏆" : ""}',
                          style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
                        ),
                      ),
                      Image.network(
                        'https://cdn-icons-png.freepik.com/256/5825/5825151.png?semt=ais_white_label',
                        height: 28,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'TIME: ${((stats['today_time'] as int) / 3600).toStringAsFixed(2)}h / ${targetHours}h  '
                    'ACC: ${(stats['accuracy'] as double).toStringAsFixed(0)}%  '
                    '🥇: $displayCoins',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () => setState(() => _deckOpen = !_deckOpen),
                    child: Text(
                      '[COMMAND DECK]',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildPowerIndicator(batteryManager, theme),
                const SizedBox(height: 5),
                Text(
                  _formatDate(_currentDate),
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentDate = DateTime.now()),
                  child: Text(
                    '[RETURN TO TODAY]',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _changeDate(-1),
              color: theme.colorScheme.primary,
            ),
            Expanded(
              child: Text(
                _formatDate(_currentDate),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => _changeDate(1),
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPowerIndicator(BatteryManager battery, ThemeData theme) {
    if (battery.isCharging) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: Colors.green, size: 16),
          Text(
            '${battery.level}%',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    if (battery.remainingTime == 'TARGET_REACHED') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.battery_alert, color: theme.colorScheme.error, size: 16),
          Text(
            'LOW POWER',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return Text(
      'REM: ${battery.remainingTime ?? "SYNC..."}',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: battery.isLowPower ? theme.colorScheme.error : theme.colorScheme.secondary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  List<Widget> _buildPausedBanners(ProfileManager profileManager) {
    return profileManager.pausedTasks.values.map((paused) {
      return PausedTaskBanner(
        task: paused.task,
        elapsedSeconds: paused.elapsedSeconds,
        onResume: () => _resumeTask(paused),
      );
    }).toList();
  }

  Widget _buildTaskList(List<TaskItem> tasks, ProfileManager profileManager) {
    if (tasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('NO TASKS FOR THIS DATE'),
        ),
      );
    }

    return Column(
      children: tasks.map((task) {
        return TaskItemWidget(
          task: task,
          onToggle: () => _toggleTask(task, profileManager),
          onUpdate: (updated) => profileManager.updateTask(updated),
          onDelete: () => profileManager.deleteTask(task.id),
          onReorder: (direction) => profileManager.reorderTasks(task.id, direction),
          onEngage: () => _engageTask(task),
        );
      }).toList(),
    );
  }

  void _changeDate(int days) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: days));
    });
    Vibration.vibrate(duration: 20);
  }

  void _addTask() {
    final profileManager = context.read<ProfileManager>();
    final task = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: 'New Directive',
      tag: 'MISC',
      mode: 'focus',
      createdAt: _currentDate,
    );
    profileManager.addTask(task);
    Vibration.vibrate(duration: 30);
  }

  void _toggleTask(TaskItem task, ProfileManager profileManager) {
    final updated = TaskItem(
      id: task.id,
      text: task.text,
      tag: task.tag,
      mode: task.mode,
      done: !task.done,
      createdAt: task.createdAt,
    );
    profileManager.updateTask(updated);
    Vibration.vibrate(duration: 20);
  }

  void _engageTask(TaskItem task) {
    Vibration.vibrate(duration: 50);
    if (task.mode == 'training' || task.mode == 'online_test') {
      _showConfigDialog(task);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HUDScreen(task: task, initialElapsed: 0),
        ),
      );
    }
  }

  void _showConfigDialog(TaskItem task) {
    int questionCount = 15;

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text('MISSION CONFIG', style: theme.textTheme.displayMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(task.text, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of Questions',
                  labelStyle: TextStyle(color: theme.colorScheme.secondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.secondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                style: theme.textTheme.bodyLarge,
                onChanged: (val) => questionCount = int.tryParse(val) ?? 15,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HUDScreen(
                      task: task,
                      initialElapsed: 0,
                      questionCount: questionCount,
                    ),
                  ),
                );
              },
              child: Text('START', style: TextStyle(color: theme.colorScheme.primary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('CANCEL', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  void _resumeTask(PausedTask paused) {
    final profileManager = context.read<ProfileManager>();
    profileManager.resumeTask(paused.task.id);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HUDScreen(
          task: paused.task,
          initialElapsed: paused.elapsedSeconds,
          initialQuestion: paused.lastQuestionIndex,
          initialCorrect: paused.lastCorrectCount,
          initialScore: paused.lastScore,
        ),
      ),
    );
  }

  void _resetDay(ProfileManager profileManager) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text('WIPE TODAY LOGS?', style: theme.textTheme.displayMedium),
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
      await profileManager.resetDay(_currentDate);
      setState(() {});
    }
  }

  void _openSummary(Map<String, dynamic> stats) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SummaryScreen(stats: stats)),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _isTextFieldFocused() {
    return FocusManager.instance.primaryFocus?.context?.widget is EditableText;
  }
}
