import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;
import '../models/profile.dart';
import 'profile_manager.dart';

class SyncManager extends ChangeNotifier {
  final ProfileManager _profileManager;
  String? _deviceId;
  String? _deviceName;
  List<ConnectedDevice> _connectedDevices = [];
  
  HttpServer? _server;
  MDNSClient? _mdnsClient;
  Timer? _discoveryTimer;
  
  static const int _port = 48484;
  static const String _serviceType = '_jaexo._tcp.local';

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
      _deviceName = '${androidInfo.brand} ${androidInfo.model}';
    } catch (e) {
      _deviceId = 'unknown_device';
      _deviceName = 'Unknown Device';
    }
  }

  void updateProfile(ProfileManager profileManager) {
    // Handle profile changes if needed
  }

  Future<void> connect() async {
    if (_profileManager.currentProfile == null) return;
    
    await _stopServer();
    await _startServer();
    _startDiscovery();
  }

  Future<void> _startServer() async {
    final router = Router();

    router.get('/status', (Request request) {
      return Response.ok(jsonEncode({
        'device_id': _deviceId,
        'device_name': _deviceName,
        'online_at': DateTime.now().toIso8601String(),
      }), headers: {'content-type': 'application/json'});
    });

    router.post('/update', (Request request) async {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      _handleRemoteUpdate(data);
      return Response.ok('updated');
    });

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router);

    try {
      _server = await io.serve(handler, InternetAddress.anyIPv4, _port);
      debugPrint('Sync server running on port ${_server!.port}');
    } catch (e) {
      debugPrint('Failed to start sync server: $e');
    }
  }

  Future<void> _stopServer() async {
    await _server?.close(force: true);
    _server = null;
  }

  void _startDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _discoverDevices();
    });
    _discoverDevices();
  }

  Future<void> _discoverDevices() async {
    final client = MDNSClient();
    await client.start();
    
    final List<ConnectedDevice> foundDevices = [];
    
    try {
      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer(_serviceType))) {
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName))) {
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {
            
            final address = ip.address.address;
            if (address == '127.0.0.1') continue;

            try {
              final response = await http.get(Uri.parse('http://$address:$_port/status'))
                  .timeout(const Duration(seconds: 2));
              
              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                if (data['device_id'] != _deviceId) {
                  foundDevices.add(ConnectedDevice(
                    deviceId: data['device_id'],
                    deviceName: data['device_name'],
                    onlineAt: DateTime.parse(data['online_at']),
                    address: address,
                  ));
                }
              }
            } catch (e) {
              // Device might be offline or unreachable
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Discovery error: $e');
    } finally {
      client.stop();
    }

    _connectedDevices = foundDevices;
    notifyListeners();
  }

  void _handleRemoteUpdate(Map<String, dynamic> payload) {
    try {
      final updatedProfile = Profile.fromJson(payload['profile']);
      // Only update if the incoming profile is newer or different
      // For simplicity in this local sync, we just import it
      _profileManager.importProfile(updatedProfile.toJsonString());
    } catch (e) {
      debugPrint('Failed to handle remote update: $e');
    }
  }

  Future<void> broadcastUpdate() async {
    if (_profileManager.currentProfile == null) return;

    final payload = jsonEncode({
      'profile': _profileManager.currentProfile!.toJson(),
      'device_id': _deviceId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    for (final device in _connectedDevices) {
      try {
        await http.post(
          Uri.parse('http://${device.address}:$_port/update'),
          body: payload,
          headers: {'content-type': 'application/json'},
        ).timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Failed to send update to ${device.deviceName}: $e');
      }
    }
  }

  void _disconnect() {
    _discoveryTimer?.cancel();
    _stopServer();
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
  final String address;

  ConnectedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.onlineAt,
    required this.address,
  });

  factory ConnectedDevice.fromJson(Map<String, dynamic> json) {
    return ConnectedDevice(
      deviceId: json['device_id'],
      deviceName: json['device_name'],
      onlineAt: DateTime.parse(json['online_at']),
      address: json['address'] ?? '',
    );
  }
}
