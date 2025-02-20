import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/helpers/my_functions.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isCodeSent = false;
  bool _isCodeVerified = false;
  String _errorMessage = '';
  String _passwordResetCode = '';

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) {
      return; // If the form is not valid, exit the function
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await Future.delayed(const Duration(seconds: 2));

    try {
      final response = await http.post(
        Uri.parse(
            '${settingsData["serverUrl"]}/api/v1/user/send_password_reset_code'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'email': _emailController.text,
          'appId': settingsData['companyId'],
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        if (responseBody['status'] == 1) {
          setState(() {
            _isCodeSent = true;
            _passwordResetCode = responseBody['data'];
          });
          MyFunctions.showSnackBar(
              context, 'Code sent to your email. Check your inbox.');
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception('Server Error, please contact admin.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection Error: $e';
      });
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) {
      return; // If the form is not valid, exit the function
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Delay for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (_passwordResetCode == _codeController.text) {
      setState(() {
        _isCodeVerified = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = 'Wrong code. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return; // If the form is not valid, exit the function
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Delay for 2 seconds
    await Future.delayed(const Duration(seconds: 12));

    try {
      final response = await http.post(
        Uri.parse('${settingsData["serverUrl"]}/api/v1/user/change_password'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'email': _emailController.text,
          'code': _codeController.text,
          'newPassword': _newPasswordController.text,
          'appId': settingsData['companyId'],
          'oldPassword': 'NA',
          'actor': {'userId': 1}, // acting on behalf of super admin
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        if (responseBody['status'] == 1) {
          MyFunctions.showSnackBar(context,
              'Password reset successful. You will be redirected to the login screen in 10 seconds.');
          // Delay for 3 seconds
          await Future.delayed(const Duration(seconds: 10));
          Navigator.of(context).pop(); // Go back to the previous screen
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception('Server Error, please contact admin.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.of(context).pop(), // Go back to the previous screen
        ),
      ),
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
                    'Reset Password Form',
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

                  if (!_isCodeSent)
                    SizedBox(
                      width: 400.0,
                      height: 200.0,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email address',
                                enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.black))),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              } else if (!value.contains('@')) {
                                return 'Please provide a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          _isLoading
                              ? loadingScreenWidgets[
                                  settingsData['loadingScreenWidget']]
                              : ElevatedButton(
                                  onPressed: _isLoading ? null : _sendResetCode,
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all<
                                            Color>(
                                        Theme.of(context).colorScheme.tertiary),
                                    foregroundColor:
                                        WidgetStateProperty.all<Color>(
                                            Theme.of(context)
                                                .colorScheme
                                                .onPrimary),
                                  ),
                                  child: const Text('Send Reset Code'),
                                ),
                        ],
                      ),
                    )
                  else if (!_isCodeVerified)
                    SizedBox(
                      width: 400.0,
                      height: 200.0,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _codeController,
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                                labelText: 'Verification Code',
                                hintText:
                                    'Enter the ${_passwordResetCode.length} digit code sent to your email',
                                enabledBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.black))),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the ${_passwordResetCode.length} digit code sent to your email.';
                              } else if (value.length !=
                                  _passwordResetCode.length) {
                                return 'Provide a valid code';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          _isLoading
                              ? loadingScreenWidgets[
                                  settingsData['loadingScreenWidget']]
                              : ElevatedButton(
                                  onPressed: _isLoading ? null : _verifyCode,
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all<
                                            Color>(
                                        Theme.of(context).colorScheme.tertiary),
                                    foregroundColor:
                                        WidgetStateProperty.all<Color>(
                                            Theme.of(context)
                                                .colorScheme
                                                .onPrimary),
                                  ),
                                  child: const Text('Verify Code'),
                                ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: 400.0,
                      height: 300.0,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _newPasswordController,
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                            decoration: const InputDecoration(
                                labelText: 'New Password',
                                hintText: 'Enter your new password',
                                enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.black))),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your new password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _confirmPasswordController,
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                            decoration: const InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Confirm your new password',
                                enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.black))),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your new password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          _isLoading
                              ? loadingScreenWidgets[
                                  settingsData['loadingScreenWidget']]
                              : ElevatedButton(
                                  onPressed: _isLoading ? null : _resetPassword,
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all<
                                            Color>(
                                        Theme.of(context).colorScheme.tertiary),
                                    foregroundColor:
                                        WidgetStateProperty.all<Color>(
                                            Theme.of(context)
                                                .colorScheme
                                                .onPrimary),
                                  ),
                                  child: const Text('Reset Password'),
                                ),
                        ],
                      ),
                    ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: SizedBox(
                        width: 500.00,
                        child: Text(
                          _errorMessage,
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
}
