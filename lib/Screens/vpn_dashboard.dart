// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:openvpn_app/Screens/graph.dart';
import '../services/network_service.dart';
import 'common_app_bar.dart';
import '../constants/colors.dart';
import 'confirmation_dialog.dart';
import 'common_app_bar_with_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vpn_status_model.dart';
import '../models/vpn_data_model.dart';
import 'package:http/http.dart' as http;
import '../services/vpn_service.dart';
import 'login_page.dart';
import 'vpn_stats_page.dart';
import 'vpn_url_screen.dart';

class Vpndashboard extends StatelessWidget {
  const Vpndashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VPNPage(),
    );
  }
}

class VPNPage extends StatefulWidget {
  const VPNPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _VPNPageState createState() => _VPNPageState();
}

class _VPNPageState extends State<VPNPage> {
  final VpnService _vpnService = VpnService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String selectedLocation = "USA - Florida";
  final ScrollController _scrollController = ScrollController();
  final NetworkService _networkService = NetworkService();
  bool _isOffline = false;
  double _scaleFactor = 1.0;
  double scaleHeightFirst = 120; //  height top of Connected timer
  double scaleHeightSecond = 20; // height top of circle
  //final OpenVpnService _vpnService = OpenVpnService();
  bool isConnecting = false;
  List<VpnData> vpnData = [];
  OpenVpnStatus? openVpnStatus; // Changed from Map to OpenVpnStatus
  String stage = 'disconnected';
  String? connectingIndex = '';
  String? selectedIndex;
  bool _isButtonDisabled = false;

