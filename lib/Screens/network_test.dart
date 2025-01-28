import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/ips_detail_model.dart';
import '../models/network_data.dart';
import '../services/network_type_service.dart';
import '../widgets/network_widgets.dart';
import '../controller/theme_controller.dart';
import 'common_app_bar.dart';
import 'common_app_bar_with_drawer.dart';

class NetworkTestScreen extends StatefulWidget {
  const NetworkTestScreen({super.key});

  @override
  State<NetworkTestScreen> createState() => _NetworkTestScreenState();
}

class _NetworkTestScreenState extends State<NetworkTestScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final themeController = Get.find<ThemeController>();
  final ipData = IPDetails.fromJson({}).obs;
  Offset _floatingButtonOffset =  Offset(300, 600); // Initial position of the button

  @override
  void initState() {
    super.initState();
    APIs.getIPDetails(ipData: ipData);
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    key: _scaffoldKey,
    extendBodyBehindAppBar: true,
    resizeToAvoidBottomInset: false,
    appBar: CommonAppBar(scaffoldKey: _scaffoldKey),
    drawer: const CommonDrawer(),
    body: Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Obx(
            () => Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(themeController.innerImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),

        // Content
        Obx(
          () => ListView(
            padding: const EdgeInsets.only(top: 200, left: 16, right: 16),
            children: [
              // IP Address
              NetworkCard(
                data: NetworkData(
                  title: 'IP Address',
                  subtitle: ipData.value.query ?? 'Fetching...',
                  icon: const Icon(
                    CupertinoIcons.location_solid,
                    color: Colors.blue,
                  ),
                ),
              ),

              // Internet Provider
              NetworkCard(
                data: NetworkData(
                  title: 'Internet Provider',
                  subtitle: ipData.value.isp ?? 'Fetching...',
                  icon: const Icon(Icons.business, color: Colors.orange),
                ),
              ),

              // Location
              NetworkCard(
                data: NetworkData(
                  title: 'Location',
                  subtitle: ipData.value.country.isEmpty
                      ? 'Fetching...'
                      : '${ipData.value.city}, ${ipData.value.regionName}, ${ipData.value.country}',
                  icon: const Icon(CupertinoIcons.location, color: Colors.pink),
                ),
              ),

              // Pin-code
              NetworkCard(
                data: NetworkData(
                  title: 'Pin-code',
                  subtitle: ipData.value.zip ?? 'Fetching...',
                  icon: const Icon(CupertinoIcons.location_solid,
                      color: Colors.cyan),
                ),
              ),

              // Timezone
              NetworkCard(
                data: NetworkData(
                  title: 'Timezone',
                  subtitle: ipData.value.timezone ?? 'Fetching...',
                  icon: const Icon(CupertinoIcons.time, color: Colors.green),
                ),
              ),
            ],
          ),
        ),

        // Movable FloatingActionButton
        Positioned(
          left: _floatingButtonOffset.dx,
          top: _floatingButtonOffset.dy,
          child: Draggable(
            feedback: FloatingActionButton(
              onPressed: null, // Non-interactive during drag
              foregroundColor: Theme.of(context).colorScheme.buttonTextColor,
              backgroundColor:
                  Theme.of(context).colorScheme.buttonBackgroundColor,
              shape: CircleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.buttonBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(CupertinoIcons.refresh),
            ),
            childWhenDragging: SizedBox(), // Placeholder during drag
            onDragEnd: (details) {
              setState(() {
                // Prevent the button from going outside the screen
                final newOffset = details.offset;

                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;

                // Constrain within screen bounds
                _floatingButtonOffset = Offset(
                  newOffset.dx.clamp(10, screenWidth - 56), // 56 is FAB size
                  newOffset.dy.clamp(56, screenHeight - 56),
                );
              });
            },
            child: FloatingActionButton(
              onPressed: () {
                ipData.value = IPDetails.fromJson({});
                APIs.getIPDetails(ipData: ipData);
              },
              foregroundColor: Theme.of(context).colorScheme.buttonTextColor,
              backgroundColor:
                  Theme.of(context).colorScheme.buttonBackgroundColor,
              shape: CircleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.buttonBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(CupertinoIcons.refresh),
            ),
          ),
        ),
      ],
    ),
  );
}

}
