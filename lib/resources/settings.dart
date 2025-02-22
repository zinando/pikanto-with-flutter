import 'package:flutter/material.dart';
import 'package:pikanto/widgets/loading_screen.dart';
import 'package:pikanto/widgets/theme_data.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

//import 'package:loading_animation_widget/loading_animation_widget.dart';

Map<String, dynamic> settingsData = {
  "appTitle": "Pikanto",
  "appLogo": 'assets/logo/logo.jpeg',
  "appLogoAlt": 'assets/logo/logo.png',
  "primaryColor": 6,
  "colorScheme": 6,
  "appTheme": 0,
  "scaffoldBackgroundColor": 0,
  "textTheme": 0,
  "appBarTheme": 0,
  "loadingScreenDelay": 15,
  "loadingScreenWidget": 0,
  "serverUrl": null,
  "apiEndpoints": apiEndpoints,
  "appDirectory": null,
  "appImageDirectory": null,
  "appDocumentDirectory": null,
  "appLogoDirectory": null,
  "appSettingsFile": null,
  "ticketHeaderImage": null,
  "waybillHeaderImage": null,
  "scalePort": "COM5",
  "scaleBaudRate": 9600,
  "scaleDataBits": 8,
  "scaleStopBits": 1.0,
  "scaleParity": "none",
  "scaleTimeout": 1000,
  "scaleWeightUnit": "kg",
  "scaleWeightDecimals": 2,
  "scaleWeightMin": 0.0,
  "scaleReading": "0.0",
  "emailTriggerUrl": null,
  "companyId": 1,
  "preText": 0,
  "postText": 0,
  "mailchimpApiKey": null,
  "mailchimpApiUser": null,
  "mailchimpapiEmailSender": null,
  "pikantoEmailSender": null,
  "pikantoEmailToken": null,
  "currentAppVersion": "1.0.0",
  "updateFileUrl":
      "https://raw.githubusercontent.com/zinando/pikanto-with-flutter/master/windows-release/update.json",
};

Map<String, String> apiEndpoints = {
  "loginUser": "/user/login-user",
  "registerUser": "/user/register-user",
  "getUsers": "/user/get-users",
  "getUser": "/user/get-user",
  "updateUser": "/user/update-user",
  "deleteUser": "/user/delete-user",
  "getWaybills": "/waybill/get-waybills",
  "getWaybill": "/waybill/get-waybill",
  "createWaybill": "/waybill/create-waybill",
  "updateWaybill": "/waybill/update-waybill",
  "deleteWaybill": "/waybill/delete-waybill",
  "getWaybillItems": "/waybill/get-waybill-items",
  "getWaybillItem": "/waybill/get-waybill-item",
  "createWaybillItem": "/waybill/create-waybill-item",
  "updateWaybillItem": "/waybill/update-waybill-item",
  "deleteWaybillItem": "/waybill/delete-waybill-item",
  "getWaybillItemStatuses": "/waybill/get-waybill-item-statuses",
  "getWaybillItemStatus": "/waybill/get-waybill-item-status",
  "createWaybillItemStatus": "/waybill/create-waybill-item-status",
  "updateWaybillItemStatus": "/waybill/update-waybill-item-status",
  "deleteWaybillItemStatus": "/waybill/delete-waybill-item-status",
  "getWaybillItemStatusHistories": "/waybill/get-waybill-item-status-histories",
  "getWaybillItemStatusHistory": "/waybill/get-waybill-item-status-history",
  "createWaybillItemStatusHistory":
      "/waybill/create-waybill-item-status-history",
  "updateWaybillItemStatusHistory":
      "/waybill/update-waybill-item-status-history",
  "deleteWaybillItemStatusHistory":
      "/waybill/delete-waybill-item-status-history",
  "getWaybillItemStatusHistoryTypes":
      "/waybill/get-waybill-item-status-history-types",
  "getWaybillItemStatusHistoryType":
      "/waybill/get-waybill-item-status-history-type",
  "createWaybillItemStatusHistoryType":
      "/waybill/create-waybill-item-status-history-type",
  "updateWaybillItemStatusHistoryType":
      "/waybill/update-waybill-item-status-history-type",
  "deleteWaybillItemStatusHistoryType":
      "/waybill/delete-waybill-item-status-history-type",
  "getWaybillItemStatusHistoryReasons":
      "/waybill/get-waybill-item-status-history-reasons",
};

