import 'package:flutter/material.dart';
import 'package:pikanto/main.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:pikanto/helpers/my_functions.dart';

class BackendUrlScreen extends StatefulWidget {
  const BackendUrlScreen({super.key});
  @override
  _BackendUrlScreenState createState() => _BackendUrlScreenState();
}

class _BackendUrlScreenState extends State<BackendUrlScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String _errorMessage = '';

  void _submitUrl() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = '';
      });

      // Simulate URL validation or server check
      await Future.delayed(const Duration(seconds: 2));
      // Check internet connection first
      if (!await _checkInternetConnection()) {
        setState(() {
          _errorMessage = 'No internet connection.';
          _isSubmitting = false;
        });
        return;
      }

      final url = _urlController.text;
      if (await _isBackendServerRunning(url)) {
        // Server is running, update settings and navigate to the splash screen
        settingsData['serverUrl'] = url;
        if (!await MyFunctions.updateSettingsFile()) {
          setState(() {
            _errorMessage = '';
            _errorMessage +=
                'An error occurred while updating the settings file.\n';
            _errorMessage += 'We will continue with the setup process.\n';
            _errorMessage +=
                'But you will have to provide the URL again when next you start the app.';
            //_isSubmitting = false;
          });
          await Future.delayed(const Duration(seconds: 10));
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      } else {
        setState(() {
          _errorMessage =
              'The backend server is not running. Please check the URL.';
          _isSubmitting = false;
        });
        return;
      }
    }
  }

  Future<bool> _checkInternetConnection() async {
    Future.delayed(const Duration(seconds: 2));
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    return true;
  }

  Future<bool> _isBackendServerRunning(String url) async {
    // Make an HTTP request to the server to verify it's running
    await Future.delayed(const Duration(seconds: 2));
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      // Handle error
      setState(() {
        _errorMessage = 'Error: $e';
        _isSubmitting = false;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enter Server URL: e.g. http://localhost:3000 or https://example.com',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.tertiary),
                    ),
                    const SizedBox(height: 16.0),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              labelText: 'Server URL',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black,
                                ),
                              ),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(color: Colors.black),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a URL';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          _isSubmitting
                              ? loadingScreenWidgets[
                                  settingsData['loadingScreenWidget']]
                              : ElevatedButton(
                                  onPressed: _submitUrl,
                                  child: const Text('Submit'),
                                ),
                          const SizedBox(height: 20.0),
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
