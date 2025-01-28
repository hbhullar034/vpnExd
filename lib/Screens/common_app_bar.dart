import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../controller/theme_controller.dart';

class CommonAppBar extends StatefulWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const CommonAppBar({super.key, required this.scaffoldKey});

  @override
  // ignore: library_private_types_in_public_api
  _CommonAppBarState createState() => _CommonAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CommonAppBarState extends State<CommonAppBar> {
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
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            widget.scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Image.asset(
          'assets/images/logo.png',
          height: 37,
          fit: BoxFit.cover,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Obx(() {
            return InkWell(
              onTap: () {
                themeController.toggleTheme();
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(8.0), // Increase touch area
                child: Icon(
                  themeController.isDarkMode.value
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: themeController.isDarkMode.value
                      ? Colors.white
                      : Colors.white,
                ),
              ),
            );
          }),
        ),

        // Space between the last action and the edge
      ],
    );
  }
}
