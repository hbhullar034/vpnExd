import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'common_app_bar.dart';
import 'common_app_bar_with_drawer.dart';
import 'package:get/get.dart';
import '../controller/theme_controller.dart';
class AboutPage extends StatefulWidget {
   const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
String appVersion = '';
 final themeController = Get.find<ThemeController>();
  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      key: _scaffoldKey, // Assign the GlobalKey to the Scaffold
     appBar: CommonAppBar(scaffoldKey: _scaffoldKey),
      drawer: const CommonDrawer(),
      extendBodyBehindAppBar: true, 
      body:Stack(
        children: [ 
       Positioned.fill(
            child: Container(
              decoration:  BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(themeController.innerImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
             Center(
              child: Column(
                children: [
                  const Icon(Icons.info, size: 100, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    "About Us",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:  Theme.of(context).colorScheme.themeTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App description
           
            const SizedBox(height: 8),
             Text(
              "Exdvpn App is a secure and reliable VPN service that ensures your online privacy and anonymity. Easily connect to servers worldwide and enjoy a secure browsing experience.",
              style: TextStyle(fontSize: 16,color: Theme.of(context).colorScheme.themeTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
              Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            // App version
            Text(
              appVersion.isNotEmpty ? 'v $appVersion' : '-',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
           const Text(
              " | ",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const Text(
              "By Exd Vpn",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
              ]
              ),
            

       
            
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // Replace with your privacy policy URL
                debugPrint("Privacy Policy clicked");
              },
              child: const Text(
                "Read our Privacy Policy",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
        ],
    )
    );
  }
}
