import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/profile.dart';
import 'profile_manager.dart';

class SyncManager extends ChangeNotifier {
  final ProfileManager _profileManager;
  String? _deviceId;
  List<ConnectedDevice> _connectedDevices = [];
  Timer? _heartbeatTimer;
  RealtimeChannel? _channel;

  List<ConnectedDevice> get connectedDevices => _connectedDevices;
  String? get deviceId => _deviceId;

  SyncManager(this._profileManager) {
    _init();
  }

  Future<void> _init() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceId = androidInfo.id;
    } catch (e) {
      _deviceId = 'unknown_device';
    }
  }

  void updateProfile(ProfileManager profileManager) {
    if (_profileManager != profileManager) {
      _disconnect();
    }
  }

  Future<void> connect() async {
    if (_profileManager.currentProfile == null) return;

    final profile = _profileManager.currentProfile!;
    final channelName = 'profile:${profile.id}';

    _channel?.unsubscribe();

    _channel = Supabase.instance.client.channel(channelName);

    _channel!.onPresenceSync((_) {
      final state = _channel!.presenceState();
      _connectedDevices = state.entries
          .expand((e) => e.value)
          .map((p) => ConnectedDevice.fromJson(p as Map<String, dynamic>))
          .toList();
      notifyListeners();
    });

    _channel!.onBroadcast(
      event: 'profile_update',
      callback: (payload) {
        _handleRemoteUpdate(payload);
      },
    );

    await _channel!.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel!.track({
          'device_id': _deviceId,
          'device_name': await _getDeviceName(),
          'online_at': DateTime.now().toIso8601String(),
        });
      }
    });

    _startHeartbeat();
  }

  void _handleRemoteUpdate(Map<String, dynamic> payload) {
    try {
      final updatedProfile = Profile.fromJson(payload['profile']);
      _profileManager.importProfile(updatedProfile.toJsonString());
    } catch (e) {
      debugPrint('Failed to handle remote update: $e');
    }
  }

  Future<void> broadcastUpdate() async {
    if (_channel == null || _profileManager.currentProfile == null) return;

    await _channel!.sendBroadcastMessage(
      event: 'profile_update',
      payload: {
        'profile': _profileManager.currentProfile!.toJson(),
        'device_id': _deviceId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendHeartbeat();
    });
  }

  Future<void> _sendHeartbeat() async {
    if (_channel == null) return;
    await _channel!.track({
      'device_id': _deviceId,
      'device_name': await _getDeviceName(),
      'online_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      final androidInfo = await deviceInfo.androidInfo;
      return '${androidInfo.brand} ${androidInfo.model}';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  void _disconnect() {
    _heartbeatTimer?.cancel();
    _channel?.unsubscribe();
    _channel = null;
    _connectedDevices.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }
}

class ConnectedDevice {
  final String deviceId;
  final String deviceName;
  final DateTime onlineAt;

  ConnectedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.onlineAt,
  });

  factory ConnectedDevice.fromJson(Map<String, dynamic> json) {
    return ConnectedDevice(
      deviceId: json['device_id'],
      deviceName: json['device_name'],
      onlineAt: DateTime.parse(json['online_at']),
    );
  }
}
