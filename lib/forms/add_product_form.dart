import 'package:flutter/material.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class AddProductForm extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAddProduct;

  const AddProductForm({super.key, required this.onAddProduct});

  @override
  State createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _productDescriptionController =
      TextEditingController();
  final TextEditingController _countPerCaseController = TextEditingController();
  final TextEditingController _weightPerCountController =
      TextEditingController();
  bool isAddLoading = false;
  String errorMessage = '';

  Future<void> _addProduct() async {
    // Check if productCode and productDescription are not empty
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

    final productCode = _productCodeController.text;
    final productDescription = _productDescriptionController.text;
    final countPerCase = _countPerCaseController.text.isEmpty
        ? null
        : int.parse(_countPerCaseController.text);
    final weightPerCount = _weightPerCountController.text.isEmpty
        ? null
        : int.parse(_weightPerCountController.text);

    try {
      final response = await http.post(
        Uri.parse('${settingsData['serverUrl']}/api/v1/product/add_new'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'productCode': productCode,
          'productDescription': productDescription,
          'countPerCase': countPerCase,
          'weightPerCount': weightPerCount,
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
            widget.onAddProduct(responseBody['data']);
            Navigator.of(context).pop();
          }
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors
      setState(() {
        isAddLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _productCodeController.dispose();
    _productDescriptionController.dispose();
    _countPerCaseController.dispose();
    _weightPerCountController.dispose();
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
                          controller: _productCodeController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Product Code',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Product code cannot be empty';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _productDescriptionController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Product Description',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Product description cannot be empty';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _countPerCaseController,
                          style: const TextStyle(color: Colors.black),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Count Per Case (number only)',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Count per case cannot be empty';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _weightPerCountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Weight Per Count (number only)',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
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
                        onPressed: _addProduct,
                        child: const Text('Add Product'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
