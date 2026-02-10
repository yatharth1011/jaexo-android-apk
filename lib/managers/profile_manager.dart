import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../utils/task_generator.dart';
import 'sync_manager.dart';

class ProfileManager extends ChangeNotifier {
  SyncManager? _syncManager;

  void setSyncManager(SyncManager syncManager) {
    _syncManager = syncManager;
  }
  Profile? _currentProfile;
  String _currentTheme = 'ghost';
  final Map<String, PausedTask> _pausedTasks = {};

  Profile? get currentProfile => _currentProfile;
  String get currentTheme => _currentTheme;
  Map<String, PausedTask> get pausedTasks => _pausedTasks;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTheme = prefs.getString('theme') ?? 'ghost';

    final profileJson = prefs.getString('current_profile');
    if (profileJson != null) {
      _currentProfile = Profile.fromJsonString(profileJson);
      notifyListeners();
    }
  }

  Future<void> createProfile({
    required String name,
    required String networkSSID,
    required String networkBSSID,
    required List<int> pattern,
  }) async {
    const uuid = Uuid();
    final patternHash = _hashPattern(pattern);

    _currentProfile = Profile(
      id: uuid.v4(),
      name: name,
      networkSSID: networkSSID,
      networkBSSID: networkBSSID,
      patternHash: patternHash,
      createdAt: DateTime.now(),
      tasks: [],
      logs: [],
      stats: {},
      totalCoins: 0,
      studyHistory: [],
      musicQueue: [],
    );

    await _saveProfile();
    _syncManager?.broadcastUpdate();
    notifyListeners();
  }

  bool validatePattern(List<int> pattern) {
    if (_currentProfile == null) return false;
    final hash = _hashPattern(pattern);
    return listEquals(hash, _currentProfile!.patternHash);
  }

  List<int> _hashPattern(List<int> pattern) {
    final bytes = utf8.encode(pattern.join(','));
    final digest = sha256.convert(bytes);
    return digest.bytes;
  }

  Future<void> setTheme(String theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
    notifyListeners();
  }

  List<TaskItem> getTasksForDate(DateTime date) {
    if (_currentProfile == null) return [];

    final dateKey = _formatDateKey(date);
    final existingTasks = _currentProfile!.tasks.where((t) {
      final taskDate = _formatDateKey(t.createdAt);
      return taskDate == dateKey;
    }).toList();

    if (existingTasks.isEmpty) {
      final generated = TaskGenerator.generateDailyTasks(date);
      _currentProfile!.tasks.addAll(generated);
      _saveProfile();
      return generated;
    }

    return existingTasks;
  }

  Future<void> addTask(TaskItem task) async {
    if (_currentProfile == null) return;
    _currentProfile!.tasks.add(task);
    await _saveProfile();
    _syncManager?.broadcastUpdate();
    notifyListeners();
  }

  Future<void> updateTask(TaskItem updated) async {
    if (_currentProfile == null) return;
    final index = _currentProfile!.tasks.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _currentProfile!.tasks[index] = updated;
      await _saveProfile();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (_currentProfile == null) return;
    _currentProfile!.tasks.removeWhere((t) => t.id == taskId);
    await _saveProfile();
    _syncManager?.broadcastUpdate();
    notifyListeners();
  }

  Future<void> reorderTasks(String taskId, int direction) async {
    if (_currentProfile == null) return;
    final index = _currentProfile!.tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _currentProfile!.tasks.length) return;

    final task = _currentProfile!.tasks.removeAt(index);
    _currentProfile!.tasks.insert(newIndex, task);
    await _saveProfile();
    _syncManager?.broadcastUpdate();
    notifyListeners();
  }

  Future<void> logSession(StudyLog log) async {
    if (_currentProfile == null) return;
    _currentProfile!.logs.add(log);
    await _saveProfile();
    _syncManager?.broadcastUpdate();
    notifyListeners();
  }

  Map<String, dynamic> calculateStats(DateTime date) {
    if (_currentProfile == null) {
      return {
        'today_time': 0,
        'questions_today': 0,
        'accuracy': 0.0,
        'subject_breakdown': {},
        'total_coins': 0,
      };
    }

    final dateKey = _formatDateKey(date);
    final dayLogs = _currentProfile!.logs.where((l) => l.date == dateKey).toList();

    final dayTime = dayLogs.fold<int>(0, (sum, l) => sum + l.duration);

    final trainingLogs = dayLogs.where((l) => l.type == 'training').toList();
    final totalQ = trainingLogs.fold<int>(0, (sum, l) => sum + l.questionsTotal);
    final totalC = trainingLogs.fold<int>(0, (sum, l) => sum + l.questionsCorrect);

    int totalCoins = 0;

    for (final log in dayLogs) {
      if (log.type == 'focus') {
        totalCoins += (log.duration / 60).floor();
      } else if (log.type == 'training' || log.type == 'online_test' || log.type == 'test') {
        totalCoins += log.marksScored;
      }
    }

    final dayTasks = getTasksForDate(date);
    final offlineDone = dayTasks.where((t) => t.mode == 'offline' && t.done).length;
    totalCoins += offlineDone * 50;

    final subjects = <String, int>{};
    for (final log in dayLogs) {
      final name = log.taskName.toUpperCase();
      String tag = 'OTHER';
      if (name.contains('MATH') || name.contains('ALGEBRA') || name.contains('CALC')) {
        tag = 'MATH';
      } else if (name.contains('PHY')) {
        tag = 'PHYSICS';
      } else if (name.contains('CHEM')) {
        tag = 'CHEM';
      }
      subjects[tag] = (subjects[tag] ?? 0) + log.duration;
    }

    return {
      'today_time': dayTime,
      'questions_today': totalQ,
      'accuracy': totalQ > 0 ? (totalC / totalQ * 100) : 0.0,
      'subject_breakdown': subjects,
      'total_coins': totalCoins,
    };
  }

  Future<void> resetDay(DateTime date) async {
    if (_currentProfile == null) return;
    final dateKey = _formatDateKey(date);

    _currentProfile!.logs.removeWhere((l) => l.date == dateKey);
    _currentProfile!.tasks.removeWhere((t) => _formatDateKey(t.createdAt) == dateKey);

    await _saveProfile();
    _syncManager?.broadcastUpdate();
    notifyListeners();
  }

  void pauseTask(PausedTask pausedTask) {
    _pausedTasks[pausedTask.task.id] = pausedTask;
    notifyListeners();
  }

  void resumeTask(String taskId) {
    _pausedTasks.remove(taskId);
    notifyListeners();
  }

  Future<String> exportProfile() async {
    if (_currentProfile == null) return '';
    return _currentProfile!.toJsonString();
  }

  Future<void> importProfile(String jsonString) async {
    try {
      _currentProfile = Profile.fromJsonString(jsonString);
      await _saveProfile();
      notifyListeners();
    } catch (e) {
      throw Exception('Invalid profile data');
    }
  }

  Future<void> _saveProfile() async {
    if (_currentProfile == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_profile', _currentProfile!.toJsonString());
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
