import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/helpers/my_functions.dart';

class ChangeUserPassword extends StatefulWidget {
  const ChangeUserPassword({super.key});

  @override
  State createState() => _ChangeUserPasswordState();
}

class _ChangeUserPasswordState extends State<ChangeUserPassword> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSuccess = false;
  bool _obscureText = true;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    await Future.delayed(const Duration(seconds: 2));

    try {
      final response = await http.post(
        Uri.parse('${settingsData["serverUrl"]}/api/v1/user/change_password'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'oldPassword': 'NA',
          'newPassword': _newPasswordController.text,
          'email': _emailController.text,
          'actor': currentUser,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] > 1) {
          throw Exception(responseData['message']);
        }
        setState(() {
          _isSuccess = true;
        });
        MyFunctions.showSnackBar(context, responseData['message']);
      } else {
        throw Exception('Failed to change password: Server error');
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    color: Colors.grey[400],
                    child: const Text(
                      'CHANGE USER PASSWORD',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff000000),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 80.0,
                  ),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'User Email',
                      hintText: 'Enter the user\'s email',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'User email cannot be empty.';
                      } else if (!value.contains('@')) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _newPasswordController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Enter a new password',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    obscureText: _obscureText,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _confirmPasswordController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      hintText: 'Re-enter the new password',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    obscureText: _obscureText,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm the new password';
                      } else if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
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
                  const SizedBox(height: 32.0),
                  _isLoading
                      ? loadingScreenWidgets[
                          settingsData['loadingScreenWidget']]
                      : ElevatedButton(
                          onPressed: _changePassword,
                          child: const Text('Change Password'),
                        ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_isSuccess)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        'Password changed successfully!',
                        style: TextStyle(color: Colors.green),
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
