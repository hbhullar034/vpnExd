import 'package:flutter/material.dart';

class ConfirmationDialog {
  // Common confirmation dialog method
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String content,
    String cancelButtonText = "Cancel",
    String confirmButtonText = "OK",
    Color confirmButtonColor = Colors.blue,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Prevent dialog dismissal by tapping outside
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false); // User cancels
                  },
                  child: Text(cancelButtonText),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true); // User confirms
                  },
                  child: Text(
                    confirmButtonText,
                    style: TextStyle(color: confirmButtonColor),
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed
  }
}
class AlertBox {
  // Simple alert dialog method
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    String buttonText = "OK",
    Color buttonColor = Colors.blue,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dialog dismissal by tapping outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: Text(
                buttonText,
                style: TextStyle(color: buttonColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
