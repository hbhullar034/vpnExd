import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:openvpn_app/Screens/common_app_bar.dart';
import 'package:openvpn_app/controller/theme_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:http/http.dart' as http;
import '../constants/colors.dart';
import 'login_page.dart'; // Replace with the correct import path for your LoginPage
import 'common_app_bar_with_drawer.dart'; // Replace with the correct import path for your drawer
import 'package:get/get.dart';

class VpnUrlScreen extends StatefulWidget {
  const VpnUrlScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _VpnUrlScreenState createState() => _VpnUrlScreenState();
}

class _VpnUrlScreenState extends State<VpnUrlScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  final TextEditingController urlController = TextEditingController();
  int _currentIndex = 0;
  final themeController = Get.find<ThemeController>();


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });

    });
   
  }

  @override
  void dispose() {
    _tabController.dispose();
    urlController.dispose();
    super.dispose();
  }

  // Function to handle URL submission with enhanced validation
  Future<void> _handleUrlSubmit() async {
    try {
      final url = Uri.parse(urlController.text);
      if (!url.isAbsolute || !['http', 'https'].contains(url.scheme)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid URL format')),
        );
        return;
      }

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final details = await parseOvpnFile(response.body);
        if (details['server'] == 'Not Found') {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid .ovpn file content')),
          );
          return;
        }
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(fileDetails: details),
          ),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load .ovpn file')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Unable to fetch URL')),
      );
    }
  }

  Future<Map<String, String>> parseOvpnFile(String fileContent) async {
    final result = <String, String>{};

    final serverMatch =
        RegExp(r'^\s*remote\s+([\w\.-]+)\s+\d+', multiLine: true)
            .firstMatch(fileContent);
    result['server'] = serverMatch?.group(1) ?? 'Not Found';

    final profileMatch = RegExp(r'^\s*#\s*Profile:\s*(.+)', multiLine: true)
        .firstMatch(fileContent);
    result['profile'] = profileMatch?.group(1) ?? 'Not Found';
    result['content'] = fileContent;
    return result;
  }

  // Function to handle file upload
  Future<void> _handleFileUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      if (result.files.single.size > 256 * 1024) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File exceeds 256 KB size limit')),
        );
        return;
      }

      String? filePath = result.files.single.path;
      if (filePath != null && filePath.endsWith('.ovpn')) {
        final details =
            await parseOvpnFile(await File(filePath).readAsString());
        if (details['server'] == 'Not Found') {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid .ovpn file content')),
          );
          return;
        }
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(fileDetails: details),
          ),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload only .ovpn file')));
      }
    } else {
      debugPrint('No file selected');
    }
  }

  Future<void> saveAssetToPublicDirectory(
      String assetPath, String fileName) async {
    try {
      PermissionStatus permission = await Permission.storage.request();
      if (!permission.isGranted) {
        debugPrint("Storage permission not granted");
        return;
      }

      final byteData = await rootBundle.load(assetPath);
      final directory = await path_provider.getDownloadsDirectory();
      if (directory == null) {
        debugPrint("Downloads directory not found");
        return;
      }

      final savePath = Directory('${directory.path}/store1');
      if (!(await savePath.exists())) {
        await savePath.create(recursive: true);
      }

      String filePath = '${savePath.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath = '${savePath.path}/$fileName-$timestamp';
      }

      final newFile = File(filePath);
      await newFile.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      debugPrint("File saved to: $filePath");
    } catch (e) {
      debugPrint("Error saving file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: CommonAppBar(scaffoldKey: _scaffoldKey),
      drawer: const CommonDrawer(),
      body: Container(
        decoration:  BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeController.innerImage),
            fit: BoxFit.cover,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Upload File Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open,
                      size: 80, color: AppColors.fileIconColor),
                  const SizedBox(height: 16),
                   Text(
                    '.OVPN',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.themeTextColor),
                  ),
                  const SizedBox(height: 16),
                   Text(
                    'Select all files related to a single profile.\nYou can import only one ".ovpn" profile at a time.\nThe maximum file size is 256 KB.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.themeTextColor),
                    
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 250,
                    height: 50, // Set the width you want for the button
                    child: ElevatedButton(
                      onPressed: _handleFileUpload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.buttonBackgroundColor,
                        foregroundColor:Theme.of(context).colorScheme.buttonTextColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              10), // No rounded corners (sharp edges)
                        ),
                      ),
                      child: const Text('Upload File',style: TextStyle(fontSize: 20)),
                    ),
                  )
                ],
              ),
            ),
            // URL Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                    'Type Server Address or Cloud ID',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.themeTextColor),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      hintText: 'test.openvpn.ovpn',
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 250,
                    height: 50, 
                    child: ElevatedButton(
                      onPressed: _handleUrlSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.buttonBackgroundColor,
                        foregroundColor:Theme.of(context).colorScheme.buttonTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              10), // No rounded corners (sharp edges)
                        ),
                      ),
                      child: const Text('Get URL',style: TextStyle(fontSize: 20)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
     bottomNavigationBar: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.createMaterialColor(AppColors.primary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCustomNavItem(
            icon: Icons.upload_file,
            label: 'Upload',
            isActive: _currentIndex == 0,
            onTap: () {
              setState(() {
                _currentIndex = 0;
                _tabController.animateTo(0);
              });
            },
          ),
          _buildCustomNavItem(
            icon: Icons.link,
            label: 'URL',
            isActive: _currentIndex == 1,
            onTap: () {
              setState(() {
                _currentIndex = 1;
                _tabController.animateTo(1);
              });
            },
          ),
        ],
      ),
    ),
    );
  }

  // Custom Navigation Item
Widget _buildCustomNavItem({
  required IconData icon,
  required String label,
  required bool isActive,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isActive)
              Container(
                width: 40,
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.createMaterialColor(AppColors.primary),
                  shape: BoxShape.rectangle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            Icon(
              icon,
              size: isActive ? 40 : 24,
              color: isActive
                  ? AppColors.createMaterialColor(AppColors.text)
                  : AppColors.createMaterialColor(AppColors.text).withOpacity(0.6),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isActive ? 14 : 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: AppColors.createMaterialColor(AppColors.text),
          ),
        ),
      ],
    ),
  );
}
}
