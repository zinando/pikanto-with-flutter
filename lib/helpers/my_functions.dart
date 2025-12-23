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
import 'package:flutter_libserialport/flutter_libserialport.dart';

Process? _serialServiceProcess;

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

Future<bool> serialServiceRunning() async {
  try {
    final result = await Process.run(
      'tasklist',
      [],
    );

    return result.stdout
        .toString()
        .toLowerCase()
        .contains('serial_service.exe');
  } catch (_) {
    return false;
  }
}

Future<void> startSerialService() async {
  if (await serialServiceRunning()) {
    return; // Already running
  }

  _serialServiceProcess = await Process.start(
    'serial_service.exe',
    [],
    runInShell: true,
    mode: ProcessStartMode.normal,
  );

  // Optional: give Flask time to bind port
  await Future.delayed(const Duration(milliseconds: 500));
}

void stopSerialService() {
  // await ensureAppIsClosed('serial_service.exe');
  try {
    _serialServiceProcess?.kill();
    _serialServiceProcess = null;
    // Preferred: kill tracked process
    // if (_serialServiceProcess != null) {
    //   // _serialServiceProcess!.kill(ProcessSignal.sigterm);
    //   _serialServiceProcess!.kill();
    //   _serialServiceProcess = null;
    //   return;
    // }

    // // Fallback: kill by name (safety net)
    // await Process.run(
    //   'taskkill',
    //   ['/F', '/IM', 'serial_service.exe'],
    // );
  } catch (_) {
    // Ignore shutdown errors
  }
}

Future<void> closeApp(String executableName) async {
  try {
    if (Platform.isWindows) {
      // Use taskkill to force close the app
      await Process.run('taskkill', ['/F', '/IM', executableName]);
    } else {
      // Use pkill for macOS/Linux
      await Process.run('pkill', [executableName]);
    }
  } catch (e) {
    print("Error closing app: $e");
  }
}

Future<bool> isProcessRunning(String executableName) async {
  var result = await Process.run('tasklist', []);
  return result.stdout.toString().contains(executableName);
}

Future<void> ensureAppIsClosed(String executableName) async {
  await closeApp(executableName);
  await Future.delayed(const Duration(seconds: 3)); // Wait briefly
  while (await isProcessRunning(executableName)) {
    await closeApp(executableName);
    await Future.delayed(const Duration(seconds: 2));
  }
}

String extractWeightFromBytesxxx(Uint8List data) {
  // Optionally: print raw chars for debugging
  // print('Raw bytes: $data');
  // print('Chars: ${data.map((b) => String.fromCharCode(b)).join()}');

  // Find the range you want to extract (e.g., last 5 digits before CR)
  // This part is based on your data pattern. For example:
  // Data sample: [41, 56, 32, 32, 32, 32, 52, 55, 48, 32, 32, 32, 32, 48, 48, 13]
  //
  // These represent:
  //   ' )', '8', '    ', '470', '    ', '00', CR

  // We'll extract characters between index 6 and 9
  // print('Data : ${data}'); // Debugging line
  List<int> relevantBytes = data.sublist(6, 9 + 1); // 52, 55, 48 = '470'

  String numericPart = String.fromCharCodes(relevantBytes).trim();

  // You can now format this (e.g., divide by 100)
  try {
    int raw = int.parse(numericPart);
    return (raw / 100).toStringAsFixed(2); // e.g., 4.70
  } catch (_) {
    return '0.0';
  }
}

String extractWeightFromBytes(Uint8List data) {
  // Check if data has enough bytes
  if (data.length < 10) {
    return '0.0'; // or throw an exception / log a warning
  }

  try {
    List<int> relevantBytes = data.sublist(6, 10); // 6 to 9 inclusive
    String numericPart = String.fromCharCodes(relevantBytes).trim();

    int raw = int.parse(numericPart);
    return (raw / 100).toStringAsFixed(2); // e.g., 4.70
  } catch (e) {
    return '0.0';
  }
}

int parseParity(dynamic parityValue) {
  String value = parityValue.toString().toLowerCase();
  switch (value) {
    case 'even':
      return SerialPortParity.even;
    case 'odd':
      return SerialPortParity.odd;
    case 'none':
      return SerialPortParity.none;
    case 'mark':
      return SerialPortParity.mark;
    case 'space':
      return SerialPortParity.space;
    default:
      return SerialPortParity.none;
  }
}
