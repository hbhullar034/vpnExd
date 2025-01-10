import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart' as vpn_flutter; // Import with prefix
import '../models/VpnStatusModel.dart';
import '../models/vpn_data_model.dart';
import 'vpn_usage_service.dart';

class OpenVpnService {
  static final OpenVpnService _instance = OpenVpnService._internal();

  factory OpenVpnService() {
    return _instance;
  }

  OpenVpnService._internal();

  final VpnUsageService vpnUsageService = VpnUsageService();
  final vpn_flutter.OpenVPN engine = vpn_flutter.OpenVPN();
  OpenVpnStatus? status;
  String? stage;
  Timer? _statusTimer;
  Timer? _durationTimer;
  int accumulatedDuration = 0; // in seconds
  Function(OpenVpnStatus)? onStatusChanged;

  Future<void> initialize() async {
    try {
      await engine.initialize(
        groupIdentifier: "group.com.laskarmedia.vpn",
        providerBundleIdentifier: "id.laskarmedia.openvpnFlutterExample.VPNExtension",
        localizedDescription: "VPN by YourCompany",
      );
      _saveLog("VPN initialized successfully.");
    } catch (e) {
      _saveLog("Error during VPN initialization: $e");
    }
  }
   Future<bool> testVpnServerConnectivity(String server, int port) async {
    try {
      final socket = await Socket.connect(server, port, timeout: Duration(seconds: 5));
      socket.destroy(); // Close the connection
      _saveLog("Successfully connected to server: $server:$port");
      return true;
    } catch (e) {
      _saveLog("Failed to connect to server: $server:$port. Error: $e");
      return false;
    }
  }
 Future<bool> validateRemoteServer(String vpnConfig) async {
    final remotePattern = RegExp(r"remote\s+([\w\.\-]+)\s+(\d+)");
    final match = remotePattern.firstMatch(vpnConfig);
    if (match != null) {
      final server = match.group(1)!;
      final port = int.parse(match.group(2)!);
      return await testVpnServerConnectivity(server, port);
    }
    return false;
  }
  Future<void> connect(VpnData vpnData) async {
    try {
      String vpnConfig = vpnData.vpnConfigPath;
      if (!await validateRemoteServer(vpnConfig)) {
        throw Exception("Unable to reach the VPN server.");
      }

        if (_statusTimer != null && _statusTimer!.isActive) {
          _statusTimer!.cancel();
          _statusTimer = null; // Clear the reference to prevent reuse
        }
      _monitorVpnStatus();
      _saveLog("Connected to VPN successfully.");
      await engine.connect(
        vpnConfig,
        "US",
        username: vpnData.username,
        password: vpnData.password,
        certIsRequired: true,
      );
      
    } catch (e) {
      _saveLog("Error during VPN connection: $e");
      //throw Exception("Unable to reach the VPN server. $e");
    }
  }

  Future<void> disconnect() async {
    try {
      if (_statusTimer != null && _statusTimer!.isActive) {
        _statusTimer!.cancel();
        _statusTimer = null; // Clear the reference to prevent reuse
      }
      if (status != null) {
        status!.stage = 'disconnected';
      }
      stage = 'disconnected';
      status = null;
      engine.disconnect();
      _saveLog("VPN disconnected successfully.");
    } catch (e) {
      _saveLog("Error during VPN disconnection: $e");
    }
  }

  void _monitorVpnStatus() async {
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        
        final vpn_flutter.VpnStatus currentStatus = await engine.status();
        status = OpenVpnStatus.fromJson(currentStatus.toJson());

        if (status?.connectedOn == null) {
          status!.stage = 'disconnected';
        } else {
          status!.stage = 'connected';
        }

        if (onStatusChanged != null && status != null) {
          onStatusChanged!(status!);
        }

        stage = status?.stage;
        onStatusChanged?.call(status!);
        _saveLog("VPN Status: ${status!.stage}");
      } catch (e) {
        _saveLog("Error monitoring VPN status: $e");
      }
    });
  }
  void dispose() {
    _statusTimer?.cancel();
    _durationTimer?.cancel();
    _saveLog("VPN service disposed.");
  }

  OpenVpnStatus? getCurrentStatus() {
    return status;
  }

  String? getConnectionStage() {
    return stage;
  }

  // Method to get accumulated VPN usage duration
  int getVpnUsageDuration() {
    return accumulatedDuration;
  }

  // Check if VPN is connected
  bool isVpnConnected() {
    return status?.stage == 'connected';
  }

  // Check if VPN is disconnected
  bool isVpnDisconnected() {
    return status?.stage == 'disconnected';
  }

  Future<void> _saveLog(String log) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList('vpn_logs') ?? [];
      logs.add("${DateTime.now().toIso8601String()}: $log");
      await prefs.setStringList('vpn_logs', logs);
    } catch (e) {
      // ignore: avoid_print
      print("Error saving log to SharedPreferences: $e");
    }
  }

  Future<List<String>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('vpn_logs') ?? [];
  }
}

