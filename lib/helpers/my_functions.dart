import 'package:flutter/material.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:windows_notification/windows_notification.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path_provider/path_provider.dart';

class MyFunctions {
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
            )),
        duration: const Duration(seconds: 5),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  static void showAlertDialog(
      BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Create a function to update the settings file
  static Future<bool> updateSettingsFile() async {
    // load settings data from the settings file
    final File file = File(settingsData['appSettingsFile']);
    // check if file exists
    if (!file.existsSync()) {
      return false;
    } else {
      // update the settings file
      file.writeAsStringSync(jsonEncode(settingsData));
    }
    return true;
  }

  // Create a function that formats the scalereading data:
  static String formatScaleReading(String data) {
    try {
      String extractedNumber = data.substring(settingsData['preText'],
          data.length - int.parse(settingsData['postText'].toString()));
      double weight = double.parse(extractedNumber);
      return weight.toStringAsFixed(settingsData['scaleWeightDecimals']);
    } catch (e) {
      //print(e.toString());
      return data;
    }
  }

  static bool isNumber(String value) {
    if (value.isEmpty) {
      return false;
    }

    // Try parsing the string as an integer
    final intValue = int.tryParse(value);
    if (intValue != null) {
      return true;
    }

    // Try parsing the string as a double
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) {
      return true;
    }

    return false;
  }

  // Create a function that converts a string to Uint8List
  static Uint8List stringToUint8List(String data) {
    List<int> list = data.codeUnits;
    return Uint8List.fromList(list);
  }

  // create a function that compares two numbers and returns the bigger one using max lib
  static String getMaxi(
      dynamic num1, dynamic num2, String time1, String time2) {
    // when num2 is not a numeral, alwyas assume num1 is the smaller number
    try {
      if (num1 is! double || num2 is! double) return '-';
      var result = max(num1, num2);
      if (result == num2) {
        return '$num2 ${settingsData['scaleWeightUnit']} | $time2 | Operator: Cardinal';
      } else {
        return '$num1 ${settingsData["scaleWeightUnit"]} | $time1 | Operator: Cardinal';
      }
    } catch (e) {
      return '-';
    }
  }

  static int countItemsToBeApproved(List<Map<String, dynamic>> items) {
    int counter = items
        .where((item) {
          return (item['waybillRecord']['currentSecondaryApprover'] ==
              currentUser['userId']);
        })
        .toList()
        .length;

    return counter;
  }

  static bool itemNeedsApproval(Map<String, dynamic>? item) {
    if (item != null &&
        item['waybillRecord'] != null &&
        item['waybillRecord']['currentSecondaryApprover'] ==
            currentUser['userId'] &&
        item['approvalStatus'] != 'declined') {
      return true;
    }
    return false;
  }

  // create a function that compares two numbers and returns the smaller one using min lib
  static String getMini(
      dynamic num1, dynamic num2, String time1, String time2) {
    // when num2 is not a numeral, alwyas assume num1 is the smaller number
    try {
      if (num1 is! double || num2 is! double) {
        if (num1 is double || num1 is int) {
          return '$num1 ${settingsData["scaleWeightUnit"]} | $time1 | Operator: Cardinal';
        }
        return '-';
      }
      var result = min(num1, num2);
      if (result == num1) {
        return '$num1 ${settingsData["scaleWeightUnit"]} | $time1 | Operator: Cardinal';
      } else {
        return '$num2 ${settingsData["scaleWeightUnit"]} | $time2 | Operator: Cardinal';
      }
    } catch (e) {
      return 'e';
    }
  }

  // Create a function that subtracts two numbers and formats the result into a string of 2 decimal places
  static String subtractAndFormat(dynamic num1, dynamic num2) {
    try {
      if (num1 is! double || num2 is! double) return "-";
      // Ensure num1 is the bigger number and num2 is the smaller number
      double result = (num1 > num2) ? num1 - num2 : num2 - num1;
      // Format the result to 2 decimal places
      return result.toStringAsFixed(2);
    } catch (e) {
      // Return "-" if something goes wrong
      return "-";
    }
  }

  // Generate random order number from the current date and time
  static String generateOrderNumber() {
    DateTime now = DateTime.now();

    // Format: YYYYMMDDHHMMSS (Year, Month, Day, Hour, Minute, Second)
    String orderNumber = "${now.year}"
        "${now.month.toString().padLeft(2, '0')}"
        "${now.day.toString().padLeft(2, '0')}"
        "${now.hour.toString().padLeft(2, '0')}"
        "${now.minute.toString().padLeft(2, '0')}"
        "${now.second.toString().padLeft(2, '0')}";

    return orderNumber;
  }
}

