import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../models/vpn_status_model.dart';
import '../models/vpn_data_model.dart';
import 'openvpn_service.dart';
import 'vpn_usage_service.dart';

class VpnService {
  // Singleton instance
  static final VpnService _instance = VpnService._internal();

  // Factory constructor
  factory VpnService() {
    return _instance;
  }

  // Private constructor
  VpnService._internal();
  final OpenVpnService _vpnService = OpenVpnService();
  final VpnUsageService _vpnUsageService = VpnUsageService();
  
  Timer? _statusTimer;
  Timer? _vpnCheckTimer;
  String? connectingIndex;
  bool isConnecting = false;
  double accumulatedDuration = 0;
  String? ipAddress;
  bool _isInitialized = false;
  final ValueNotifier<OpenVpnStatus?> _currentStatusNotifier =
      ValueNotifier<OpenVpnStatus?>(null);

  // Initialize the VPN service
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent multiple initializations
    _isInitialized = true;
    await _vpnService.initialize();
    await _loadVpnData();
  }

  // Load previously saved VPN connection data (index and VPN data)
  Future<void> _loadVpnData() async {
    
    final prefs = await SharedPreferences.getInstance();
    String? savedIndex = prefs.getString('connectingIndex');
    if (savedIndex != null) {
      connectingIndex = savedIndex;
      isConnecting = true;
      if (_statusTimer != null && _statusTimer!.isActive) {
        _statusTimer!.cancel();
        _statusTimer = null; // Clear the reference to prevent reuse
      }
       startVpnCheck();
      _monitorVpnStatus();
      _vpnUsageService.updateVpnUsageWithSplitting(connectingIndex!);
      VpnData vpnData = await getVpnDataByIndex(savedIndex);
      await _vpnService.connect(vpnData);
    }
  }

  // Monitor VPN connection status and handle duration tracking
  void _monitorVpnStatus() {
    if (_statusTimer != null && _statusTimer!.isActive) {
      _statusTimer!.cancel();
      _statusTimer = null; // Clear the reference to prevent reuse
    }
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final OpenVpnStatus? currentStatus = _vpnService.getCurrentStatus();
      if (currentStatus != null) {
        _currentStatusNotifier.value = currentStatus;
        // Call setState to force UI rebuild if needed
      }
    });
  }

  // Connect to VPN using the given VPN data
  Future<void> connectVpn(VpnData vpnData, String id) async {
    try{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('connectingIndex', id);
    connectingIndex = id;
    isConnecting = true;
    startVpnCheck();
    _monitorVpnStatus();
    _vpnUsageService.storeTimeStart();
    await _vpnService.connect(vpnData);
    }
     catch (error) {
      
      debugPrint("testtt vpn network");
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('startTime');
     await disconnectVpn();
      // Handle errors gracefully
     
      
    }
  }

 void setStatusCustom(){
isConnecting= false;
 }
  Future<void> disconnectVpn() async {
    if (connectingIndex == null) return;
    await _vpnUsageService.updateVpnUsageWithSplitting(connectingIndex!);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('connectingIndex');
    await prefs.remove('connectingStatus');

    // Ensure the VPN service is disconnected and all resources are released
    if (_statusTimer != null && _statusTimer!.isActive) {
      _statusTimer!.cancel();
      _statusTimer = null; // Clear the reference
    }
    if (_vpnCheckTimer != null && _vpnCheckTimer!.isActive) {
      _vpnCheckTimer!.cancel();
      _vpnCheckTimer = null; // Clear the reference
    }
    connectingIndex = null;
    isConnecting = false;
    _currentStatusNotifier.value = null;
    try {
      await _vpnService.disconnect(); // Disconnect VPN securely
    } catch (e) {
      debugPrint("Error disconnecting VPN: $e");
    }
  }

  // Periodic VPN check to ensure the connection is still active
  void startVpnCheck() {
    _vpnCheckTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (_currentStatusNotifier.value?.stage != 'connected') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('startTime');
        disconnectVpn();
      }
      if (_vpnCheckTimer != null && _vpnCheckTimer!.isActive) {
        _vpnCheckTimer!.cancel();
        _vpnCheckTimer = null; // Clear the reference
      }
    });
  }

  // Get VPN data by index
  Future<VpnData> getVpnDataByIndex(String index) async {
    final prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString('vpnData');
    List<VpnData> vpnList = [];
    if (storedData != null) {
      vpnList = (jsonDecode(storedData) as List)
          .asMap()
          .entries
          .map((entry) => VpnData.fromJson(entry.value, entry.key))
          .toList()
          .cast<VpnData>();
    }
    return vpnList.firstWhere((vpn) => vpn.id == index,
        orElse: () => throw Exception("VPN data not found"));
  }

  OpenVpnStatus? getCurrentStatus() {
    return _currentStatusNotifier.value;
  }

  // Method to get the current VPN status notifier
  ValueNotifier<OpenVpnStatus?> getCurrentStatusNotifier() {
    return _currentStatusNotifier;
  }

  // Method to update the VPN status
  void updateVpnStatus(OpenVpnStatus status) {
    _currentStatusNotifier.value = status;
  }

  // Getter for the current stage of the connection
  bool? getConnectingStatus() {
    return isConnecting;
  }

  // Dispose resources when no longer needed
  void dispose() {
    if (_statusTimer != null && _statusTimer!.isActive) {
      _statusTimer!.cancel();
      _statusTimer = null; // Clear the reference to prevent reuse
    }
    if (_vpnCheckTimer != null && _vpnCheckTimer!.isActive) {
      _vpnCheckTimer!.cancel();
      _vpnCheckTimer = null; // Clear the reference to prevent reuse
    }
    _vpnService.dispose();
  }
}