  bool isDropdownOpen = false;
  String? ipAddress = '';
  String? cachedIpAddress; //store ip address
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener); // Add scroll listener
    checkIndex();
    _loadVpnData();
    getIp();
    _startMonitoring();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    // Dispose of the scroll controller safely
    if (_scrollController.hasClients) {
      _scrollController.dispose();
    }
    // Call the parent dispose method
    super.dispose();
  }

  Future<void> _loadVpnData() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString('vpnData');
    if (storedData != null) {
      setState(() {
        vpnData = (jsonDecode(storedData) as List)
            .asMap()
            .entries
            .map((entry) => VpnData.fromJson(entry.value, entry.key))
            .toList()
            .cast<VpnData>();
      });
      // Load the connecting index
      String? savedIndex = prefs.getString('connectingIndex');
      if (savedIndex != null) {
        String? connectingIndex = savedIndex;

        try {
          // Update the UI to reflect the connection state
          setState(() {
            isConnecting = true;
            selectedIndex = connectingIndex;
          });
          final currentStatus = _vpnService.getCurrentStatus();
          
          if (currentStatus == null) {
            _vpnService.initialize();
          }
        } catch (error) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${error.toString()}')),
          );
          _disconnectVpn();
        }
      }
    }
  }

  void checkIndex() async {
    connectingIndex = await getConnectingIndex();
    //selectedIndex = connectingIndex;
  }
   void _startMonitoring() async {
    // Start monitoring network status
    await _networkService.startMonitoring(_handleNetworkStatusChange);
  }
  void _handleNetworkStatusChange(bool isOffline) {
    setState(() {
      _isOffline = isOffline;
    });
    if (_isOffline) {
      _showNetworkErrorDialog();
    }
  }
   void _showNetworkErrorDialog() {
    if (_isOffline) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Network Error'),
            content: const Text('You are offline. Please check your connection.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  _isOffline= false;
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
  Future<String?> getConnectingIndex() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedIndex = prefs.getString('connectingIndex');
    setState(() {
      connectingIndex = savedIndex;
    });
    return savedIndex != null ? savedIndex.toString() : '';
  }

 Future<void> _connectVpn(String id) async {
  try {
     // Check for internet connectivity
    // Fetch VPN data asynchronously
    final VpnData vpnData = await _vpnService.getVpnDataByIndex(id);

    // Save the connecting index to persistent storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('connectingIndex', id);

    // Update local state to indicate that a connection attempt is in progress
    setState(() {
      connectingIndex = id;
      isConnecting = true;
    });

    // Attempt to connect to the VPN using the fetched VPN data
    await _vpnService.connectVpn(vpnData, id);

    // Optionally check the VPN status
    final OpenVpnStatus? status = _vpnService.getCurrentStatus();
    if (status?.stage != 'connected') {
      throw Exception(
          "VPN failed to connect. Status: ${status?.stage ?? 'unknown'}");
    }
  } catch (error) {
    _vpnService.setStatusCustom();
    await _disconnectVpn();
    // Handle errors gracefully
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to connect: ${error.toString()}")),
    );
  }
}

  Future<void> alreadyConnected(
      BuildContext context, dynamic vpnData, String id) async {
    if (_vpnService.getConnectingStatus() == true) {
      // Show confirmation popup
      final bool userConfirmed = await ConfirmationDialog.show(
        context: context,
        title: "VPN Connection",
        content:
            "A VPN connection is already in progress. Do you want to disconnect and connect to a new VPN server?",
        cancelButtonText: "Cancel",
        confirmButtonText: "Proceed",
        confirmButtonColor: Colors.green,
      );
      if (userConfirmed) {
        await _disconnectVpn(); // First disconnect VPN
        selectedIndex = id; // Then connect to new VPN
      }
    } else {
      // Directly connect if no ongoing VPN connection
      _connectVpn(id);
    }
  }

  String _formattedDuration(OpenVpnStatus? status) {
    // Check if the status is null, if not format the duration
    if (status != null) {
      final duration = status.formattedDuration;
      // Additional formatting logic if needed
      return duration;
    }
    return "00:00:00"; // Fallback if null
  }

  // Method to show confirmation dialog

  Future<void> _disconnectVpn() async {
    debugPrint("disconnetcd");
    // Your logic to stop the VPN connection
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('connectingIndex');
    setState(() {
      connectingIndex = null;
      isConnecting = false;
      stage = 'disconnected';
      openVpnStatus = null;
      //'00:00:00';
    });
    refreshIp();
    getIp();
    await _vpnService.disconnectVpn();
  }

  Color getBorderColor(String? stage) {
    if (_vpnService.getConnectingStatus() == true && stage != 'connected') {
      return Colors.blue; // Connecting but not connected
    } else if (stage == 'connected') {
      return Colors.green; // Successfully connected
    } else {
      return Colors.red; // Default case or disconnected
    }
  }

  void refreshIp() {
    cachedIpAddress = null; // Clear the cached value
    setState(() {}); // Trigger a rebuild to fetch the IP again
  }

  Future<String?> getIp() async {
    try {
      // Check if the IP address is already cached
      if (cachedIpAddress != null) {
        return cachedIpAddress;
      }

      final response =
          await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        // If the server returns a successful response, parse the IP address
        final data = jsonDecode(response.body);
        cachedIpAddress = data['ip']; // Cache the IP address
        setState(() {
          ipAddress = cachedIpAddress;
        });
        return cachedIpAddress;
      } else {
        throw Exception('Failed to load IP');
      }
    } catch (e) {
      debugPrint('Error fetching public IP: $e');
      return null;
    }
  }

  String formatBytes(double bytes) {
    if (bytes >= 1e9) {
      // Convert to GB if greater than or equal to 1GB (1e9 bytes)
      return '${(bytes / 1e9).toStringAsFixed(2)} GB';
    } else if (bytes >= 1e6) {
      // Convert to MB if greater than or equal to 1MB (1e6 bytes)
      return '${(bytes / 1e6).toStringAsFixed(2)} MB';
    } else if (bytes >= 1e3) {
      // Convert to KB if greater than or equal to 1KB (1e3 bytes)
      return '${(bytes / 1e3).toStringAsFixed(2)} KB';
    } else {
      // Return bytes if it's less than 1KB
      return '${bytes.toStringAsFixed(2)} B';
    }
  }

  // Function to listen to scroll events and adjust the CircleAvatar size
  void _scrollListener() {
    double scale =
        1 - (_scrollController.offset / 100); // Shrink factor based on scroll

    // Ensure the scale doesn't get too small or large
    if (scale < 0.5) {
      scale = 0.5; // Minimum scale limit
    } else if (scale > 2) {
      scale = 2; // Maximum scale limit
    }
    double scrollHeight;
    if (_scrollController.offset / 3 > 20) {
    scrollHeight = 18;
    } else  {
      scrollHeight = _scrollController.offset / 3;
    }
       
    setState(() {
      scaleHeightFirst = 120 -scrollHeight;
      scaleHeightSecond = 20 - scrollHeight;
      _scaleFactor = scale; // Update the scale factor
    });
    debugPrint("scaleHeightFirst $scaleHeightFirst");
    debugPrint("scaleHeightSecond $scaleHeightSecond");
  }

  @override
  Widget build(BuildContext context) {
    // Get the current orientation (portrait or landscape)
    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      key: _scaffoldKey, // Assign the GlobalKey to the Scaffold
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset:
          false, // Prevent resizing when keyboard is visible
      appBar: CommonAppBar(scaffoldKey: _scaffoldKey),
      drawer: const CommonDrawer(),
      body: Stack(children: [
        ValueListenableBuilder<OpenVpnStatus?>(
            valueListenable: _vpnService.getCurrentStatusNotifier(),
            builder: (context, status, child) {
              String stageResult = status?.stage ?? 'disconnected';
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      _vpnService.getConnectingStatus() == true &&
                              stageResult != 'connected'
                          ? 'assets/images/blue.png'
                          : stageResult == 'connected'
                              ? 'assets/images/green.png'
                              : 'assets/images/red.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: orientation == Orientation.portrait
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: scaleHeightFirst),
                          const Text(
                            "Connected Time",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          ValueListenableBuilder<OpenVpnStatus?>(
                            valueListenable:
                                _vpnService.getCurrentStatusNotifier(),
                            builder: (context, status, child) {
                              return Text(
                                _formattedDuration(status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: scaleHeightSecond),
                          AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 200), // Duration for animation
                            curve: Curves.easeInOut, // Smooth animation
                            child: Transform.scale(
                              scale:
                                  _scaleFactor, // Apply scale factor to the whole container
                              child: Container(
                                width: 230, // Keep the base width
                                height: 230,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: getBorderColor(stageResult),
                                    width: 12,
                                  ),
                                ),
                                child: InkWell(
                                  // Wrap the whole container with InkWell
                                  onTap: () async {
                                   
                                    if (_isButtonDisabled) {
                                      return; // Prevent multiple clicks
                                    }
                                    _isButtonDisabled =
                                        true; // Disable the button

                                    try {
                                      if (stageResult == 'connected') {
                                        // Disconnect logic
                                         _disconnectVpn();
                                          Future.delayed(
                                          const Duration(seconds: 3));
                                      _isButtonDisabled = false;
                                    
                                      } else {
                                        // Connect logic
                                        if (selectedIndex != null &&
                                            vpnData.isNotEmpty) {
                                           _connectVpn(selectedIndex!);
                                           Future.delayed(
                                          const Duration(seconds: 3));
                                      _isButtonDisabled = false;
                                        } else {
                                          // Show SnackBar for missing VPN selection
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "Please select a VPN")),
                                          );
                                           Future.delayed(
                                          const Duration(seconds: 3));
                                      _isButtonDisabled = false;
                                        }
                                      }
                                    } catch (e) {
                                      // Handle any errors if needed
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text("An error occurred: $e")),
                                      );
                                    } 
                                  },
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 22.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.power_settings_new,
                                            color:
                                                _vpnService.getConnectingStatus() ==
                                                            true &&
                                                        stageResult !=
                                                            'connected'
                                                    ? Colors.blue
                                                    : stageResult == 'connected'
                                                        ? Colors.green
                                                        : Colors.red,
                                            size: 70,
                                          ),
                                          const SizedBox(height: 5),
                                          const Text(
                                            "Your IP",
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 148, 145, 145),
                                              fontSize: 20,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          ipTextFieldWidget(stageResult),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Adjust layout based on orientation
                          // Portrait Layout (SingleChildScrollView)
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child:
                                        _buildSelectedLocationDropdown(context),
                                  ),

                                  const SizedBox(height: 10),
                                  // Stack of VPN Info and other widgets
                                  Stack(
                                    children: <Widget>[
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 4,
                                            right: 4,
                                            top: 0,
                                            bottom: 0),
                                        padding: const EdgeInsets.only(
                                            left: 20,
                                            right: 20,
                                            top: 0,
                                            bottom: 0),
                                        child: ProtectedCardWidget(
                                            selectedIndex: selectedIndex),
                                      ),
                                    ],
                                  ),

                                  // Additional stats and content
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        VpnStatTile(
                                            label: 'Byte In',
                                            valueFormatter: formatBytes(
                                                (status?.byteIn ?? 0)
                                                    .toDouble()),
                                            icon: Icons.arrow_downward,
                                            iconColor: Colors.red),
                                        VpnStatTile(
                                            label: 'Byte Out',
                                            valueFormatter: formatBytes(
                                                (status?.byteOut ?? 0)
                                                    .toDouble()),
                                            icon: Icons.arrow_upward,
                                            iconColor: Colors.green),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          )
                        ],
                      )
                    : Container(
                        padding: const EdgeInsets.only(
                            top: 170), // Add padding for top alignment
                        child: const Row(
                          children: [
                            SizedBox(
                                height: 80), // For some space from the left
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Layout adjusted for landscape
                                  Text("Landscape Mode upadte Soon"),
                                  // Add any widgets you want in landscape mode here
                                  // For example:
                                  SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              );
            }),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VpnUrlScreen(), // Destination screen
            ),
          );
        },
        foregroundColor: AppColors.createMaterialColor(AppColors.text),
        backgroundColor: AppColors.createMaterialColor(AppColors.primary),
        shape: const CircleBorder(
          side: BorderSide(
            color: AppColors.primary, // Border color
            width: 2, // Border width
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSelectedLocationDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color.fromARGB(255, 226, 224, 224),
              width: 1, // Thickness of the border
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              // String as value
              value: selectedIndex, // Here we use String (VpnData.id)
              hint: Text(
                vpnData.isNotEmpty ? "Choose a VPN" : "No records",
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w700),
              ),
              dropdownColor: Colors.white,
              icon: const Icon(Icons.more_vert, color: Colors.black),
              isExpanded: true,

              items: vpnData.map((VpnData data) {
                return DropdownMenuItem<String>(
                  value: data.id, // Set the value to VpnData.id
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data.userProfile,
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              if (data.id == connectingIndex) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Please disconnect the VPN first, then Edit."),
                                  ),
                                );
                              } else {
                                editVpnProfile(context, data.id);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              if (data.id == connectingIndex &&
                                  _vpnService.getConnectingStatus() == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Please disconnect the VPN first, then delete."),
                                  ),
                                );
                              } else {
                                deleteVpnProfile(context, data.id);
                              }
                              if (data.id != selectedIndex) {
                                Navigator.pop(
                                    context); // Only pop after the state is updated
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newId) {
                if (newId != selectedIndex) {
                  setState(() {
                    isDropdownOpen =
                        newId != null; // Update dropdown open state
                    selectedIndex = newId; // Update selected ID
                    if (_vpnService.getConnectingStatus() == true &&
                        newId != null) {
                      alreadyConnected(
                          context,
                          vpnData.firstWhere((data) => data.id == newId),
                          newId);
                    }
                  });
                }
              },
              onTap: () {
                // Set the state when dropdown is opened
                setState(() {
                  isDropdownOpen = true;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  void editVpnProfile(BuildContext context, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(id: id),
      ),
    );
  }

  Future<void> _deleteVpnData(BuildContext context, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final vpnIndex = vpnData.indexWhere((data) => data.id == id);
    if (vpnIndex != -1) {
      // Remove the VPN from the list using the index
      setState(() {
        vpnData.removeAt(vpnIndex);
        // If the deleted item was selected, reset the selectedIndex
        if (selectedIndex == id) {
          // If there's another item in the list, select it, otherwise set selectedIndex to null
          if (vpnData.isNotEmpty) {
            selectedIndex = vpnData.first.id;
          } else {
            selectedIndex = null;
          }
        }

        isDropdownOpen = false;
      });
      prefs.remove(id);
      // Save the updated vpnData list to SharedPreferences
      await prefs.setString(
          'vpnData', jsonEncode(vpnData.map((e) => e.toJson()).toList()));

      // Optionally disconnect VPN if the deleted item was the one connected
      if (id == connectingIndex) {
        _disconnectVpn();
      }
      // If the selected item was deleted, navigate to the dashboard
      if (selectedIndex == null) {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const Vpndashboard()),
        );
      } else {
        // If the item was not selected, reload the VPN data
        _loadVpnData();
      }
    } else {
      // Handle the case when the VPN ID isn't found in the list
      debugPrint('VPN with id $id not found');
    }
  }

  void deleteVpnProfile(BuildContext context, String id) {
    // Find the VPN data by id
    var vpnProfile = _vpnService.getVpnDataByIndex(id.toString());

    // Show a confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete VPN"),
        content: Text(vpnProfile != null
            ? "Are you sure you want to delete?"
            : "VPN profile not found."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _deleteVpnData(context, id);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget ipTextFieldWidget(stageResult) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: FutureBuilder<VpnData?>(
        future: _vpnService.getVpnDataByIndex(
            connectingIndex ?? ''), // Call the async method here for IP
        builder: (context, snapshot) {
         
          return Column(
            children: [
              if (_vpnService.getConnectingStatus() == true &&
                  stageResult != 'connected')
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Connecting...',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              else if (snapshot.hasError)
                Text(ipAddress ?? 'Fetching IP...',
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w900))
              else if (snapshot.hasData)
                Text(
                  _vpnService.getConnectingStatus() == true
                      ? (snapshot.data!.serverName)
                      : (ipAddress ?? 'Not found'),
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w900),
                )
              else
                const Text("No data found")
            ],
          );
        },
      ),
    );
  }
}