// Create a list for each object values in the settingData, use their index in the settings data
List<MaterialColor> primaryColors = [
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.brown,
  Colors.grey,
  Colors.blueGrey,
];

// List of colorschemes
List<ColorScheme> colorSchemes = [
  ColorScheme.fromSwatch(primarySwatch: Colors.red),
  ColorScheme.fromSwatch(primarySwatch: Colors.pink),
  ColorScheme.fromSwatch(primarySwatch: Colors.purple),
  ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple),
  ColorScheme.fromSwatch(primarySwatch: Colors.indigo),
  ColorScheme.fromSwatch(primarySwatch: Colors.blue),
  ColorScheme.fromSwatch(primarySwatch: Colors.lightBlue),
  ColorScheme.fromSwatch(primarySwatch: Colors.cyan),
  ColorScheme.fromSwatch(primarySwatch: Colors.teal),
  ColorScheme.fromSwatch(primarySwatch: Colors.green),
  ColorScheme.fromSwatch(primarySwatch: Colors.lightGreen),
  ColorScheme.fromSwatch(primarySwatch: Colors.lime),
  ColorScheme.fromSwatch(primarySwatch: Colors.yellow),
  ColorScheme.fromSwatch(primarySwatch: Colors.amber),
  ColorScheme.fromSwatch(primarySwatch: Colors.orange),
  ColorScheme.fromSwatch(primarySwatch: Colors.deepOrange),
  ColorScheme.fromSwatch(primarySwatch: Colors.brown),
  ColorScheme.fromSwatch(primarySwatch: Colors.grey),
  ColorScheme.fromSwatch(primarySwatch: Colors.blueGrey),
];

// List of text themes
List<TextTheme> textThemes = [
  const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black87),
  ),
  const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
  ),
  const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
  ),
];

// List of app bar themes
List<AppBarTheme> appBarThemes = [
  const AppBarTheme(
    color: Colors.lightBlue,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  const AppBarTheme(
    color: Colors.blue,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  const AppBarTheme(
    color: Colors.red,
    iconTheme: IconThemeData(color: Colors.white),
  ),
];

// List of loading screen widgets
List<Widget> loadingScreenWidgets = [
  const ScreenAnimator(),
  const CircularProgressIndicator(),
  const LoadingAnimator(),
  const LinearLoader(),
  const BottomLoader(),
];

// List of notifiction items
List<Map<String, dynamic>> notificationsList = [];

// Create and empty map for currentUser data
Map<String, dynamic> currentUser = {};

// Create a list of product items
List<Map<String, dynamic>> productItems = [];

// create an empty list of product map
List<Map<String, dynamic>> products = [];

// create an empty list of customers map
List<Map<String, dynamic>> customers = [];

// Create a list of hauliers map
List<Map<String, dynamic>> hauliers = [];

// Create a list of weight records
List<Map<String, dynamic>> weightRecords = [];

// create a global websocket manager
class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  late WebSocketChannel channel;

  factory WebSocketManager() {
    return _instance;
  }

  WebSocketManager._internal() {
    // Open the WebSocket connection
    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8088/websocket'),
    );
  }

  Stream get stream => channel.stream;

  void close() {
    channel.sink.close();
  }
}

// Create a list of active listeners
Map<String, bool> listeners = {};

// create methods for storing and retrieving data from shared preferences
Future<void> storeLocalData(String key, dynamic value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (value is String) {
    await prefs.setString(key, value);
  } else if (value is int) {
    await prefs.setInt(key, value);
  } else if (value is double) {
    await prefs.setDouble(key, value);
  } else if (value is bool) {
    await prefs.setBool(key, value);
  } else if (value is List<String>) {
    await prefs.setStringList(key, value);
  } else {
    await prefs.setString(key, value.toString());
  }
}

dynamic getLocalData(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.get(key);
}

// create a value notifier for the last recorde weight
final ValueNotifier<String> lastRecordedWeightNotifier = ValueNotifier('');

// create a value notifier for notification items
// final ValueNotifier<String> notificationItemStatusNotifier =
//     ValueNotifier('unread');

// create appThemeNotifier
final ValueNotifier<int> appThemeNotifier = ValueNotifier(0);

// Create a global socket manager
class SocketManager {
  late IO.Socket socket;
  final ValueNotifier<List<Map<String, dynamic>>> notificationListNotifier =
      ValueNotifier([]); // Notifier for notifications
  final ValueNotifier<List<Map<String, dynamic>>> weightRecordListNotifier =
      ValueNotifier([]); // Notifier for weight records
  //bool _isListenerAdded = false; // To track if the listener is already added