String formatDateTime(String datetimeStr) {
  // Parse the datetime string into a DateTime object
  DateTime inputDateTime = DateTime.parse(datetimeStr);
  DateTime now = DateTime.now();

  Duration difference = now.difference(inputDateTime);

  // Helper function to format the date
  String formatDate(DateTime date) {
    return DateFormat('d MMMM, yyyy').format(date);
  }

  if (difference.inSeconds < 1) {
    return 'Just now';
  } else if (difference.inSeconds < 60) {
    return '${difference.inSeconds} seconds ago';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else if (difference.inDays < 30) {
    int weeks = (difference.inDays / 7).floor();
    return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
  } else if (difference.inDays < 365) {
    int months = (difference.inDays / 30).floor();
    return '$months ${months == 1 ? 'month' : 'months'} ago';
  } else {
    return formatDate(inputDateTime);
  }
}

bool isNotificationShown = false;
String currentPage = ''; // page tracking variable
String lastNotificationMessage =
    ''; // last notification message tracking variable
final notificationPlugin = WindowsNotification(applicationId: "PIKANTO");

Future<void> showLocalNotification(String body) async {
  if (isNotificationShown || body == lastNotificationMessage) return;
  //if (isNotificationShown || body == "fkgjg") return;

  isNotificationShown = true;
  lastNotificationMessage = body;

  String assetPath = "pikanto/logos/logo.jpeg";

  final directory = await getApplicationDocumentsDirectory();
  assetPath = '${directory.path}/$assetPath';

  final notification = NotificationMessage.fromPluginTemplate(
    "unique_id", // Unique ID for this notification
    "", // Title of the notification
    body, // Body text of the notification
    //largeImage: assetPath, // Path to the large image
    image: assetPath, // Path to image
  );

  await notificationPlugin.showNotificationPluginTemplate(notification);
  isNotificationShown = false;

  /// Listen for notification click
  const platform = MethodChannel('com.example.notification/click');
  platform.setMethodCallHandler((call) async {
    if (call.method == 'notificationClicked') {
      // Restore the window
      await windowManager.show();
      await windowManager.focus();
    }
    return;
  });
}

Future<bool> showDeleteConfirmation(
    BuildContext context, String warningMessage) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Confirm Deletion'),
            content:
                Text(warningMessage, style: TextStyle(color: Colors.grey[800])),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Delete'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<bool> showRestoreConfirmation(
    BuildContext context, String warningMessage) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Confirm Restoration'),
            content:
                Text(warningMessage, style: TextStyle(color: Colors.grey[800])),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Restore'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<String?> getAssetImagePath(String imageName) async {
  if (imageName.isEmpty) {
    return null;
  }
  final String logoPath = 'assets/logo/$imageName';

  try {
    await rootBundle.load(logoPath);
    return logoPath; //image exists
  } catch (e) {
    return null; // image does not exists
  }
}

Future<void> copyLogoToAppDirectory() async {
  // check if the logo exists in the app directory
  String logoName = 'logo.jpeg';
  final String? logoPath = await getAssetImagePath(logoName);

  //copy logo image to app directory
  if (logoPath != null) {
    try {
      final byteData = await rootBundle.load(logoPath);
      final String targetDirectory =
          '${settingsData["appLogoDirectory"]}/$logoName';
      final File newLogoFile = File(targetDirectory);

      // write the bytedata into the new logo file
      await newLogoFile.writeAsBytes(byteData.buffer.asUint8List());
    } catch (e) {
      // do nothing here
    }
  }
}
