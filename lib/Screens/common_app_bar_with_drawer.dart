// ignore: file_names
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../controller/theme_controller.dart';
import 'network_test.dart';
import 'vpn_dashboard.dart';
import 'about_page.dart';
import 'vpn_url_screen.dart';

class CommonDrawer extends StatefulWidget {
  const CommonDrawer({super.key});

  @override
  State<CommonDrawer> createState() => _CommonDrawerState();
}

class _CommonDrawerState extends State<CommonDrawer>
    with WidgetsBindingObserver {
  final themeController = Get.find<ThemeController>();
  String appVersion = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppVersion();
  }
    

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = packageInfo.version; // Fetch app version
    });
  }

 @override
Widget build(BuildContext context) {
  return Drawer(
    child: Column(
      children: [
        // Top container for background image and logo
        Container(
          height: 200, // Explicit height for the top area
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/images/background.jpg'), // Background image
              fit: BoxFit.cover, // Ensures the image covers the entire container
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 100, // Adjust logo size as needed
                width: 100,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),

        // Middle section for menu items
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.primeryTheme, // Set background color
            child: ListView(
              padding: EdgeInsets.zero, // Remove padding
              children: [
                ListTile(
                  leading:
                       Icon(Icons.home, color: Theme.of(context).colorScheme.menuIconColor),
                  title:  Text('Home',
                      style: TextStyle(color: Theme.of(context).colorScheme.menuTitleColor)),
                  onTap: () {
                    void navigateToVpnDashboard(BuildContext context) {
                      if (ModalRoute.of(context)?.settings.name != null) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pop(context); // Close the current screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            settings:
                                const RouteSettings(name: "/vpndashboard"),
                            builder: (context) => const Vpndashboard(),
                          ),
                        );
                      }
                    }
                    navigateToVpnDashboard(context);
                  },
                ),
                ListTile(
                  leading:  Icon(Icons.settings,
                      color: Theme.of(context).colorScheme.menuIconColor),
                  title:  Text('Create New Profile',
                      style: TextStyle(color: Theme.of(context).colorScheme.menuTitleColor)),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const VpnUrlScreen(), // Destination screen
                      ),
                    );
                  },
                ),
               
               
                ListTile(
                  leading:
                       Icon(Icons.info, color: Theme.of(context).colorScheme.menuIconColor),
                  title:  Text('Network',
                      style: TextStyle(color: Theme.of(context).colorScheme.menuTitleColor)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NetworkTestScreen(), // Destination screen
                      ),
                    );
                  },
                ),
                 ListTile(
                  leading:
                       Icon(Icons.info, color: Theme.of(context).colorScheme.menuIconColor),
                  title:  Text('About',
                      style: TextStyle(color: Theme.of(context).colorScheme.menuTitleColor)),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AboutPage(), // Destination screen
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Bottom section for app version
        Align(
          alignment: Alignment.bottomRight, // Align to bottom-right
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Add spacing from the edges
            child: Text(
              appVersion.isNotEmpty ? 'v $appVersion' : '-', // Show version
              style: const TextStyle(
                color: Color.fromARGB(255, 168, 167, 167),
                fontSize: 12.0, // Adjusted font size
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

}
