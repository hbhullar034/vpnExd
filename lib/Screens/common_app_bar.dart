import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CommonAppBar extends StatefulWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const CommonAppBar({super.key, required this.scaffoldKey});

  @override
  _CommonAppBarState createState() => _CommonAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CommonAppBarState extends State<CommonAppBar> {
  String appVersion = '';

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
          padding: const EdgeInsets.only(top: 15.0, right: 16.0),
          child: Text(
            appVersion.isNotEmpty ? 'v $appVersion' : '-', // Show version
            style: const TextStyle(
              color: Color.fromARGB(255, 168, 167, 167),
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
