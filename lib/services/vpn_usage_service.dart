import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VpnUsageService {
  // Store the current time as the start time
  Future<void> storeTimeStart() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('startTime', now.toIso8601String());
  }

  // Update VPN usage data with splitting across days
  Future<void> updateVpnUsageWithSplitting(String index) async {
    final prefs = await SharedPreferences.getInstance();
    final String? startTimeString = prefs.getString('startTime');

    if (startTimeString == null) {
     
      return;
    }

    final DateTime startTime = DateTime.parse(startTimeString);
    final DateTime now = DateTime.now();

    if (startTime.isAfter(now)) {
     
      return;
    }

    // Retrieve current usage data
    Map<String, int> currentUsage = await getVpnUsageData(index);

    // Initialize time splitting
    DateTime currentDate = startTime;
    int remainingSeconds = now.difference(startTime).inSeconds;

    while (remainingSeconds > 0) {
      // Calculate the end of the current day
      final DateTime endOfDay = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        23,
        59,
        59,
      );

      // Calculate duration for the current day
      int durationForCurrentDay = currentDate.isSameDayAs(endOfDay)
          ? remainingSeconds
          : endOfDay.difference(currentDate).inSeconds + 1;

      if (durationForCurrentDay > remainingSeconds) {
        durationForCurrentDay = remainingSeconds;
      }

      // Update usage for the current day
      final String dateKey = getDateKey(currentDate);
      currentUsage[dateKey] = (currentUsage[dateKey] ?? 0) + durationForCurrentDay;

      // Move to the next day
      remainingSeconds -= durationForCurrentDay;
      currentDate = currentDate.add(const Duration(days: 1)).startOfDay();
    }
    // Save updated usage data
    await saveVpnUsageData(index, currentUsage);
    storeTimeStart();
  }

  // Update VPN usage data for the current day
  Future<void> updateVpnUsage(String index, int duration) async {
    Map<String, int> currentUsage = await getVpnUsageData(index);
    String day = getDayOfWeek();
    currentUsage[day] = (currentUsage[day] ?? 0) + duration;
    await saveVpnUsageData(index, currentUsage);
  }


Map<String, int> removeOldWeekData(Map<String, int> vpnUsageData) {
  DateTime now = DateTime.now();
  int currentWeek = getWeekOfYear(now);

  // Filter the Map using entries
  final filteredEntries = vpnUsageData.entries.where((entry) {
    DateTime date = DateTime.parse(entry.key);
    return getWeekOfYear(date) == currentWeek;
  });

  // Convert back to a Map
  return Map<String, int>.fromEntries(filteredEntries);
}
  // Save VPN usage data
  Future<void> saveVpnUsageData(String index, Map<String, int> vpnUsageData) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, int> filteredData = removeOldWeekData(vpnUsageData);
    await prefs.setString(index, jsonEncode(filteredData));
  }

  // Get VPN usage data
  Future<Map<String, int>> getVpnUsageData(String index) async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(index);
    return data != null ? Map<String, int>.from(jsonDecode(data)) : {};
  }

  // Set VPN connection status
  Future<void> setVpnConnectionStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('connectingStatus', status);
  }

  // Get VPN connection status
  Future<bool> getVpnConnectionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('connectingStatus') ?? false;
  }

  // Remove VPN connection status
  Future<void> removeVpnConnectionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('connectingStatus');
  }

  // Helper: Get date as yyyy-MM-dd
  String getDateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // Helper: Get day of the week
  String getDayOfWeek() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Helper: Get week of the year
  int getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    return ((date.difference(firstDayOfYear).inDays) / 7).floor() + 1;
  }
}

// DateTime extensions for cleaner operations
extension DateTimeExtensions on DateTime {
  DateTime startOfDay() => DateTime(year, month, day);
  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}