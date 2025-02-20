import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pikanto/forms/add_haulier_form.dart';
import 'package:pikanto/helpers/my_functions.dart';
import 'package:pikanto/resources/settings.dart';

class HauliersPage extends StatefulWidget {
  const HauliersPage({super.key});
  @override
  State createState() => _HauliersPageState();
}

class _HauliersPageState extends State<HauliersPage> {
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isEmptyList = true;
  bool _isEditLoading = false;
  bool _isDeletedHauliersShown = false;
  bool _isRestoring = false;
  String? _editingHaulierId;
  List<Map<String, dynamic>> _hauliers = [];

  @override
  void initState() {
    super.initState();
    _fetchHauliers();
  }

  Future<void> _fetchHauliers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse(
          '${settingsData['serverUrl']}/api/v1/haulier/fetch_hauliers'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        List<Map<String, dynamic>> data =
            List<Map<String, dynamic>>.from(responseBody['data']);
        if (responseBody['status'] == 1) {
          if (mounted) {
            setState(() {
              _hauliers =
                  data.where((product) => product['deleteFlag'] == 0).toList();
              hauliers = data;
              _isEmptyList = _hauliers.isEmpty;
              _isLoading = false;
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

  void _showAddHaulierDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddHaulierForm(
          onAddHaulier: _addHaulierToList,
        );
      },
    );
  }

  void _addHaulierToList(Map<String, dynamic> haulier) {
    setState(() {
      _hauliers.insert(0, haulier);
      hauliers.insert(0, haulier);
    });
  }

  Future<void> _updateHaulier(int haulierId) async {
    if (_registrationNumberController.text.isEmpty) {
      MyFunctions.showAlertDialog(
          context, 'Error', 'Registration number cannot be empty');
      return;
    }
    if (_companyNameController.text.isEmpty) {
      MyFunctions.showAlertDialog(
          context, 'Error', 'Company name cannot be empty');
      return;
    }
    if (_addressController.text.isEmpty) {
      MyFunctions.showAlertDialog(context, 'Error', 'Address cannot be empty');
      return;
    }
    setState(() {
      _isEditLoading = true;
    });

    final haulierCode = _registrationNumberController.text;
    final companyName = _companyNameController.text;
    final address = _addressController.text;

    await Future.delayed(const Duration(seconds: 2));

    try {
      final response = await http.put(
        Uri.parse('${settingsData["serverUrl"]}/api/v1/haulier/update_haulier'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'haulierId': haulierId,
          'registrationNumber': haulierCode,
          'companyName': companyName,
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
          if (mounted) {
            List<Map<String, dynamic>> updatedList =
                List<Map<String, dynamic>>.from(responseBody['data']);
            setState(() {
              _hauliers =
                  updatedList.where((test) => test['deleteFlag'] == 0).toList();
              hauliers = updatedList;
              _editingHaulierId = null;
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
        _isEditLoading = false;
      });
      MyFunctions.showSnackBar(context, 'An error occurred: $e');
    }
  }

  Future<void> _deleteHaulier(int haulierId) async {
    try {
      final response = await http.delete(
        Uri.parse('${settingsData["serverUrl"]}/api/v1/haulier/delete_haulier'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'haulierId': haulierId,
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
              _hauliers =
                  newList.where((test) => test['deleteFlag'] == 0).toList();
              hauliers = newList;
              _isEmptyList = newList.isEmpty;
              _isDeletedHauliersShown = false;
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

  Future<void> _restoreDeletedHaulier(int haulierId) async {
    setState(() {
      _isRestoring = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    try {
      final response = await http.put(
        Uri.parse(
            '${settingsData["serverUrl"]}/api/v1/haulier/restore_deleted_haulier'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'haulierId': haulierId,
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
              _hauliers = newList;
              hauliers = newList;
              _isEmptyList = newList.isEmpty;
              _isRestoring = false;
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
      setState(() {
        _isRestoring = false;
      });
    }
  }

  Future<bool> _showDeleteConfirmationDialog(String haulierId) async {
    final Map<String, dynamic> haulier = _hauliers.firstWhere(
        (haulier) => haulier['haulierId'].toString() == haulierId,
        orElse: () => <String, dynamic>{}); // Return an empty map if not found
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Confirm Deletion'),
              content: haulier.isNotEmpty
                  ? Text(
                      'Are you sure you want to delete this product?\n\n'
                      'Product Code: ${haulier['registrationNumber']}\n'
                      'Description: ${haulier['companyName']}',
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
                haulier.isNotEmpty
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

  void _toggleDeletedHauliers() {
    if (_isDeletedHauliersShown) {
      setState(() {
        _hauliers = hauliers
            .where((testProduct) => testProduct['deleteFlag'] == 0)
            .toList();
        _isEmptyList = _hauliers.isEmpty;
      });
    } else {
      setState(() {
        _hauliers = hauliers;
        _isEmptyList = _hauliers.isEmpty;
      });
    }
    setState(() {
      _isDeletedHauliersShown = !_isDeletedHauliersShown;
    });
  }

  @override
  void dispose() {
    _registrationNumberController.dispose();
    _companyNameController.dispose();
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
                'List of Hauliers',
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
                      onPressed: currentUser['permissions']['canAddHaulier']
                          ? _showAddHaulierDialog
                          : null,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      mini: true,
                      tooltip: 'Add haulier',
                      child: const Icon(Icons.add),
                    ),
                    if (currentUser['permissions']['canDeleteHaulier']) ...[
                      const SizedBox(width: 8.0),
                      FloatingActionButton(
                        onPressed: _toggleDeletedHauliers,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        mini: true,
                        tooltip: _isDeletedHauliersShown
                            ? 'Hide deleted hauliers'
                            : 'Show deleted hauliers',
                        child: _isDeletedHauliersShown
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
                                    'Company Name',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Company Address',
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
                              itemCount: _hauliers.length,
                              itemBuilder: (context, index) {
                                final haulier = _hauliers[index];
                                final isEditing = _editingHaulierId ==
                                    haulier['haulierId'].toString();

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
                                                      : haulier[
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
                                                controller: _companyNameController
                                                  ..text = _companyNameController
                                                          .text.isNotEmpty
                                                      ? _companyNameController
                                                          .text
                                                      : haulier['companyName'],
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Company Name',
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
                                                      : haulier['address'],
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
                                                    haulier[
                                                        'registrationNumber'],
                                                    style: TextStyle(
                                                      color:
                                                          haulier['deleteFlag'] ==
                                                                  0
                                                              ? Colors.black
                                                              : Colors
                                                                  .grey[500],
                                                    )),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                child: Text(
                                                    haulier['companyName'],
                                                    style: TextStyle(
                                                      color:
                                                          haulier['deleteFlag'] ==
                                                                  0
                                                              ? Colors.black
                                                              : Colors
                                                                  .grey[500],
                                                    )),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                child: Text(
                                                    haulier['address']
                                                        .toString(),
                                                    style: TextStyle(
                                                      color:
                                                          haulier['deleteFlag'] ==
                                                                  0
                                                              ? Colors.black
                                                              : Colors
                                                                  .grey[500],
                                                    )),
                                              ),
                                            ],
                                          ),
                                        ),
                                  trailing: haulier['deleteFlag'] == 1
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
                                              tooltip: 'Restore haulier',
                                              onPressed: () async {
                                                final bool shouldRestore =
                                                    await showRestoreConfirmation(
                                                        context,
                                                        'Are you sure you want to restore this haulier?\n\n'
                                                        'Company Name: ${haulier['companyName']}');
                                                if (shouldRestore) {
                                                  _restoreDeletedHaulier(
                                                      haulier['haulierId']);
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
                                                            _updateHaulier(
                                                                haulier[
                                                                    'haulierId']);
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
                                                              _editingHaulierId =
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
                                                      ['canEditHaulier']) {
                                                    return;
                                                  }
                                                  setState(() {
                                                    _editingHaulierId =
                                                        haulier['haulierId']
                                                            .toString();
                                                    _registrationNumberController
                                                            .text =
                                                        haulier[
                                                            'registrationNumber'];
                                                    _companyNameController
                                                            .text =
                                                        haulier['companyName'];
                                                    _addressController.text =
                                                        haulier['address'];
                                                  });
                                                },
                                              ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () async {
                                                if (!currentUser['permissions']
                                                    ['canDeleteHaulier']) {
                                                  return;
                                                }
                                                final shouldDelete =
                                                    await _showDeleteConfirmationDialog(
                                                        haulier['haulierId']
                                                            .toString());
                                                if (shouldDelete) {
                                                  _deleteHaulier(
                                                      haulier['haulierId']);
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
      child: Text('No hauliers available',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Color(0xaa000000),
          )),
    );
  }
}
