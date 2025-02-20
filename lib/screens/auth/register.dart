import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'package:pikanto/resources/settings.dart';
import 'login.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscureText = true;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Delay for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // Check internet connection
    if (!await _checkInternetConnection()) {
      setState(() {
        _errorMessage = 'No internet connection.';
        _isLoading = false;
      });
      return;
    }

    final response = await http.post(
      Uri.parse('${settingsData["serverUrl"]}/api/v1/user/signup-super-admin'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (responseBody['status'] == 1) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) =>
                  // Go to login screen
                  const AuthenticationScreen()),
        );
      } else {
        setState(() {
          _errorMessage = responseBody['error'].join(', ');
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Failed to register. Please try again.';
      });
    }
  }

  // Check internet connection
  Future<bool> _checkInternetConnection() async {
    Future.delayed(const Duration(seconds: 2));
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
                    'Registration Form',
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
                    width: 600, // Adjust the width as needed
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'First Name',
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)), // Change the border color
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)), // Change the border color
                                  icon: Icon(Icons.person,
                                      color: Theme.of(context)
                                          .primaryColor), // Change the icon color
                                  hintText: 'Your first name',
                                ),
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your first name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Last Name',
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)), // Change the border color
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)), // Change the border color
                                  icon: Icon(Icons.person,
                                      color: Theme.of(context)
                                          .primaryColor), // Change the icon color
                                  hintText: 'Your last name',
                                ),
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your last name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)), // Change the border color
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)), // Change the border color
                                  icon: Icon(Icons.email,
                                      color: Theme.of(context)
                                          .primaryColor), // Change the icon color
                                  hintText: 'Your email address',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  } else if (!value.contains('@')) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: TextFormField(
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
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)), // Change the border color
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _confirmPasswordController,
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)), // Change the border color
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)), // Change the border color
                                  icon: Icon(Icons.lock,
                                      color: Theme.of(context)
                                          .primaryColor), // Change the icon color
                                  hintText: 'Re-enter your password',
                                ),
                                obscureText: _obscureText,
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  } else if (value !=
                                      _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _obscureText
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                  Text(
                                    _obscureText
                                        ? 'Show password'
                                        : 'Hide password',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
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
                    _authButtons(),
                  const SizedBox(height: 16.0),
                  if (_errorMessage.isNotEmpty)
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 40.0,
                      child: Center(
                        child: Text(
                          _errorMessage,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                ],
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
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _register();
                }
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                    Theme.of(context).colorScheme.tertiary),
                foregroundColor: WidgetStateProperty.all<Color>(
                    Theme.of(context).colorScheme.onPrimary),
              ),
              child: const Text('Register'),
            ),
            const SizedBox(width: 20.0),
            const Text('You can', style: TextStyle(color: Colors.black)),
            TextButton(
              onPressed: () {
                // Navigate to the Register screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AuthenticationScreen(),
                  ),
                );
              },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all<Color>(
                    Theme.of(context).colorScheme.tertiary),
              ),
              child: const Text('Login'),
            ),
            const Text('here.', style: TextStyle(color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
