// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:openvpn_app/Screens/common_app_bar.dart';
import 'package:openvpn_app/Screens/common_app_bar_with_drawer.dart';
import '/controller/theme_controller.dart';
import 'vpn_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:get/get.dart';

class LoginPage extends StatefulWidget {
  final Map<String, dynamic>? fileDetails; // For adding a new VPN
  final String? id; // For editing an existing VPN

  const LoginPage({super.key, this.fileDetails, this.id});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controllers for username and password fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _profileNameController = TextEditingController();
  bool _obscureText = true;
  String? _editId; // Store the ID if we are editing an existing VPN
  final themeController = Get.find<ThemeController>();
  @override
  void initState() {
    super.initState();

    if (widget.id != null) {
      // If id is passed, it means we're editing an existing VPN
      _editId = widget.id;
      _loadVpnData(); // Load the existing data by id
    } else if (widget.fileDetails != null) {
      // If fileDetails is passed, it means we're adding a new VPN
      // You can extract the data from widget.fileDetails and prefill fields if needed
    }
  }

  @override
  void dispose() {
    // Dispose the controllers to prevent memory leaks
    _usernameController.dispose();
    _passwordController.dispose();
    _profileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign the GlobalKey to the Scaffold
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset:
          false, // Prevent resizing when keyboard is visible
      appBar: CommonAppBar(scaffoldKey: _scaffoldKey),
      drawer: const CommonDrawer(),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(themeController.innerImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .dropdownColorBackground, // Background color
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12), // Padding inside the box
                  child: TextField(
                    controller: _profileNameController,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .themeTextColor, // Text color
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Profile Name',
                      hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .themeTextColor, // Hint text color
                      ),
                      border: InputBorder.none, // Remove default border
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .themeTextColor, // Focused border color
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .dropdownColorBackground, // Background color
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12), // Padding inside the box
                  child: TextField(
                    controller: _usernameController,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .themeTextColor, // Text color
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Username',
                      hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .themeTextColor, // Hint text color
                      ),
                      border: InputBorder.none, // Remove default border
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .themeTextColor, // Focused border color
                        ),
                      ),
                    ),
                  ),
                ),
                // Username field

                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .dropdownColorBackground, // Background color
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12), // Padding inside the box
                  child: Stack(
                    alignment:
                        Alignment.center, // Ensures content stays centered
                    children: [
                      TextField(
                        controller: _passwordController,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .themeTextColor, // Text color
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .themeTextColor, // Hint text color
                          ),
                          border: InputBorder.none, // Remove default border
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .themeTextColor, // Focused border color
                            ),
                          ),
                          contentPadding: const EdgeInsets.only(
                              right: 0), // Add padding to the right
                        ),
                        obscureText: _obscureText, // Obscure text for password
                      ),
                      Positioned(
                        right: 0, // Position the icon to the right
                        child: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Theme.of(context)
                                .colorScheme
                                .themeTextColor, // Icon color
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText =
                                  !_obscureText; // Toggle obscureText
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: 250,
                  height: 50, // Set the desired width here
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.buttonBackgroundColor,
                      foregroundColor:
                          Theme.of(context).colorScheme.buttonTextColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10), // Rounded corners
                      ),
                    ),
                    onPressed: () async {
                      String username = _usernameController.text.trim();
                      String password = _passwordController.text.trim();
                      String profileName = _profileNameController.text.trim();

                      if (username.isEmpty ||
                          password.isEmpty ||
                          profileName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All fields are required'),
                          ),
                        );
                        return;
                      }

                      try {
                        // Show a loading indicator
                        if (_editId == null) {
                          // Store the file path
                          await _storeFilePath(widget.fileDetails);
                        } else {
                          await updateData(
                              _editId!, username, password, profileName);
                        }

                        // Navigate to the VPN page
                      } catch (e) {
                        // Handle any errors
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      } finally {
                        // Dismiss the loading indicator
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Vpndashboard(),
                          ),
                        );
                      }
                    },
                    child: Text(_editId == null ? 'Store' : 'Update',
                        style: const TextStyle(fontSize: 20)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Load VPN data for editing
  Future<void> _loadVpnData() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString('vpnData');
    if (storedData != null) {
      List<dynamic> decodedList = jsonDecode(storedData);
      for (var vpn in decodedList) {
        if (vpn['id'] == _editId) {
          _usernameController.text = vpn['username'];
          _passwordController.text = vpn['password'];
          _profileNameController.text = vpn['userProfile'];
          break;
        }
      }
    }
  }

  // Store or update the file path in SharedPreferences
  Future<void> _storeFilePath(fileDetails) async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String userProfile = _profileNameController.text.trim();

    // If _editId is null, we are adding a new VPN configuration
    await saveData(username, password, userProfile, fileDetails);
  }

  // Save new VPN configuration data
  Future<void> saveData(String username, String password, String userProfile,
      vpnConfigPath) async {
    final prefs = await SharedPreferences.getInstance();
    // Retrieve existing data, if any
    String? storedData = prefs.getString('vpnData');
    List<dynamic> decodedList = [];
    // If there is already data stored, decode it and append new data
    if (storedData != null) {
      // Decode the stored JSON and ensure all values are Strings
      decodedList = jsonDecode(storedData);
    }
    String randomId = _generateRandomString(10);
    // If no existing data, create a new list
    decodedList.add({
      'id': randomId,
      'username': username,
      'password': password,
      'userProfile': userProfile,
      'vpnConfigPath': vpnConfigPath['content'],
      'serverName': vpnConfigPath['server'] ?? 'Unknown',
      'profileName': vpnConfigPath['profile'] ?? 'Unknown',
    });
    // Save updated list back to SharedPreferences
    await prefs.setString('vpnData', jsonEncode(decodedList));
  }

  // Update existing VPN configuration data by ID
  Future<void> updateData(
    String id,
    String username,
    String password,
    String userProfile,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString('vpnData');
    if (storedData != null) {
      List<dynamic> decodedList = jsonDecode(storedData);
      for (var i = 0; i < decodedList.length; i++) {
        if (decodedList[i]['id'] == id) {
          decodedList[i] = {
            'id': id,
            'username': username,
            'password': password,
            'userProfile': userProfile,
            'vpnConfigPath': decodedList[i]["vpnConfigPath"],
            'serverName': decodedList[i]["serverName"],
            'profileName': decodedList[i]["profileName"],
          };
          break;
        }
      }
      await prefs.setString('vpnData', jsonEncode(decodedList));
    }
  }

  // Helper function to generate a random string
  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}
