import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pikanto/helpers/my_functions.dart';
import 'widgets/loading_screen.dart';
import 'resources/settings.dart';
import 'screens/server_url_form.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() async {
  // runApp(const MyApp());
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => WeightRecordsProvider()),
  ], child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    _checkSettings();
    _checkForLogoImage();
    super.initState();
    // add appthemenotifier listener
    appThemeNotifier.addListener(_updateAppTheme);
  }

  Future<void> _checkSettings() async {
    // Implement your settings check and load logic here
    final Directory directory = await getApplicationDocumentsDirectory();
    // create the app directories if they don't exist
    final Directory appDirectory =
        Directory(path.join(directory.path, 'pikanto'));
    final Directory imageDirectory =
        Directory(path.join(appDirectory.path, 'images'));
    final Directory logoDirectory =
        Directory(path.join(appDirectory.path, 'logos'));
    final Directory docsDirectory =
        Directory(path.join(appDirectory.path, 'docs'));

    if (!appDirectory.existsSync()) {
      appDirectory.createSync();
      imageDirectory.createSync();
      logoDirectory.createSync();
      docsDirectory.createSync();

      // Save the app directory path to the settings data
      settingsData['appDirectory'] = appDirectory.path;
      settingsData['appImageDirectory'] = imageDirectory.path;
      settingsData['appLogoDirectory'] = logoDirectory.path;
      settingsData['appDocumentDirectory'] = docsDirectory.path;

      // create settings file and save the settings data in it
      final File file = File(path.join(appDirectory.path, 'settings.json'));
      settingsData['appSettingsFile'] =
          file.path; // save the settings file path in the settings data
      file.writeAsStringSync(jsonEncode(
          settingsData)); // save the settings data in the settings file
    }

    // load settings data from the settings file
    final File file = File(path.join(appDirectory.path, 'settings.json'));
    // check if file exists
    if (!file.existsSync()) {
      // Save the app directory path to the settings data
      settingsData['appDirectory'] = appDirectory.path;
      settingsData['appImageDirectory'] = imageDirectory.path;
      settingsData['appLogoDirectory'] = logoDirectory.path;
      settingsData['appDocumentDirectory'] = docsDirectory.path;
      settingsData['appSettingsFile'] = file.path;
      // create settings file and save the settings data in it
      file.writeAsStringSync(jsonEncode(settingsData));
    } else {
      // load settings data from the settings file
      final String data = await file.readAsString();
      // check if data has the same number of keys as the settings data
      if (jsonDecode(data) == settingsData) {
        settingsData = jsonDecode(data);
        setState(() {
          settingsData = jsonDecode(data);
        });
      } else {
        // update settings data with the data from the settings file
        settingsData.addAll(jsonDecode(data));
        // create settings file and save the settings data in it
        file.writeAsStringSync(jsonEncode(settingsData));
      }
    }
  }

  // function that checks if logo image is in the app directory
  Future<void> _checkForLogoImage() async {
    // check if logo image exists in app directory
    const String logoName = 'logo.jpeg';
    final String logoPath = '${settingsData["appLogoDirectory"]}/$logoName';
    final File imageFile = File(logoPath);
    if (!imageFile.existsSync()) {
      copyLogoToAppDirectory();
    }
  }

  // create a function that updates apptheme value from appthemenotifier
  void _updateAppTheme() {
    setState(() {
      settingsData['appTheme'] = appThemeNotifier.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: settingsData['appTitle'],
      theme: themeData[settingsData['appTheme']],
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<String> _errorMessages = [];

  @override
  void initState() {
    super.initState();
    _runTasks();
  }

  Future<void> _runTasks() async {
    // Execute functions here
    await Future.delayed(const Duration(seconds: 3));
    await _checkInternetConnection();
    await _checkBackendUrl();

    // Navigate to the login screen after initialization
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => settingsData['serverUrl'] != null
            ? const AuthenticationScreen() //const MainLayout() //AuthenticationScreen()
            : const BackendUrlScreen()));
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // Show error message
      setState(() {
        _errorMessages.add('No internet connection.');
      });
      await Future.delayed(const Duration(seconds: 5));
    } else {
      // Hide error message
      setState(() {
        //_errorMessages.add("Internet connection is available.");
      });
    }
  }

  Future<void> _checkBackendUrl() async {
    final bool isServerUrlSet = settingsData['serverUrl'] != null;
    // Check if serverUrl is set in the settings data
    if (!isServerUrlSet) {
      setState(() {
        _errorMessages.add('Server URL is not set');
        _errorMessages.add(
            'You will be directed to the server URL form screen in a few seconds.');
      });
      await Future.delayed(const Duration(seconds: 8));
    } else {
      // Check if serverUrl is reachable
      try {
        final response = await http.get(Uri.parse(settingsData['serverUrl']));
        if (response.statusCode == 200) {
          setState(() {
            //_errorMessages.add('Server URL is reachable.');
          });
        } else {
          setState(() {
            _errorMessages.add(
                'Server URL is not reachable. You may not be able to login.');
          });
          await Future.delayed(const Duration(seconds: 5));
        }
      } catch (e) {
        setState(() {
          _errorMessages.add(
              'Server URL is not reachable. You may not be able to login.');
        });
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
            // display app logo
            const SizedBox(height: 50.0),
            Image.asset(
              settingsData['appLogo'],
              height: 200,
              width: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30.0),
            Text(
              _errorMessages.isNotEmpty
                  ? _errorMessages.join('\n')
                  : 'Getting ready...',
              maxLines: _errorMessages.isNotEmpty ? _errorMessages.length : 1,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16.0,
                fontWeight: FontWeight.w100,
              ),
            ),
            const SizedBox(height: 50.0),

            const LoadingAnimator(),
          ],
        ), // Your loading indicator
      ),
    );
  }
}
