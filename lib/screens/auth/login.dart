import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/screens/main_layout.dart';
import 'package:pikanto/helpers/updater.dart';
import 'dart:convert';
import 'register.dart';
import 'package:flutter/services.dart';
import 'reset_password.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordError = false;
  String _errorMessage = '';
  bool _obscureText = true;

  // final SocketManager socketManager = SocketManager();

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _passwordError = false;
    });

    try {
      // Check internet connection
      if (!await _checkInternetConnection()) {
        setState(() {
          _errorMessage = 'No internet connection.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('${settingsData["serverUrl"]}/api/v1/user/login-user'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': _userIdController.text,
          'password': _passwordController.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        if (responseBody['status'] == 1) {
          // Update current user data
          setState(() {
            currentUser = responseBody['data'];
            // update list of users
            users = List<Map<String, dynamic>>.from(responseBody['users']);
          });
          //join websocket
          var data = jsonEncode({
            'userId': currentUser["userId"],
          });
          SocketManager().sendMessage('join_room', data);

          // check for app update

          final AppUpdater updater = AppUpdater();
          final resp = await updater.checkForUpdate(context);
          setState(() {
            _errorMessage = resp;
          });
          await Future.delayed(const Duration(seconds: 5));
          //return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainLayout(),
            ),
          );
        } else {
          setState(() {
            _errorMessage = responseBody['error'].join(', ');
            _passwordError = true;
          });
        }
      } else {
        throw Exception('Failed to authenticate. Please try again.');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connetion error.\n$error';
        _errorMessage += error.toString();
      });
    }
  }

  // Check internet connection
  Future<bool> _checkInternetConnection() async {
    //Future.delayed(const Duration(seconds: 2));
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event.logicalKey == LogicalKeyboardKey.enter) {
                  if (_formKey.currentState!.validate()) {
                    _authenticate();
                  }
                }
              },
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      settingsData['appLogo'],
                      height: 200.0,
                      width: 200.0,
                    ),
                    const SizedBox(
                        height: 24.0), // Add space between the logo and text
                    Text(
                      'Login Form',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(
                        height:
                            24.0), // Add space between the app name and form fields
                    SizedBox(
                      width: 300, // Adjust the width as needed
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _userIdController,
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              labelText: 'User ID',
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)), // Change the border color
                              focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors
                                          .grey)), // Change the border color
                              icon: Icon(Icons.person,
                                  color: Theme.of(context)
                                      .primaryColor), // Change the icon color
                              hintText: 'Your email e.g samuel@example.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',

                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)), // Change the border color
                              focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors
                                          .black)), // Change the border color
                              icon: Icon(Icons.lock,
                                  color: Theme.of(context)
                                      .primaryColor), // Change the icon color
                              hintText:
                                  'minimum: 1 uppercase, 1 lowercase, and 1 special char.',
                              hintStyle: const TextStyle(
                                fontSize: 9.0,
                                color: Colors.grey,
                              ),
                            ),
                            obscureText: _obscureText,
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: <Widget>[
                              Checkbox(
                                value: _obscureText,
                                onChanged: (value) {
                                  setState(() {
                                    _obscureText = value!;
                                  });
                                },
                              ),
                              const Text(
                                'Hide Password',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32.0),
                    if (_isLoading)
                      loadingScreenWidgets[settingsData['loadingScreenWidget']]
                    else
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _authenticate();
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                              Theme.of(context).colorScheme.tertiary),
                          foregroundColor: WidgetStateProperty.all<Color>(
                              Theme.of(context).colorScheme.onPrimary),
                        ),
                        child: const Text('Login'),
                      ),
                    const SizedBox(height: 16.0),
                    if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    _passwordError ? _authButtons() : const SizedBox(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _authButtons() {
    return SizedBox(
      width: double.infinity,
      height: 30.0,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                // Navigate to the Forgot Password screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                );
              },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all<Color>(
                    Theme.of(context).colorScheme.tertiary),
              ),
              child: const Text('Forgot Password?'),
            ),
            const Text('or you can', style: TextStyle(color: Colors.black)),
            TextButton(
              onPressed: () {
                // Navigate to the Register screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RegistrationScreen(),
                  ),
                );
              },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all<Color>(
                    Theme.of(context).colorScheme.tertiary),
              ),
              child: const Text('Register'),
            ),
            const Text('here.', style: TextStyle(color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
