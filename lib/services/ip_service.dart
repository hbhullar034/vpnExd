import 'package:network_info_plus/network_info_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
class IpService {
  final NetworkInfo _networkInfo = NetworkInfo();
  Future<String?> getPublicIpAddress() async {
    try {
      // Fetch the public IP from an external API
      final response = await http.get(Uri.parse('https://api.myip.com'));

      if (response.statusCode == 200) {
        print("response.body ${response.body}");
        // If the request is successful, return the public IP address
        return response.body;

      } else {
        print("Failed to load IP: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching public IP: $e");
      return null;
    }
  }

  Future<String?> getLocalIpAddress() async {
    try {
      // Get the local IP address (Wi-Fi IP)
      String? ipAddress = await _networkInfo.getWifiIP();
      print("Local IP: $ipAddress");
      return ipAddress;
    } catch (e) {
      print("Failed to get local IP address: $e");
      return null;
    }
  }
}


class IpDetailsService {
  Map<String, dynamic>? _cachedData; // Store the cached data
  DateTime? _lastFetchedTime;
  final Duration cacheDuration = Duration(minutes: 1); // Cache for 1 minute

  Future<Map<String, dynamic>> getIpDetails(ip) async {
    
    if (_cachedData != null && _lastFetchedTime != null) {
      final elapsedTime = DateTime.now().difference(_lastFetchedTime!);
      if (elapsedTime < cacheDuration) {
        return _cachedData!; // Return cached data if it's still valid
      }
    }

    final response = await http.get(Uri.parse('https://ipinfo.io/$ip?token=66597aabbe4811'));
    print("response${response.statusCode}");
    if (response.statusCode == 200) {
      _cachedData = jsonDecode(response.body); // Cache the response
      _lastFetchedTime = DateTime.now(); // Update the fetch time
      return _cachedData!;
    } else {
      throw Exception('Failed to load IP details');
    }
  }
}
