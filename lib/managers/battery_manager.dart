import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';

class BatteryManager extends ChangeNotifier {
  final Battery _battery = Battery();

  int _level = 100;
  BatteryState _state = BatteryState.full;
  String? _remainingTime;
  bool _isLowPower = false;

  List<BatteryReading> _readings = [];
  Timer? _pollTimer;

  int get level => _level;
  BatteryState get state => _state;
  String? get remainingTime => _remainingTime;
  bool get isLowPower => _isLowPower;
  bool get isCharging => _state == BatteryState.charging || _state == BatteryState.full;

  BatteryManager() {
    _init();
  }

  Future<void> _init() async {
    await _updateBatteryInfo();
    _startPolling();

    _battery.onBatteryStateChanged.listen((state) {
      _state = state;
      notifyListeners();
    });
  }

  Future<void> _updateBatteryInfo() async {
    try {
      _level = await _battery.batteryLevel;
      _state = await _battery.batteryState;

      _readings.add(BatteryReading(
        level: _level,
        timestamp: DateTime.now(),
      ));

      if (_readings.length > 120) {
        _readings = _readings.sublist(_readings.length - 120);
      }

      if (_state == BatteryState.discharging) {
        _calculateRemainingTime();
      } else {
        _remainingTime = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update battery info: $e');
    }
  }

  void _calculateRemainingTime() {
    if (_readings.length < 2) {
      _remainingTime = 'SYNC...';
      return;
    }

    final recentReadings = _readings.where((r) {
      final diff = DateTime.now().difference(r.timestamp);
      return diff.inMinutes <= 10;
    }).toList();

    if (recentReadings.length < 2) {
      _remainingTime = 'SYNC...';
      return;
    }

    final first = recentReadings.first;
    final last = recentReadings.last;
    final timeDiff = last.timestamp.difference(first.timestamp).inSeconds;
    final levelDiff = first.level - last.level;

    if (levelDiff <= 0 || timeDiff <= 0) {
      _remainingTime = 'SYNC...';
      return;
    }

    final drainRatePerSecond = levelDiff / timeDiff;
    final targetLevel = 20;
    final remainingLevel = _level - targetLevel;

    if (remainingLevel <= 0) {
      _remainingTime = 'TARGET_REACHED';
      _isLowPower = true;
      return;
    }

    final secondsRemaining = (remainingLevel / drainRatePerSecond).round();
    _isLowPower = secondsRemaining < 1800;

    final hours = secondsRemaining ~/ 3600;
    final minutes = (secondsRemaining % 3600) ~/ 60;
    final seconds = secondsRemaining % 60;

    if (hours > 0) {
      _remainingTime = '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      _remainingTime = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateBatteryInfo();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

class BatteryReading {
  final int level;
  final DateTime timestamp;

  BatteryReading({required this.level, required this.timestamp});
}
