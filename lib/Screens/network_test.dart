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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    APIs.getIPDetails(ipData: ipData);

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: CommonAppBar(scaffoldKey: _scaffoldKey),
      drawer: const CommonDrawer(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10, right: 10),
        child: FloatingActionButton(
          onPressed: () {
            ipData.value = IPDetails.fromJson({});
            APIs.getIPDetails(ipData: ipData);
          },
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
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
              physics: const BouncingScrollPhysics(),
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
        ],
      ),
    );
  }
}
