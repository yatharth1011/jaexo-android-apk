import 'dart:convert';

class Profile {
  final String id;
  final String name;
  final String networkSSID;
  final String networkBSSID;
  final List<int> patternHash;
  final DateTime createdAt;
  final String? musicAnchorDeviceId;

  List<TaskItem> tasks;
  List<StudyLog> logs;
  Map<String, dynamic> stats;
  int totalCoins;
  List<HistoryEntry> studyHistory;
  List<String> musicQueue;

  Profile({
    required this.id,
    required this.name,
    required this.networkSSID,
    required this.networkBSSID,
    required this.patternHash,
    required this.createdAt,
    this.musicAnchorDeviceId,
    this.tasks = const [],
    this.logs = const [],
    this.stats = const {},
    this.totalCoins = 0,
    this.studyHistory = const [],
    this.musicQueue = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'network_ssid': networkSSID,
      'network_bssid': networkBSSID,
      'pattern_hash': patternHash,
      'created_at': createdAt.toIso8601String(),
      'music_anchor_device_id': musicAnchorDeviceId,
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'logs': logs.map((l) => l.toJson()).toList(),
      'stats': stats,
      'total_coins': totalCoins,
      'study_history': studyHistory.map((h) => h.toJson()).toList(),
      'music_queue': musicQueue,
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      name: json['name'],
      networkSSID: json['network_ssid'],
      networkBSSID: json['network_bssid'],
      patternHash: List<int>.from(json['pattern_hash']),
      createdAt: DateTime.parse(json['created_at']),
      musicAnchorDeviceId: json['music_anchor_device_id'],
      tasks: (json['tasks'] as List?)?.map((t) => TaskItem.fromJson(t)).toList() ?? [],
      logs: (json['logs'] as List?)?.map((l) => StudyLog.fromJson(l)).toList() ?? [],
      stats: json['stats'] ?? {},
      totalCoins: json['total_coins'] ?? 0,
      studyHistory: (json['study_history'] as List?)?.map((h) => HistoryEntry.fromJson(h)).toList() ?? [],
      musicQueue: List<String>.from(json['music_queue'] ?? []),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Profile.fromJsonString(String str) => Profile.fromJson(jsonDecode(str));
}

class TaskItem {
  final String id;
  String text;
  String tag;
  String mode;
  bool done;
  final DateTime createdAt;

  TaskItem({
    required this.id,
    required this.text,
    required this.tag,
    required this.mode,
    this.done = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'tag': tag,
      'mode': mode,
      'done': done,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'],
      text: json['text'],
      tag: json['tag'],
      mode: json['mode'],
      done: json['done'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class StudyLog {
  final String id;
  final DateTime timestamp;
  final String date;
  final String type;
  final int duration;
  final String taskName;
  final int questionsTotal;
  final int questionsCorrect;
  final int marksScored;
  final int marksTotal;

  StudyLog({
    required this.id,
    required this.timestamp,
    required this.date,
    required this.type,
    required this.duration,
    required this.taskName,
    this.questionsTotal = 0,
    this.questionsCorrect = 0,
    this.marksScored = 0,
    this.marksTotal = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'date': date,
      'type': type,
      'duration': duration,
      'task_name': taskName,
      'questions_total': questionsTotal,
      'questions_correct': questionsCorrect,
      'marks_scored': marksScored,
      'marks_total': marksTotal,
    };
  }

  factory StudyLog.fromJson(Map<String, dynamic> json) {
    return StudyLog(
      id: json['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      date: json['date'],
      type: json['type'],
      duration: json['duration'],
      taskName: json['task_name'],
      questionsTotal: json['questions_total'] ?? 0,
      questionsCorrect: json['questions_correct'] ?? 0,
      marksScored: json['marks_scored'] ?? 0,
      marksTotal: json['marks_total'] ?? 0,
    );
  }
}

class HistoryEntry {
  final String date;
  final double hours;

  HistoryEntry({required this.date, required this.hours});

  Map<String, dynamic> toJson() {
    return {'date': date, 'hours': hours};
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      date: json['date'],
      hours: (json['hours'] as num).toDouble(),
    );
  }
}

class PausedTask {
  final TaskItem task;
  final int elapsedSeconds;
  final int lastQuestionIndex;
  final int lastCorrectCount;
  final int lastScore;

  PausedTask({
    required this.task,
    required this.elapsedSeconds,
    this.lastQuestionIndex = 1,
    this.lastCorrectCount = 0,
    this.lastScore = 0,
  });
}
