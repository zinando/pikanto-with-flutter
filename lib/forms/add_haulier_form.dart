import 'package:flutter/material.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddHaulierForm extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAddHaulier;

  const AddHaulierForm({super.key, required this.onAddHaulier});

  @override
  State createState() => _AddHaulierFormState();
}

class _AddHaulierFormState extends State<AddHaulierForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController registrationNumberController =
      TextEditingController();
  final TextEditingController haulierNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  bool isAddLoading = false;
  String errorMessage = '';

  Future<void> _addHaulier() async {
    setState(() {
      errorMessage = '';
    });
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isAddLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));

    final haulierCode = registrationNumberController.text;
    final companyName = haulierNameController.text;
    final address = addressController.text;

    try {
      final response = await http.post(
        Uri.parse('${settingsData['serverUrl']}/api/v1/haulier/add_new'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'registrationNumber': haulierCode,
          'companyName': companyName,
          'address': address,
          'actor': currentUser,
        }),
      );

      setState(() {
        isAddLoading = false;
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          if (mounted) {
            setState(() {
              widget.onAddHaulier(responseBody['data']);
            });
            Navigator.of(context).pop();
          }
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isAddLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    registrationNumberController.dispose();
    haulierNameController.dispose();
    addressController.dispose();
    _formKey.currentState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.15,
        vertical: MediaQuery.of(context).size.height * 0.2,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/logo/logo.jpeg',
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Add New Haulier',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff000000),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: registrationNumberController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Haulier Registration Number',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Haulier registration number cannot be empty';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: haulierNameController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Haulier Name',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Haulier name cannot be empty';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: addressController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Haulier Address',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Address cannot be empty';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  isAddLoading
                      ? const SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(),
                        )
                      : SizedBox(
                          height: 40.0,
                          width: MediaQuery.of(context).size.width * 0.3,
                          child: Text(
                            errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 11.0,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: 40,
            left: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                isAddLoading
                    ? const SizedBox()
                    : TextButton(
                        onPressed: _addHaulier,
                        child: const Text('Add Haulier'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