  // Singleton pattern to make the SocketManager accessible globally
  static final SocketManager _instance = SocketManager._internal();

  factory SocketManager() {
    return _instance;
  }

  SocketManager._internal() {
    // Initialize the Socket.IO connection
    socket = IO.io(
      '${settingsData["serverUrl"]}', // Replace with your backend server address
      IO.OptionBuilder()
          .setTransports(['websocket']) // Use WebSocket transport
          .setQuery({'user_id': currentUser['userId']})
          .enableAutoConnect() // Automatically connect
          .build(),
    );

    // Optional: Add basic listeners for connect, disconnect, etc.
    socket.onConnect((message) {
      listeners['connect'] = true;
      if (currentUser["userId"] != null) {
        sendMessage('join_room', jsonEncode({'userId': currentUser["userId"]}));
      }
    });

    // send app settings to the server
    var appSettings = {
      'companyId': settingsData['companyId'],
      'settings': {'email_trigger_url': settingsData['emailTriggerUrl']}
    };
    socket.emit('save_app_settings', jsonEncode(appSettings));

    // Listen for incoming notifications
    listenToNotifications();

    // Listen for incoming weight records
    listenToWeightRecords();

    socket.onDisconnect((_) {
      listeners['connect'] = false;
    });

    socket.onError((error) {
      //print('Socket error: $error');
    });
  }

  void addListenerIfNeeded(String object, Function() callback) {
    if (object == 'notifications') {
      notificationListNotifier.addListener(callback);
    } else if (object == 'weight_records') {
      weightRecordListNotifier.addListener(callback);
    }
  }

  void listenToNotifications() {
    var _event =
        'notification_response_${currentUser["userId"]}'; // Use the current user's ID as the event name
    listen(_event, (data) {
      final List<Map<String, dynamic>> response =
          List<Map<String, dynamic>>.from(jsonDecode(data));

      notificationListNotifier.value = response;

      notificationListNotifier.notifyListeners();
    });
  }

  // listen to weight records
  void listenToWeightRecords() {
    var _event = 'weight_record_response';
    listen(_event, (data) {
      final List<Map<String, dynamic>> response =
          List<Map<String, dynamic>>.from(jsonDecode(data));

      weightRecordListNotifier.value = response;
      WeightRecordsProvider().setWeightRecord(response);
      weightRecordListNotifier.notifyListeners();
    });
  }

  // Method to emit an event
  void sendMessage(String event, dynamic data) {
    try {
      socket.emit(event, data);
    } catch (e) {
      //print('Error sending message: $e');
    }
  }

  // Method to listen for incoming messages
  void listen(String event, Function(dynamic) callback) {
    if (!listeners.containsKey(event) || listeners[event] == false) {
      // Add the listener only if it's not already active
      socket.on(event, callback);
      listeners[event] = true; // Mark the event as actively listened to
    } else {}
  }

  // Method to stop listening to an event
  void stopListening(String event) {
    if (listeners.containsKey(event) && listeners[event] == true) {
      socket.off(event);
      listeners[event] = false; // Mark the event as not being listened to
    } else {}
  }

  // Method to close the socket connection
  void close() {
    socket.disconnect();
    listeners.clear(); // clear all active listeners
  }
}

// Create a list of users
List<Map<String, dynamic>> users = [];

// List of themeData
List<ThemeData> themeData = [
  brickRedTheme,
  lightBlueTheme,
  lemonGreenTheme,
];

// List of Scaffold background colors
List<Color> scaffoldBackgroundColors = [
  Colors.white,
  Colors.black,
  Colors.grey,
];

class WeightRecordsProvider extends ChangeNotifier {
  static final WeightRecordsProvider _instance =
      WeightRecordsProvider._internal();
  factory WeightRecordsProvider() {
    return _instance;
  }

  WeightRecordsProvider._internal();

  List<Map<String, dynamic>> _weightRecordsList = [];

  List<Map<String, dynamic>> get weightRecordsList => _weightRecordsList;

  void addWeightRecord(Map<String, dynamic> weight) {
    _weightRecordsList.add(weight);
    notifyListeners();
  }

  void setWeightRecord(List<Map<String, dynamic>> newList) {
    _weightRecordsList = newList;
    notifyListeners();
  }
}
