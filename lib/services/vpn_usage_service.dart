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
      //print('No start time found. Exiting updateVpnUsageWithSplitting.');
      return;
    }

    final DateTime startTime = DateTime.parse(startTimeString);
    final DateTime now = DateTime.now();

    if (startTime.isAfter(now)) {
      // print('Start time is after the current time. Exiting.');
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
      int durationForCurrentDay = endOfDay.isAfter(now)
          ? now.difference(currentDate).inSeconds
          : endOfDay.difference(currentDate).inSeconds;

      if (durationForCurrentDay > remainingSeconds) {
        durationForCurrentDay = remainingSeconds;
      }

// Update usage for the current day
      final String dateKey = getDateKey(currentDate);
      currentUsage[dateKey] =
          (currentUsage[dateKey] ?? 0) + durationForCurrentDay;

// Move to the next day
      remainingSeconds -= durationForCurrentDay;
      currentDate = currentDate.add(const Duration(days: 1)).startOfDay();
    }

    // Save updated usage data
    await saveVpnUsageData(index, currentUsage);
    storeTimeStart();
  }

  // Remove VPN usage data from previous weeks
  Map<String, int> removeOldWeekData(Map<String, int> vpnUsageData) {
    DateTime now = DateTime.now();
    DateTime startOfWeek =
        now.startOfWeek(); // Start of the current week (Monday)
    // print('Removing old data. Current week starts on: ${startOfWeek.toIso8601String()}');

    // Keep only data from the current week
    final filteredEntries = vpnUsageData.entries.where((entry) {
      DateTime date = DateTime.parse(entry.key);
      return !date.isBefore(startOfWeek);
    });

    return Map<String, int>.fromEntries(filteredEntries);
  }

  // Save VPN usage data
  Future<void> saveVpnUsageData(
      String index, Map<String, int> vpnUsageData) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, int> filteredData = removeOldWeekData(vpnUsageData);
    await prefs.setString(index, jsonEncode(filteredData));
    //print('Saved VPN usage data: $filteredData');
  }

  // Get VPN usage data
  Future<Map<String, int>> getVpnUsageData(String index) async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(index);
    //print('Fetched VPN usage data: $data');
    return data != null ? Map<String, int>.from(jsonDecode(data)) : {};
  }

  // Helper: Get date as yyyy-MM-dd
  String getDateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// DateTime extensions for cleaner operations
extension DateTimeExtensions on DateTime {
  DateTime startOfDay() => DateTime(year, month, day);

  // Get start of the current week (Monday)
  DateTime startOfWeek() {
    int daysToSubtract = weekday - 1; // Monday = 1
    return subtract(Duration(days: daysToSubtract)).startOfDay();
  }

  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
