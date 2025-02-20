import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/helpers/my_functions.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});
  @override
  State createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading =
      false; // shows when page is loading data from database as user visits the screen
  bool _isEmptyList = true;
  bool _isEditLoading = false; // shows during edit operation
  bool _isDeletedCustomersShown = false;
  bool _isRestoring = false;
  String? _editingCustomerId;
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse(
          '${settingsData['serverUrl']}/api/v1/customer/fetch_customers'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          List<Map<String, dynamic>> data =
              List<Map<String, dynamic>>.from(responseBody['data']);
          if (mounted) {
            setState(() {
              _customers = data
                  .where((customer) => customer['deleteFlag'] == 0)
                  .toList();
              customers = data;
              _isEmptyList = _customers.isEmpty;
            });
          }
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      MyFunctions.showSnackBar(context, 'An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCustomer(int customerId) async {
    if (_registrationNumberController.text.isEmpty) {
      MyFunctions.showSnackBar(
          context, 'Customer registration number cannot be empty');
      return;
    }
    if (_customerNameController.text.isEmpty) {
      MyFunctions.showSnackBar(context, 'Customer name cannot be empty');
      return;
    }
    if (_addressController.text.isEmpty) {
      MyFunctions.showSnackBar(context, 'Address cannot be empty');
      return;
    }

    final customerCode = _registrationNumberController.text;
    final customerName = _customerNameController.text;
    final address = _addressController.text;
    setState(() {
      _isEditLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));

    try {
      final response = await http.put(
        Uri.parse(
            '${settingsData["serverUrl"]}/api/v1/customer/update_customer'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'customerId': customerId,
          'registrationNumber': customerCode,
          'customerName': customerName,
          'address': address,
          'actor': currentUser,
        }),
      );

      setState(() {
        _isEditLoading = false;
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          List<Map<String, dynamic>> newList =
              List<Map<String, dynamic>>.from(responseBody['data']);
          if (mounted) {
            setState(() {
              _customers = newList
                  .where((customer) => customer['deleteFlag'] == 0)
                  .toList();
              customers = newList;
              _isEmptyList = _customers.isEmpty;
              _editingCustomerId = null;
            });
          }
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception('Failed to update customer');
      }
    } catch (e) {
      setState(() {
        _isEditLoading = false;
      });
      MyFunctions.showSnackBar(context, 'An error occurred: $e');
    }
  }

  Future<void> _deleteCustomer(int customerId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '${settingsData["serverUrl"]}/api/v1/customer/delete_customer'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'customerId': customerId,
          'actor': currentUser,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          List<Map<String, dynamic>> newList =
              List<Map<String, dynamic>>.from(responseBody['data']);
          if (mounted) {
            setState(() {
              _customers =
                  newList.where((test) => test['deleteFlag'] == 0).toList();
              customers = newList;
              _isDeletedCustomersShown = false;
              _isEmptyList = newList.isEmpty;
            });
          }
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      MyFunctions.showSnackBar(context, 'An error occurred: $e');
    }
  }

  Future<void> _restoreDeletedCustomer(int customerId) async {
    setState(() {
      _isRestoring = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    try {
      final response = await http.put(
        Uri.parse(
            '${settingsData["serverUrl"]}/api/v1/customer/restore_deleted_customer'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'customerId': customerId,
          'actor': currentUser,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          List<Map<String, dynamic>> newList =
              List<Map<String, dynamic>>.from(responseBody['data']);
          if (mounted) {
            setState(() {
              _customers = newList;
              customers = newList;
              _isRestoring = false;
              _isEmptyList = newList.isEmpty;
            });
          }
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isRestoring = false;
      });
      MyFunctions.showSnackBar(context, 'An error occurred: $e');
    }
  }

  Future<bool> _showDeleteConfirmationDialog(String customerId) async {
    final Map<String, dynamic> customer = _customers.firstWhere(
        (customer) => customer['customerId'].toString() == customerId,
        orElse: () => <String, dynamic>{}); // Return an empty map if not found
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Confirm Deletion'),
              content: customer.isNotEmpty
                  ? Text(
                      'Are you sure you want to delete this customer?\n\n'
                      'Customer Code: ${customer['registrationNumber']}\n'
                      'Description: ${customer['customerName']}',
                      style: TextStyle(color: Colors.grey[800]))
                  : Text(
                      'You cannot delete this item because it does not have id.',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                customer.isNotEmpty
                    ? TextButton(
                        child: const Text('Delete'),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      )
                    : const SizedBox(),
              ],
            );
          },
        ) ??
        false;
  }

  void _revealAddCustomerDialog() {
    _registrationNumberController.clear();
    _customerNameController.clear();
    _addressController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AddCustomerDialog(
          onAddCustomer: _addCustomerToList,
          registrationNumberController: _registrationNumberController,
          customerNameController: _customerNameController,
          addressController: _addressController,
        );
      },
    );
  }

  void _addCustomerToList(Map<String, dynamic> customer) {
    setState(() {
      _customers.insert(0, customer);
      customers.insert(0, customer);
    });
  }

  void _toggleDeletedCustomers() {
    if (_isDeletedCustomersShown) {
      setState(() {
        _customers = customers
            .where((testProduct) => testProduct['deleteFlag'] == 0)
            .toList();
        _isEmptyList = _customers.isEmpty;
      });
    } else {
      setState(() {
        _customers = customers;
        _isEmptyList = _customers.isEmpty;
      });
    }
    setState(() {
      _isDeletedCustomersShown = !_isDeletedCustomersShown;
    });
  }

  @override
  void dispose() {
    _registrationNumberController.dispose();
    _customerNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8.0),
          Row(
            children: [
              const Text(
                'Customers List',
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff000000),
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  children: [
                    FloatingActionButton(
                      onPressed: currentUser['permissions']['canAddCustomer']
                          ? _revealAddCustomerDialog
                          : null,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      mini: true,
                      child: const Icon(Icons.add),
                    ),
                    if (currentUser['permissions']['canDeleteCustomer']) ...[
                      const SizedBox(width: 8.0),
                      FloatingActionButton(
                        onPressed: _toggleDeletedCustomers,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        mini: true,
                        tooltip: _isDeletedCustomersShown
                            ? 'Hide deleted customers'
                            : 'Show deleted customers',
                        child: _isDeletedCustomersShown
                            ? const Icon(Icons.visibility)
                            : const Icon(Icons.visibility_off),
                      )
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isEmptyList
                  ? _buildEmptyList()
                  : Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            height: 40.0,
                            color: Colors.grey[600],
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Registration Number',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Customer Name',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Customer Address',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Actions',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _customers.length,
                              itemBuilder: (context, index) {
                                final customer = _customers[index];
                                final isEditing = _editingCustomerId ==
                                    customer['customerId'].toString();

                                return ListTile(
                                  title: isEditing
                                      ? Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: _registrationNumberController
                                                  ..text = _registrationNumberController
                                                          .text.isNotEmpty
                                                      ? _registrationNumberController
                                                          .text
                                                      : customer[
                                                          'registrationNumber'],
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  labelText:
                                                      'Registration Number',
                                                  enabledBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8.0),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _customerNameController
                                                  ..text = _customerNameController
                                                          .text.isNotEmpty
                                                      ? _customerNameController
                                                          .text
                                                      : customer[
                                                          'customerName'],
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Customer Name',
                                                  enabledBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8.0),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _addressController
                                                  ..text = _addressController
                                                          .text.isNotEmpty
                                                      ? _addressController.text
                                                      : customer['address']
                                                          .toString(),
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Address',
                                                  enabledBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Container(
                                          padding: const EdgeInsets.fromLTRB(
                                              10, 0, 10, 0),
                                          color: index.isEven
                                              ? Colors.grey[200]
                                              : Colors.grey[100],
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                    customer[
                                                        'registrationNumber'],
                                                    style: TextStyle(
                                                      color: customer[
                                                                  'deleteFlag'] ==
                                                              0
                                                          ? Colors.black
                                                          : Colors.grey[500],
                                                    )),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                child: Text(
                                                    customer['customerName'],
                                                    style: TextStyle(
                                                      color: customer[
                                                                  'deleteFlag'] ==
                                                              0
                                                          ? Colors.black
                                                          : Colors.grey[500],
                                                    )),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                child: Text(
                                                    customer['address']
                                                        .toString(),
                                                    style: TextStyle(
                                                      color: customer[
                                                                  'deleteFlag'] ==
                                                              0
                                                          ? Colors.black
                                                          : Colors.grey[500],
                                                    )),
                                              ),
                                            ],
                                          ),
                                        ),
                                  trailing: customer['deleteFlag'] == 1
                                      ? _isRestoring
                                          ? const SizedBox(
                                              height: 20.0,
                                              width: 20.0,
                                              child:
                                                  CircularProgressIndicator())
                                          : IconButton(
                                              icon: Icon(Icons.restore,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .tertiary),
                                              tooltip: 'Restore customer',
                                              onPressed: () async {
                                                final bool shouldRestore =
                                                    await showRestoreConfirmation(
                                                        context,
                                                        'Are you sure you want to restore this customer?\n\n'
                                                        'Customer Name: ${customer['customerName']}');
                                                if (shouldRestore) {
                                                  _restoreDeletedCustomer(
                                                      customer['customerId']);
                                                }
                                              },
                                            )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            if (isEditing)
                                              _isEditLoading
                                                  ? const SizedBox(
                                                      height: 20.0,
                                                      width: 20.0,
                                                      child:
                                                          CircularProgressIndicator())
                                                  : Row(
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(Icons.save,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .tertiary),
                                                          onPressed: () {
                                                            _updateCustomer(
                                                                customer[
                                                                    'customerId']);
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: Icon(
                                                              Icons.cancel,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .tertiary),
                                                          onPressed: () {
                                                            setState(() {
                                                              _editingCustomerId =
                                                                  null;
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    )
                                            else
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary),
                                                onPressed: () {
                                                  if (!currentUser[
                                                          'permissions']
                                                      ['canEditCustomer']) {
                                                    return;
                                                  }
                                                  setState(() {
                                                    _editingCustomerId =
                                                        customer['customerId']
                                                            .toString();
                                                    _registrationNumberController
                                                            .text =
                                                        customer[
                                                            'registrationNumber'];
                                                    _customerNameController
                                                            .text =
                                                        customer[
                                                            'customerName'];
                                                    _addressController.text =
                                                        customer['address'];
                                                  });
                                                },
                                              ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () async {
                                                if (!currentUser['permissions']
                                                    ['canDeleteCustomer']) {
                                                  return;
                                                }
                                                final shouldDelete =
                                                    await _showDeleteConfirmationDialog(
                                                        customer['customerId']
                                                            .toString());
                                                if (shouldDelete) {
                                                  _deleteCustomer(
                                                      customer['customerId']);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildEmptyList() {
    return const Center(
      child: Text('No customers available',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Color(0xaa000000),
          )),
    );
  }
}

class AddCustomerDialog extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAddCustomer;
  final TextEditingController registrationNumberController;
  final TextEditingController customerNameController;
  final TextEditingController addressController;

  const AddCustomerDialog({
    super.key,
    required this.onAddCustomer,
    required this.registrationNumberController,
    required this.customerNameController,
    required this.addressController,
  });

  @override
  State createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  bool isAddLoading = false;
  String errorMessage = '';

  Future<void> _addCustomer() async {
    setState(() {
      errorMessage = '';
    });

    if (widget.registrationNumberController.text.isEmpty) {
      setState(() {
        errorMessage = 'Customer registration number cannot be empty';
      });
      return;
    }
    if (widget.customerNameController.text.isEmpty) {
      setState(() {
        errorMessage = 'Customer name cannot be empty';
      });
      return;
    }
    if (widget.addressController.text.isEmpty) {
      setState(() {
        errorMessage = 'Address cannot be empty';
      });
      return;
    }

    setState(() {
      isAddLoading = true;
    });

    final haulierCode = widget.registrationNumberController.text;
    final customerName = widget.customerNameController.text;
    final address = widget.addressController.text;

    await Future.delayed(const Duration(seconds: 2));

    try {
      final response = await http.post(
        Uri.parse('${settingsData['serverUrl']}/api/v1/customer/add_new'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'registrationNumber': haulierCode,
          'customerName': customerName,
          'address': address,
          'actor': currentUser,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          if (mounted) {
            widget.onAddCustomer(responseBody['data']);
            Navigator.of(context).pop();
          }
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isAddLoading = false;
      });
    }
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
            child: Column(
              children: [
                const Text(
                  'Add New Customer',
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
                      TextField(
                        controller: widget.registrationNumberController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          labelText: 'Customer Registration Number',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                      TextField(
                        controller: widget.customerNameController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          labelText: 'Customer Name',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                      TextField(
                        controller: widget.addressController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          labelText: 'Customer Address',
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
                        onPressed: () async {
                          //await widget.onAddCustomer();
                          //Navigator.of(context).pop();
                          _addCustomer();
                        },
                        child: const Text('Add Customer'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
