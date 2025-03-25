import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/helpers/my_functions.dart';
import 'package:http/http.dart' as http;

class WeightRecordForm extends StatefulWidget {
  final Map<String, dynamic>? weightRecord;
  final String scaleReading;
  final String vehicleId;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> hauliers;
  final List<Map<String, dynamic>> customers;
  final Function(Map<String, dynamic>, bool) onSubmit;

  const WeightRecordForm({
    super.key,
    this.weightRecord,
    required this.scaleReading,
    required this.vehicleId,
    required this.customers,
    required this.hauliers,
    required this.products,
    required this.onSubmit,
  });

  @override
  State createState() => _WeightRecordFormState();
}

class _WeightRecordFormState extends State<WeightRecordForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the form fields
  final TextEditingController _vehicleIdController = TextEditingController();
  final TextEditingController _initialWeightController =
      TextEditingController();
  final TextEditingController _finalWeightController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _productController = TextEditingController(); //
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverPhoneController = TextEditingController();
  final TextEditingController _vehicleNameController =
      TextEditingController(); //
  final TextEditingController _haulierIdController = TextEditingController();
  final TextEditingController _customerIdController =
      TextEditingController(); //
  final TextEditingController _orderNumberController =
      TextEditingController(); //

  bool _isLoading = false;
  String? _errorMessage;
  bool _isUpdate = false;

  final MyFunctions myFunc = MyFunctions();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.weightRecord != null) {
      _vehicleIdController.text = widget.weightRecord!['vehicleId'];
      _initialWeightController.text =
          widget.weightRecord!['initialWeight'].toString();
      _finalWeightController.text = widget.scaleReading != ''
          ? widget.scaleReading
          : widget.weightRecord!['finalWeight'].toString();
      _destinationController.text = widget.weightRecord!['destination'];
      _productController.text = widget.weightRecord!['product'];
      _driverNameController.text = widget.weightRecord!['driverName'];
      _driverPhoneController.text = widget.weightRecord!['driverPhone'];
      _vehicleNameController.text = widget.weightRecord!['vehicleName'];
      _haulierIdController.text = widget.weightRecord!['haulierId'].toString();
      _customerIdController.text =
          widget.weightRecord!['customerId'].toString();
      _orderNumberController.text = widget.weightRecord!['orderNumber'];
      _isUpdate = true;
    } else {
      _vehicleIdController.text = widget.vehicleId;
      _initialWeightController.text =
          widget.scaleReading; // Set the initial weight to the scale reading
      _finalWeightController.clear();
      _destinationController.clear();
      _productController.text =
          products.isNotEmpty ? products[0]['productDescription'] ?? '' : '';
      _driverNameController.clear();
      _driverPhoneController.clear();
      _vehicleNameController.text = 'Lurry';
      _haulierIdController.clear();
      _customerIdController.text = customers.isNotEmpty
          ? customers[0]['customerId']?.toString() ?? ''
          : '';
      _orderNumberController.text = MyFunctions.generateOrderNumber();
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Construct the new record
      Map<String, dynamic> newRecord = {
        'vehicleId': _vehicleIdController.text,
        'initialWeight': double.tryParse(_initialWeightController.text) != null
            ? double.parse(_initialWeightController.text)
            : _initialWeightController.text,
        'finalWeight': double.tryParse(_finalWeightController.text) != null
            ? double.parse(_finalWeightController.text)
            : _finalWeightController.text,
        'destination': _destinationController.text,
        'product': _productController.text,
        'driverName': _driverNameController.text,
        'driverPhone': _driverPhoneController.text,
        'vehicleName': _vehicleNameController.text,
        'haulierId': _haulierIdController.text.isEmpty
            ? _haulierIdController.text
            : int.parse(_haulierIdController.text),
        'customerId': _customerIdController.text.isEmpty
            ? _customerIdController.text
            : int.parse(_customerIdController.text),
        'orderNumber': _orderNumberController.text,
        'operatorId': currentUser['userId'] ?? 1,
        'appId': settingsData['companyId'],
        'actor': currentUser,
      };

      // update last recorded weight notifier
      lastRecordedWeightNotifier.value = newRecord['initialWeight'].toString();
      // Add other fields if the record is an update
      if (_isUpdate) {
        newRecord['weightRecordId'] = widget.weightRecord!['weightRecordId'];
        newRecord['approvalStatus'] = widget.weightRecord!['approvalStatus'];
        lastRecordedWeightNotifier.value = newRecord['finalWeight'].toString();
      }

      // store the last recorded weight in the shared preferences and notify listeners
      storeLocalData('lastRecordedWeight', lastRecordedWeightNotifier.value);
      lastRecordedWeightNotifier.notifyListeners();

      try {
        final response = _isUpdate
            ? await http.put(
                Uri.parse(
                    '${settingsData["serverUrl"]}/api/v1/weight_record/update_record'),
                headers: {
                  'Content-Type': 'application/json; charset=UTF-8',
                },
                body: jsonEncode(newRecord),
              )
            : await http.post(
                Uri.parse(
                    '${settingsData["serverUrl"]}/api/v1/weight_record/add_new'),
                headers: {
                  'Content-Type': 'application/json; charset=UTF-8',
                },
                body: jsonEncode(newRecord),
              );

        if (response.statusCode != 200) {
          throw Exception('Failed to submit data');
        } else if (response.statusCode == 200) {
          // get the response body
          final Map<String, dynamic> responseBody = jsonDecode(response.body);
          if (responseBody['status'] != 1) {
            throw Exception(responseBody['message']);
          } else {
            // add the new record to the list of records
            widget.onSubmit(
                responseBody['data'] as Map<String, dynamic>, _isUpdate);
          }
        }

        Navigator.of(context)
            .pop(); // Close the dialog on successful submission
      } catch (error) {
        setState(() {
          _errorMessage = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/logo/logo.jpeg',
                width: MediaQuery.of(context).size.width * 0.3,
                height: MediaQuery.of(context).size.height * 0.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.weightRecord == null
                      ? 'Create New Weight Record for: ${widget.vehicleId}'
                      : 'Update Weight Record for: ${widget.vehicleId}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(
                  color: Theme.of(context).colorScheme.primary,
                  thickness: 2.0,
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              controller: _vehicleIdController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                  labelText: 'Enter Vehicle ID',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  )),
                              readOnly:
                                  widget.scaleReading == '' ? false : true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a Vehicle ID';
                                }
                                return null; // Input is valid
                              },
                            ),
                          ),
                          // const SizedBox(width: 40),
                          // Expanded(
                          //   child: TextFormField(
                          //     controller: _vehicleNameController,
                          //     style: const TextStyle(color: Colors.black),
                          //     decoration: const InputDecoration(
                          //         labelText: 'Enter Vehicle Name',
                          //         enabledBorder: OutlineInputBorder(
                          //           borderSide: BorderSide(color: Colors.black),
                          //         ),
                          //         border: UnderlineInputBorder(
                          //           borderSide: BorderSide(color: Colors.black),
                          //         )),
                          //     validator: (value) {
                          //       if (value == null || value.isEmpty) {
                          //         return 'Please enter a Vehicle Name';
                          //       }
                          //       return null; // Input is valid
                          //     },
                          //   ),
                          // ),
                          // const SizedBox(width: 40),
                          // Expanded(
                          //   child: TextFormField(
                          //     controller: _orderNumberController,
                          //     style: const TextStyle(color: Colors.black),
                          //     decoration: const InputDecoration(
                          //         labelText: 'Enter Order Number',
                          //         enabledBorder: OutlineInputBorder(
                          //           borderSide: BorderSide(color: Colors.black),
                          //         ),
                          //         border: UnderlineInputBorder(
                          //           borderSide: BorderSide(color: Colors.black),
                          //         )),
                          //     validator: (value) {
                          //       if (value == null || value.isEmpty) {
                          //         return 'Please enter a Order Number';
                          //       }
                          //       return null; // Input is valid
                          //     },
                          //   ),
                          // ),
                          const SizedBox(width: 20),
                        ],
                      ),
                      const SizedBox(height: 60),
                      Row(
                        children: [
                          const SizedBox(width: 20),
                          // Expanded(
                          //   child: DropdownButtonFormField<String>(
                          //     isExpanded: true,
                          //     //elevation: 0,
                          //     decoration: const InputDecoration(
                          //         labelText: 'Select Product',
                          //         enabledBorder: OutlineInputBorder(
                          //           borderSide: BorderSide(color: Colors.black),
                          //         ),
                          //         border: UnderlineInputBorder(
                          //           borderSide: BorderSide(color: Colors.black),
                          //         )),
                          //     value: _productController.text.isNotEmpty
                          //         ? _productController.text
                          //         : null,
                          //     items: widget.products
                          //         .where((item) => item['deleteFlag'] == 0)
                          //         .map((item) {
                          //       return DropdownMenuItem<String>(
                          //         value: item['productDescription'],
                          //         child: Text(item['productDescription']!),
                          //       );
                          //     }).toList(),
                          //     validator: (value) {
                          //       if (value == null || value.isEmpty) {
                          //         return 'Please select a Product';
                          //       }
                          //       return null; // Input is valid
                          //     },
                          //     onChanged: (String? newValue) {
                          //       setState(() {
                          //         _productController.text = newValue ?? '';
                          //       });
                          //     },
                          //   ),
                          // ),
                          // const SizedBox(width: 40),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                  labelText: 'Select Haulier',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  )),
                              value: _haulierIdController.text.isNotEmpty
                                  ? _haulierIdController.text
                                  : null,
                              items: widget.hauliers
                                  .where((item) => item['deleteFlag'] == 0)
                                  .map((item) {
                                return DropdownMenuItem<String>(
                                  value: item['haulierId'].toString(),
                                  child: Text(item['companyName']!),
                                );
                              }).toList(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a Haulier';
                                }
                                return null; // Input is valid
                              },
                              onChanged: (String? newValue) {
                                setState(() {
                                  _haulierIdController.text = newValue ?? '';
                                });
                              },
                            ),
                          ),
                          // const SizedBox(width: 40),
                          // Expanded(
                          //   child: DropdownButtonFormField<String>(
                          //     decoration: const InputDecoration(
                          //         labelText: 'Select Customer',
                          //         enabledBorder: OutlineInputBorder(
                          //           borderSide: BorderSide(color: Colors.black),
                          //         ),
                          //         border: UnderlineInputBorder(
                          //           borderSide: BorderSide(color: Colors.black),
                          //         )),
                          //     value: _customerIdController.text.isNotEmpty
                          //         ? _customerIdController.text
                          //         : null,
                          //     items: widget.customers
                          //         .where((item) => item['deleteFlag'] == 0)
                          //         .map((item) {
                          //       return DropdownMenuItem<String>(
                          //         value: item['customerId'].toString(),
                          //         child: Text(item['customerName']!),
                          //       );
                          //     }).toList(),
                          //     validator: (value) {
                          //       if (value == null || value.isEmpty) {
                          //         return 'Please select a Customer';
                          //       }
                          //       return null; // Input is valid
                          //     },
                          //     onChanged: (String? newValue) {
                          //       setState(() {
                          //         _customerIdController.text = newValue ?? '';
                          //       });
                          //     },
                          //   ),
                          // ),
                          const SizedBox(width: 40),
                          Expanded(
                            child: TextFormField(
                              controller: _destinationController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                  labelText: 'Enter Destination',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  )),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the Destination';
                                }
                                return null; // Input is valid
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),
                      const SizedBox(height: 60),
                      Row(
                        children: [
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              controller: _driverNameController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                  labelText: 'Enter Driver\'s Name',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  )),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the Driver\'s Name';
                                }
                                return null; // Input is valid
                              },
                            ),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            child: TextFormField(
                              controller: _driverPhoneController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                  labelText: 'Enter Driver\'s Phone Number',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  )),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the Driver\'s Phone Number';
                                }
                                return null; // Input is valid
                              },
                            ),
                          ),
                          // const SizedBox(width: 40),
                          // Expanded(
                          //   child: TextFormField(
                          //     controller: _destinationController,
                          //     style: const TextStyle(color: Colors.black),
                          //     decoration: const InputDecoration(
                          //         labelText: 'Enter Destination',
                          //         enabledBorder: OutlineInputBorder(
                          //           borderSide: BorderSide(color: Colors.black),
                          //         ),
                          //         border: UnderlineInputBorder(
                          //           borderSide: BorderSide(color: Colors.black),
                          //         )),
                          //     validator: (value) {
                          //       if (value == null || value.isEmpty) {
                          //         return 'Please enter the Destination';
                          //       }
                          //       return null; // Input is valid
                          //     },
                          //   ),
                          // ),
                          const SizedBox(width: 20),
                        ],
                      ),
                      const SizedBox(height: 60),
                      Row(
                        children: [
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              controller: _initialWeightController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                  labelText: 'Initial Weight',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  )),
                              readOnly: true,
                              //widget.scaleReading == '' ? false : true,
                            ),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            child: TextFormField(
                              controller: _finalWeightController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                  labelText: 'Final Weight',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  )),
                              readOnly: true,
                              //widget.scaleReading == '' ? false : true,
                            ),
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 40),
                  Text(
                    _errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else ...[
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: Text(
                            widget.weightRecord == null ? 'Create' : 'Update'),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
