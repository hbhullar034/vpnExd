import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
     final _storage = GetStorage();
  var isDarkMode = false.obs;
  @override
  void onInit() {
    super.onInit();
    // Load saved theme preference
    isDarkMode.value = _storage.read('isDarkMode') ?? false;
    Get.changeTheme(isDarkMode.value ? darkTheme : lightTheme);
  }
  // Define light theme
  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
      ).copyWith(
        secondary: Colors.green, // Use this as the secondary color
      ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      );

  // Define dark theme
  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
         textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      );
 // Get the image path for green based on the theme
  String get greenImage {
    return isDarkMode.value
        ? 'assets/images/greenDark.jpg'
        : 'assets/images/green.jpg';
  }

  // Get the image path for blue based on the theme
  String get blueImage {
    return isDarkMode.value
        ? 'assets/images/blueDark.jpg'
        : 'assets/images/blue.jpg';
  }

  // Get the image path for red based on the theme
  String get redImage {
    return isDarkMode.value
        ? 'assets/images/redDark.jpg'
        : 'assets/images/red.jpg';
  }
   // Get the image path for red based on the theme
  String get innerImage {
    return isDarkMode.value
        ? 'assets/images/inner-bg-dark.jpg'
        : 'assets/images/inner-bg.png';
  }
  // Toggle theme and notify GetX
 void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeTheme(isDarkMode.value ? darkTheme : lightTheme);
    _storage.write('isDarkMode', isDarkMode.value); // Save preference
  }
}
extension CustomColorScheme on ColorScheme {
  // Get access to ThemeController dynamically inside the getter
  Color get connectingColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.white : Colors.white;
  }
   Color get themeTextColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.white : Colors.black;
  }

  Color get dropdownColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.white : Colors.black;
  }
  Color get dropdownColorBackground {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? const Color.fromARGB(0, 51, 47, 47) : Colors.white;
  }
  Color get dropdownListBackground {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.black87 : Colors.white;
  }
   Color get ipAddressColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.white : Colors.black;
  }
   Color get ipAddressNameColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.white : Colors.grey;
  }
   Color get circleBackgroundGreenColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? const Color(0xFF213639).withOpacity(0.8) : Colors.white;
  }
  Color get circleBackgroundBlueColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? const Color(0xFF0F3065).withOpacity(0.8) : Colors.white;
  }
  Color get circleBackgroundRedColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? const Color(0xFF30254D).withOpacity(0.8) : Colors.white;
  }
  Color get byteColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.white70 : Colors.blue;
  }
  Color get byteLabelColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.white70 : Colors.black;
  }
  Color get byteWidgetBackground {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.transparent : Colors.white;
  }
  Color get byteWidgetBackgroundBorder {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.white70 : Colors.white;
  }
  //graph color barColorIsFuture
  Color get barColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? const  Color(0xFF0FB52F) : const  Color(0xFF0FB52F);
  }
  Color get barColorIsFuture {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.green: Colors.green;
  }
  Color get blankColorIsFuture {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Color(0xFFB8DCFF) : const Color(0xFFB8DCFF);
  }
  Color get blankColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? const Color(0xFFA00606) : const Color(0xFFA00606);
  }
  Color get tooltipColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? const Color(0xFFA00606) :const Color(0xFFA00606);
  }
  Color get graphHeading {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.white : Colors.black;
  }
  Color get graphBackground {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.transparent :Colors.white;
  }
  Color get graphBorderColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? const Color.fromARGB(255, 226, 224, 224) :const Color.fromARGB(255, 226, 224, 224);
  }
  Color get graphBottomTile {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.white :Colors.black;
  }

  //button
   Color get buttonBackgroundColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.blue : Colors.blue;
  }
  Color get buttonTextColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.white : Colors.white;
  }

  //icon 

    Color get fileIconColor {
    final themeController = Get.find<ThemeController>(); // Access ThemeController here
    return themeController.isDarkMode.value ? Colors.white : Colors.white;
  }

  //network page

}