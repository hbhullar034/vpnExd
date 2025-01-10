import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ProtectedCardWidget extends StatefulWidget {
  final String? selectedIndex;

  const ProtectedCardWidget({Key? key, this.selectedIndex}) : super(key: key);

  @override
  _ProtectedCardWidgetState createState() => _ProtectedCardWidgetState();
}

class _ProtectedCardWidgetState extends State<ProtectedCardWidget> {
  int touchedIndex = -1; // To track the touched bar
  Map<String, double>? vpnUsageData;
  bool isLoading = false; // Track loading state
  Timer? _timer; // Timer to refresh data
   double barWidth = 20.0; // Set your bar width here
   double barSpacing = 10.0; // Optional: Space between bars
  // Save VPN usage data (in minutes for example)
  Future<void> saveVpnUsageData(String index, int usageInMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(today);

    String? storedData = prefs.getString('vpnUsageData_$index');
    Map<String, int> vpnUsageData = {};

    if (storedData != null) {
      vpnUsageData = Map<String, int>.from(jsonDecode(storedData));
    }

    // Update the data for today
    vpnUsageData[dateKey] = usageInMinutes;

    // Save the updated data
    await prefs.setString(index, jsonEncode(vpnUsageData));
    _loadVpnData();
  }
    @override
  void initState() {
    super.initState();
    _loadVpnData(); // Load data initially
    _startAutoRefresh(); // Start the refresh every minute
  }
    @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }
 // Start a timer to refresh data every 60 seconds
  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadVpnData(); // Refresh data
    });
  }
  // Retrieve and process VPN usage data
 Future<Map<String, double>> getVpnUsageDataInHours(String? index) async {
  if (index == null) {
    return {
      "Mon": 0.0,
      "Tue": 0.0,
      "Wed": 0.0,
      "Thu": 0.0,
      "Fri": 0.0,
      "Sat": 0.0,
      "Sun": 0.0,
    };
  }

  final prefs = await SharedPreferences.getInstance();
  String? storedData = prefs.getString(index);

  if (storedData != null) {
    Map<String, int> vpnUsageData =
        Map<String, int>.from(jsonDecode(storedData));
      
    Map<String, double> weekData = {};
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      DateTime day = now.subtract(Duration(days: i));
      String dateKey = DateFormat('yyyy-MM-dd').format(day);
      String dayName = DateFormat('EEE').format(day);

      // Convert minutes to hours
      double usageInHours = (vpnUsageData[dateKey] ?? 0) / 3600.0;
      weekData[dayName] = usageInHours;
    }
    return weekData;
  } else {
    return {
      "Mon": 0.0,
      "Tue": 0.0,
      "Wed": 0.0,
      "Thu": 0.0,
      "Fri": 0.0,
      "Sat": 0.0,
      "Sun": 0.0,
    };
  }
}


  @override
  void didUpdateWidget(covariant ProtectedCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only fetch new data when selectedIndex changes
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      setState(() {
        isLoading = true;
        vpnUsageData = null; // Reset data when index changes
      });

      // Fetch new VPN data
      _loadVpnData();
    }
  }

  // Load VPN data asynchronously
  Future<void> _loadVpnData() async {
    if (widget.selectedIndex == null) return;

    Map<String, double> data =
        await getVpnUsageDataInHours(widget.selectedIndex);

    setState(() {
      vpnUsageData = data;
      isLoading = false; // Set loading state to false when data is fetched
    });
  }

  Widget _buildProtectedCardWithGraph() {
    // If no VPN is selected, show message
    if (widget.selectedIndex == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
             border: Border.all(
              color: const Color.fromARGB(255, 226, 224, 224),
              width: 1, // Thickness of the border
            ),
          
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Time Protected (in Hours)",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              "No VPN is selected",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: buildBarChart({
                "Mon": 0.0,
                "Tue": 0.0,
                "Wed": 0.0,
                "Thu": 0.0,
                "Fri": 0.0,
                "Sat": 0.0,
                "Sun": 0.0,
              }, 1),
            ),
          ],
        ),
      );
    }

    // Show loading spinner if data is being fetched
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Show graph once the data is fetched
    if (vpnUsageData != null) {
      double maxUsage = vpnUsageData!.values.isEmpty
          ? 0
          : vpnUsageData!.values.reduce((a, b) => a > b ? a : b);
      double maxY = maxUsage > 0 ? maxUsage + 1 : 1;

      return Container(
        padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
             border: Border.all(
              color: const Color.fromARGB(255, 226, 224, 224),
              width: 1, // Thickness of the border
            ),
          
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Time Protected (in Hours)",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: buildBarChart(vpnUsageData!, maxY),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
             border: Border.all(
              color: const Color.fromARGB(255, 226, 224, 224),
              width: 1, // Thickness of the border
            ),
          
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Time Protected (in Hours)",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: buildBarChart(vpnUsageData!, 2),
          ),
        ],
      ),
    );
  }

  int _getDayIndex(String day, String today) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    int todayIndex = days.indexOf(today);

    return (days.indexOf(day) - todayIndex + 7) % 7;
  }

 Widget buildBarChart(Map<String, double> vpnUsageData, double maxY) {
  String today =
      DateFormat('EEE').format(DateTime.now()); // Get the current day name

  final daysInOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  
  // Get today's DateTime
  final DateTime now = DateTime.now();
  final int todayIndex = daysInOrder.indexOf(today);
  final sortedData = daysInOrder.map((day) {
    return MapEntry(day, vpnUsageData[day] ?? 0.0);
  }).toList();

  return BarChart(BarChartData(
    borderData: FlBorderData(
      show: false, // Hides the border lines
    ),
    alignment: BarChartAlignment.spaceAround,
    maxY: 24.0, // Set the max to 24 hours
    barGroups: sortedData.map((entry) {
      final day = entry.key;
      final usage = entry.value;

      // Get the DateTime for the current day
      final int dayIndex = daysInOrder.indexOf(day);
      final DateTime dayDate = now.subtract(Duration(days: todayIndex - dayIndex));
      // Set the color of the bars based on usage and the day
      Color barColor;
      Color blankColor;
      //final bool isPast = dayDate.isBefore(now);
      final bool isFuture = dayDate.isAfter(now);
      //inal bool isToday = day == today;
      // Future days are always gray
      if (isFuture) {
        barColor = const Color(0xFFB9DBFF); // Gray for future days
       
      }
      // Past days with no usage (blank) are also gray
      else if (usage == 0) {
        barColor = const Color(0xFF0FB52F); // Gray for past days with no usage
        
      }
      // If VPN usage is present, use green
      else {
        barColor = const Color(0xFF0FB52F);
      }
       if (isFuture) {
        blankColor = const Color(0xFFB9DBFF);
      }
      // Past days with no usage (blank) are also gray
      else {
        blankColor = const Color(0xFF0D4274);
      }
     
   
      return BarChartGroupData(
        x: _getDayIndex(day, today),
        barRods: [
          BarChartRodData(
            fromY: 0,
            toY: usage,
            color: barColor,
            width: 12,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: blankColor,
          ),
          ),
        ],
      );
    }).toList(),
    gridData: FlGridData(show: false),
    titlesData: FlTitlesData(
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
            int todayIndex = days.indexOf(today);
            String dayName = days[(value.toInt() + todayIndex) % 7];
            return Text(dayName, style: const TextStyle(color: Colors.black));
          },
        ),
      ),
    ),
    barTouchData: BarTouchData(
  touchTooltipData: BarTouchTooltipData(
    getTooltipColor: (_) => Colors.blueGrey,
    tooltipPadding: const EdgeInsets.all(8),
    tooltipMargin: 40,
    getTooltipItem: (group, groupIndex, rod, rodIndex) {
      String day = daysInOrder[groupIndex.toInt()];
      double usageInHours = rod.toY; // Usage is already in hours

      return BarTooltipItem(
        '$day\n',
        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        children: [
          TextSpan(
            text: '${usageInHours.toStringAsFixed(2)} Hours',
            style: const TextStyle(color: Colors.yellow),
          ),
        ],
      );
    },
  ),
  touchCallback: (FlTouchEvent event, barTouchResponse) {
  setState(() {
    if (!event.isInterestedForInteractions) {
      touchedIndex = -1;
      return;
    }

    if (barTouchResponse == null || barTouchResponse.spot == null) {
      final localPosition = event.localPosition;
      if (localPosition != null) {
        //final touchedX = localPosition.dx;
        //final groupIndex = (touchedX ~/ (barWidth + barSpacing)).clamp(0, daysInOrder.length - 1);
        //touchedIndex = groupIndex;
      } else {
        touchedIndex = -1;
      }
    } else {
      touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
    }
  });
},
  allowTouchBarBackDraw: true, // Optional: Allows interactions with the background
),
    
  ),
  );
}




  @override
  Widget build(BuildContext context) {
    return _buildProtectedCardWithGraph();
  }
}
