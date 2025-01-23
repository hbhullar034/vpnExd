// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
//import 'package:workmanager/workmanager.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import './services/vpn_service.dart'; // Your custom VPN service
import 'Screens/vpn_dashboard.dart';
import 'controller/theme_controller.dart';

late Size mq;
final VpnService _vpnService = VpnService();
const platform = MethodChannel('com.example.app/vpn');

class MyAppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        //registerBackgroundTask(); // Register background task when app resumes
        break;

      case AppLifecycleState.inactive:
        // Handle transition between foreground and background
        //clearConnectingIndexOnStart();
        break;

      case AppLifecycleState.paused:
        
        break;

      case AppLifecycleState.detached:
        // Handle termination: stop VPN service and cleanup
        //await stopVpnService(); // Ensure VPN stops when app terminates
        break;

      case AppLifecycleState.hidden:
        // Handle case if app is hidden (not in the foreground or background)
        //print('App hidden.');
        break;
    }
  }
}

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  _vpnService.initialize();
  WidgetsBinding.instance.addObserver(MyAppLifecycleObserver());
WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // Initialize GetStorage
  Get.put(ThemeController()); // Register the controller

  // platform.setMethodCallHandler((call) async {
  //   if (call.method == "vpnCleanup") {
  //     callbackDispatcher(); // Trigger VPN cleanup tasks
  //   }
  // });

  // Initialize Workmanager for background tasks
  // Workmanager().initialize(
  //   callbackDispatcher,
  //   isInDebugMode: true, // Disable for production
  // );
runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      return GetMaterialApp(
       debugShowCheckedModeBanner: false,
        theme: themeController.isDarkMode.value
            ? themeController.darkTheme
            : themeController.lightTheme,
        home: const MaterialApp(home: Vpndashboard()),
      );
    });
  }
}

// Future<void> startVpnService() async {
//   try {
//     await platform.invokeMethod('startVpnService');
//   } catch (e) {
//     print("Failed to start VPN service: $e");
//   }
// }

// Future<void> stopVpnService() async {
//   //clearConnectingIndexOnStart();
//   //callbackDispatcher();
//   print("Attempting to stop VPN service...");
//   try {
//     await platform.invokeMethod('stopVpnService');
//     print("VPN service stopped successfully.");
//   } catch (e) {
//     print("Error while stopping VPN service: $e");
//   }
// }

// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     print("Background task executed: $task");

//     if (task == "vpnCleanup") {
//       try {
//         // Assuming _vpnService has the disconnectVpn method
//         final currentStatus = await _vpnService.getCurrentStatus();
//         if (currentStatus != null) {
//           await _vpnService.disconnectVpn();
//           print("VPN cleanup started...");
//         }
//         print("VPN cleanup completed successfully.");
//       } catch (e) {
//         print("Error during VPN cleanup: $e");
//       }
//     }

//     return Future.value(true); // Indicate successful task completion
//   });
// }

// void registerBackgroundTask() {
//   Workmanager().registerOneOffTask(
//     "vpnCleanupTask", // Task ID
//     "vpnCleanup", // Task name
//     inputData: {"task": "cleanupVpn"},
//     initialDelay: Duration(seconds: 30),
//     backoffPolicy: BackoffPolicy.exponential, // Correct parameter
//     constraints: Constraints(
//       networkType: NetworkType
//           .connected, // Add constraints like network connection if needed
//     ),
//   );
// }

// Future<void> clearConnectingIndexOnStart() async {
//   final prefs = await SharedPreferences.getInstance();
//   if (prefs.containsKey('connectingIndex')) {
//     //await prefs.remove('connectingIndex');
//     //await prefs.remove('connectingStatus');
//   }
// }

// Landing Page Widget
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize VPN service
    _vpnService.initialize();

    // Navigate to VPN Dashboard after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      print("testt");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Vpndashboard()),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay Content
        ],
      ),
    );
  }
}

