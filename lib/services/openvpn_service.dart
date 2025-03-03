import 'dart:async';
import 'dart:io';

import 'package:openvpn_flutter/openvpn_flutter.dart'
    as vpn_flutter; // Import with prefix
import 'package:path_provider/path_provider.dart';

import '../models/vpn_data_model.dart';
import '../models/vpn_status_model.dart';
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
        groupIdentifier: "group.com.vdesk",
        providerBundleIdentifier: "com.vdesk.VdeskExtension",
        localizedDescription: "VPN by vdesk",
      );
      saveLog("VPN initialized successfully.");
    } catch (e) {
      saveLog("Error during VPN initialization: $e");
    }
  }

  Future<bool> testVpnServerConnectivity(String server, int port) async {
    try {
      final socket = await Socket.connect(server, port,
          timeout: const Duration(seconds: 5));
      socket.destroy(); // Close the connection
      saveLog("Successfully connected to server: $server:$port");
      return true;
    } catch (e) {
      saveLog("Failed to connect to server: $server:$port. Error: $e");
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
      if (!await validateRemoteServer("""client
dev tun
proto udp
remote 174.127.114.116 1194
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
auth-user-pass

# Encryption settings
cipher AES-128-CBC
auth SHA1

<ca>
-----BEGIN CERTIFICATE-----
MIIDuDCCAqCgAwIBAgIBADANBgkqhkiG9w0BAQsFADBbMRgwFgYDVQQDDA9XSU4t
Q0swSk04RUo2RFAxGDAWBgNVBAoMD1dJTi1DSzBKTThFSjZEUDEYMBYGA1UECwwP
V0lOLUNLMEpNOEVKNkRQMQswCQYDVQQGEwJVUzAeFw0yNDEyMTAwNzQ5NThaFw0z
NzEyMzEwNzQ5NThaMFsxGDAWBgNVBAMMD1dJTi1DSzBKTThFSjZEUDEYMBYGA1UE
CgwPV0lOLUNLMEpNOEVKNkRQMRgwFgYDVQQLDA9XSU4tQ0swSk04RUo2RFAxCzAJ
BgNVBAYTAlVTMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsrs2CqJc
s5MLrOj6ssFel8ZGGWJQEfbpYF5JI5wqqONfSq/287dQG3RM8mJacsnGxt4sA1Tq
M9Wq77U956mEkDQuDdBvGnAauzonA9jjElf0k7S7hq4dY2uH12JlnnTifKNydIk0
9xx3PPaDhFq5w+h7w5Ewmv1J4Dc+ET7/KDejn0z2NjjmJ7hZU4xp2+a7nNw+yqUh
5XjUzMi8kUVFUye40F5aelkD85CL7ywuDOtLZS3dRfECHJlYWx5oUtFFgJ33DexN
gcNF4dWZ+hEWIfSQ/Pmhflie/GW5gGX4Jd2mDqbPUq4qUakFpIm0F1x9+VOnNEL/
Ch19D41NOZ1xjwIDAQABo4GGMIGDMA8GA1UdEwEB/wQFMAMBAf8wCwYDVR0PBAQD
AgH2MGMGA1UdJQRcMFoGCCsGAQUFBwMBBggrBgEFBQcDAgYIKwYBBQUHAwMGCCsG
AQUFBwMEBggrBgEFBQcDBQYIKwYBBQUHAwYGCCsGAQUFBwMHBggrBgEFBQcDCAYI
KwYBBQUHAwkwDQYJKoZIhvcNAQELBQADggEBAJ9VaqT4+THeQfRKj7hLeT0K47Pz
ICkMalX8BWi7KoJSVLjl25jWmRtYXs0Cplf41jmsZFgI+I14d8TI8YbsGc6v6UlR
lk9Ir/SroB/7fpSviMRQNDoR6uvMo578se+IiJithYDRwuA8ppcG0RRWAwEXCyaL
n1rKKSRBGonUEkR1hUIdjov94BN4lfq2bmRDFOyqBkaECyL8/U8zNTpGTHUrJCpt
aOj/+JYHaF45a/wRxBIaFRoD2BSGv+4TNBD45jS9UxddteW6dFlyNmrCs+nt/yW4
rN4QPHdn3cKWtvyEUXnJ96kn/aZSF0aw70F7ft7uedNCcDun/Ay1ewgNZkQ=
-----END CERTIFICATE-----
</ca>

<cert>
-----BEGIN CERTIFICATE-----
MIIDuDCCAqCgAwIBAgIBADANBgkqhkiG9w0BAQsFADBbMRgwFgYDVQQDDA9XSU4t
Q0swSk04RUo2RFAxGDAWBgNVBAoMD1dJTi1DSzBKTThFSjZEUDEYMBYGA1UECwwP
V0lOLUNLMEpNOEVKNkRQMQswCQYDVQQGEwJVUzAeFw0yNDEyMTAwNzQ5NThaFw0z
NzEyMzEwNzQ5NThaMFsxGDAWBgNVBAMMD1dJTi1DSzBKTThFSjZEUDEYMBYGA1UE
CgwPV0lOLUNLMEpNOEVKNkRQMRgwFgYDVQQLDA9XSU4tQ0swSk04RUo2RFAxCzAJ
BgNVBAYTAlVTMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsrs2CqJc
s5MLrOj6ssFel8ZGGWJQEfbpYF5JI5wqqONfSq/287dQG3RM8mJacsnGxt4sA1Tq
M9Wq77U956mEkDQuDdBvGnAauzonA9jjElf0k7S7hq4dY2uH12JlnnTifKNydIk0
9xx3PPaDhFq5w+h7w5Ewmv1J4Dc+ET7/KDejn0z2NjjmJ7hZU4xp2+a7nNw+yqUh
5XjUzMi8kUVFUye40F5aelkD85CL7ywuDOtLZS3dRfECHJlYWx5oUtFFgJ33DexN
gcNF4dWZ+hEWIfSQ/Pmhflie/GW5gGX4Jd2mDqbPUq4qUakFpIm0F1x9+VOnNEL/
Ch19D41NOZ1xjwIDAQABo4GGMIGDMA8GA1UdEwEB/wQFMAMBAf8wCwYDVR0PBAQD
AgH2MGMGA1UdJQRcMFoGCCsGAQUFBwMBBggrBgEFBQcDAgYIKwYBBQUHAwMGCCsG
AQUFBwMEBggrBgEFBQcDBQYIKwYBBQUHAwYGCCsGAQUFBwMHBggrBgEFBQcDCAYI
KwYBBQUHAwkwDQYJKoZIhvcNAQELBQADggEBAJ9VaqT4+THeQfRKj7hLeT0K47Pz
ICkMalX8BWi7KoJSVLjl25jWmRtYXs0Cplf41jmsZFgI+I14d8TI8YbsGc6v6UlR
lk9Ir/SroB/7fpSviMRQNDoR6uvMo578se+IiJithYDRwuA8ppcG0RRWAwEXCyaL
n1rKKSRBGonUEkR1hUIdjov94BN4lfq2bmRDFOyqBkaECyL8/U8zNTpGTHUrJCpt
aOj/+JYHaF45a/wRxBIaFRoD2BSGv+4TNBD45jS9UxddteW6dFlyNmrCs+nt/yW4
rN4QPHdn3cKWtvyEUXnJ96kn/aZSF0aw70F7ft7uedNCcDun/Ay1ewgNZkQ=
-----END CERTIFICATE-----
</cert>

<key>
-----BEGIN RSA PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCyuzYKolyzkwus
6PqywV6XxkYZYlAR9ulgXkkjnCqo419Kr/bzt1AbdEzyYlpyycbG3iwDVOoz1arv
tT3nqYSQNC4N0G8acBq7OicD2OMSV/STtLuGrh1ja4fXYmWedOJ8o3J0iTT3HHc8
9oOEWrnD6HvDkTCa/UngNz4RPv8oN6OfTPY2OOYnuFlTjGnb5ruc3D7KpSHleNTM
yLyRRUVTJ7jQXlp6WQPzkIvvLC4M60tlLd1F8QIcmVhbHmhS0UWAnfcN7E2Bw0Xh
1Zn6ERYh9JD8+aF+WJ78ZbmAZfgl3aYOps9SripRqQWkibQXXH35U6c0Qv8KHX0P
jU05nXGPAgMBAAECgf8fEWvTbWWv0V+2LsllSTeoKk8FGpHQjZsDpWARUJQZx2xJ
D01eD/9cxlqZx37xdSGYcAY2jgwn9nxALsEUA+OHLYrT2+d0MQh0gydFA+50wdVB
16jBQILbRVXXmsMPSEIWaFL87tzGF6yibDdwSlUAOOlKlXJdfqnYz8F6PfkchESA
vLwQixtT56Os1WvAqLIvfRVwuHftED0//nlbpIK9SZi9hr+d5+TuhdHo4xdLtaZ3
7kcPC+VfrPzrfusjCpUOo5Ud7J2meMzLzi/ElkYxdteHvanypdF7eW4CUfv9O7wO
LIRT61dTafIy67nQ6oKj6jAgrnUWM1MjP2PEbLECgYEA8b6N8rJuC+ci1deSmrMs
Bh1RI41X17G77cMCPrg1BGId8RBMcCL83eUhBggFzZOxiQfGq+wlnoPRrfjedpOL
Dm19t6WVZop/7Bmb0WZVKxZKtX0O59O8NTGYbTJQEjFtL3FvejQ7k3AfZqIvW6BP
zbFAOOXeWgHu4RypvGJLetECgYEAvUVkepZT7yDgfUV6seYczWd4TIwXKbfed+6L
rLjAeEWda4uWS1C4ITzvg2pGA2B8OiZJA2NvmrUhoTRSIeIFrHDGRpCR98uczixL
JDM9HTVwIJCy9Pw79fzk0LcTD1Ibwp2+G5S/R87P94du6cyGfw76h/MZXnSTyub3
iwCofl8CgYEAnC2jvzwPZJk7JDRVfqRquLiQBwv1yGAHLaBi/uo7Nk29UlRZTckM
3L5/C0p7lUjp1cG0VLYHx9UZze+OqcTAfd227sKHNuwboQkaZbpbI68PLRlSW+ur
GCKme0WZ/Wb5R0Fd5/F+284AO2pkdimn5Reyig/YCwZcsgq2jgJjCUECgYB+i+j0
dZJE7exqlYvFah+TzjyGoZvTDta1xU6p+xTk1Va9UyT30k5qGr3hVareEyK8FmD2
3QL/o1+K0tqfQOmeNAC9qWePEBoVV1QeLgwMfXAstdKRLhxBCgdK7TzXH4TkCGfV
NQz3S/WMgIbN1yuNxEwJnaY2myc9oFOeIqCFbQKBgQDhqeZA9CnFY+8IeKAfOPHb
M7Uba5Wl9YsswlBnXbOvO2M9KXXVfCfIglcrZQ7EbJXyDk3lK4PdDSKqgldXXZ2s
PLT6pJ0eeZ5snKTTfehx66su4UguCEIGkfnCB/dqDD2lR8+/lD4VrN7poq9oghXy
qs4ZRdobDWFpmEtQL+NnYg==
-----END RSA PRIVATE KEY-----
</key>
""")) {
        throw Exception("Unable to reach the VPN server.");
      }

      if (_statusTimer != null && _statusTimer!.isActive) {
        _statusTimer!.cancel();
        _statusTimer = null; // Clear the reference to prevent reuse
      }
      _monitorVpnStatus();
      saveLog("Connected to VPN successfully.");
      await engine.connect(
        vpnConfig,
        "US",
        username: vpnData.username,
        password: vpnData.password,
        bypassPackages: [],
        certIsRequired: false,
      );
    } catch (e) {
      //saveLog("Error during VPN connection: $e");
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
      saveLog("VPN disconnected successfully.");
    } catch (e) {
      saveLog("Error during VPN disconnection: $e");
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
        saveLog("VPN Status: ${status!.stage}");
      } catch (e) {
        saveLog("Error monitoring VPN status: $e");
      }
    });
  }

  void dispose() {
    _statusTimer?.cancel();
    _durationTimer?.cancel();
    saveLog("VPN service disposed.");
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

/* With the help of this method we can make the log file and save the logs */
  Future<void> saveLog(String log) async {
    try {
      // Get the directory for storing logs
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/vpn_logs.txt');

      // Create a timestamped log entry
      String timestampedLog = "[${DateTime.now().toIso8601String()}] $log\n";

      // Append the log to the file
      await file.writeAsString(timestampedLog, mode: FileMode.append);

      print("saveLog: Log saved successfully");
    } catch (e) {
      print("saveLog: Error writing log to file: $e");
    }
  }

 Future<String> getLogs() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/vpn_logs.txt');

    if (await file.exists()) {
      return await file.readAsString();
    } else {
      return "No logs found.";
    }
  } catch (e) {
    return "Error reading logs: $e";
  }
}
}
