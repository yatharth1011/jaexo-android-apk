import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class NetworkManager extends ChangeNotifier {
  String? _currentSSID;
  String? _currentBSSID;
  bool _isConnected = false;

  String? get currentSSID => _currentSSID;
  String? get currentBSSID => _currentBSSID;
  bool get isConnected => _isConnected;

  Timer? _pollTimer;

  NetworkManager() {
    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();
    await _updateNetworkInfo();
    _startPolling();
  }

  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await Permission.nearbyWifiDevices.request();
  }

  Future<void> _updateNetworkInfo() async {
    try {
      final networkInfo = NetworkInfo();

      final ssid = await networkInfo.getWifiName();
      final bssid = await networkInfo.getWifiBSSID();

      _currentSSID = ssid?.replaceAll('"', '');
      _currentBSSID = bssid;
      _isConnected = _currentSSID != null && _currentBSSID != null;

      notifyListeners();
    } catch (e) {
      _isConnected = false;
      notifyListeners();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateNetworkInfo();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String get networkIdentifier => '${_currentSSID}_$_currentBSSID';
}
