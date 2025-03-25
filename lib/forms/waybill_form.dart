import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:pikanto/widgets/file_viewer.dart';
import 'dart:io';

class WaybillForm extends StatefulWidget {
  final Map<String, dynamic> weightRecord;
  final Function(Map<String, dynamic>, int) onSubmit;
  final int recordIndex;
  final bool isUpdate;

  const WaybillForm({
    super.key,
    required this.weightRecord,
    required this.recordIndex,
    required this.onSubmit,
    required this.isUpdate,
  });

  @override
  State createState() => _WaybillFormState();
}

class _WaybillFormState extends State<WaybillForm> {
  final _formKey = GlobalKey<FormState>();
  final _productFormKey = GlobalKey<FormState>();
  final _badProductFormKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> goodProductsList = [];
  List<Map<String, dynamic>> badProductsList = [];
  // add multi-file selector variable
  final List<File> _files = [];
  final List<String?> _filePaths = [];
  final TextEditingController _deliveryAddressController =
      TextEditingController();
  final TextEditingController _productConditionController =
      TextEditingController();
  final TextEditingController _customer = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _waybillNumberController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // file uploader button state tracker
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.isUpdate) {
      // extract waybill info from weightRecord
      final Map<String, dynamic> _waybill =
          Map<String, dynamic>.from(widget.weightRecord['waybillRecord']);

      if (_waybill.isNotEmpty) {
        // extract good and bad products
        final List<Map<String, dynamic>> _goodProducts =
            List<Map<String, dynamic>>.from(_waybill['goodProducts']);
        final List<Map<String, dynamic>> _badProducts =
            List<Map<String, dynamic>>.from(_waybill['badProducts']);

        _deliveryAddressController.text = _waybill['deliveryAddress'];
        _productConditionController.text = _waybill['productCondition'];
        _driverNameController.text = _waybill['driverName'];
        _waybillNumberController.text = _waybill['waybillNumber'];
        _customer.text = widget.weightRecord['customerId'].toString();

        goodProductsList = _goodProducts;
        badProductsList = _badProducts;

        //check if waybill attachments is not empty
        if (widget.weightRecord['waybillRecord']['attachments'] != null) {
          final List<String> _attachments = List<String>.from(
              widget.weightRecord['waybillRecord']['attachments']);
          for (var attachment in _attachments) {
            _filePaths.add('${settingsData["serverUrl"]}/$attachment');
          }
        }
      }
    } else {
      _deliveryAddressController.clear();
      _productConditionController.text = 'Good';
      _driverNameController.text = widget.weightRecord['driverName'];
      _waybillNumberController.clear();
      _customer.text = widget.weightRecord['customerId'].toString();
      _filePaths.clear();
    }
  }

  void showFileViewerDialog(BuildContext context, String? filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            filePath!.split('\\').last,
            style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13.0,
                fontWeight: FontWeight.bold),
            maxLines: 2,
          ),
          content: FileViewer(filePath: filePath),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickFiles() async {
    if (_isUploading) return;
    _isUploading = true;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true, // Enable multiple file selection
      type: FileType.custom, // Allow any file type
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'csv',
        'txt',
        'jpg',
        'jpeg',
        'png'
      ],
    );

    if (result != null) {
      setState(() {
        _files.clear();
        _filePaths.clear();
        _files.addAll(result.paths.map((path) => File(path!)).toList());
        _filePaths.addAll(result.paths);
      });
    }

    _isUploading = false;
  }

  Future<bool> _showDeleteConfirmation(int index, bool isGoodProduct) async {
    final Map<String, dynamic> item =
        isGoodProduct ? goodProductsList[index] : badProductsList[index];
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Confirm Deletion'),
              content: Text(
                  'Are you sure you want to delete this product?\n\n'
                  'Product Description: ${item['productDescription']}',
                  style: TextStyle(color: Colors.grey[800])),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // ensure product list is not empty
      if (goodProductsList.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Product list cannot be empty.";
          });
        }
        return;
      }

      await Future.delayed(
          const Duration(seconds: 2)); // Simulate network delay

      // Construct the new record
      Map<String, dynamic> newRecord = {
        'vehicleId': widget.weightRecord['vehicleId'],
        'customerId': _customer.text.isNotEmpty
            ? int.parse(_customer.text)
            : widget.weightRecord['customerId'],
        'haulierId': widget.weightRecord['haulierId'],
        'driverName': _driverNameController.text,
        'waybillNumber':
            _waybillNumberController.text, // loading request number
        'weightRecordId': widget.weightRecord['weightRecordId'],
        'deliveryAddress': _deliveryAddressController.text,
        'productCondition': _productConditionController.text,
        'goodProducts': goodProductsList,
        'badProducts': badProductsList,
        'preparedBy': currentUser['fullName'] ?? 'WHSE Tech',
      };

      try {
        final response = widget.isUpdate
            ? await http.put(
                Uri.parse(
                    '${settingsData["serverUrl"]}/api/v1/waybill/update_record'),
                headers: {
                  'Content-Type': 'application/json; charset=UTF-8',
                },
                body: jsonEncode(newRecord),
              )
            : await http.post(
                Uri.parse(
                    '${settingsData["serverUrl"]}/api/v1/waybill/add_new'),
                headers: {
                  'Content-Type': 'application/json; charset=UTF-8',
                },
                body: jsonEncode(newRecord),
              );

        // Simulate successful submission
        if (response.statusCode != 200) {
          throw Exception('Failed to submit data');
        } else if (response.statusCode == 200) {
          // get the response body
          final Map<String, dynamic> responseBody = jsonDecode(response.body);
          if (responseBody['status'] != 1) {
            throw Exception(responseBody['message']);
          } else {
            // add the new record to the list of records
            widget.onSubmit(responseBody['data'] as Map<String, dynamic>,
                widget.recordIndex);

            // send uploaded files to backend for storage if any
            if (_files.isNotEmpty) {
              final bool filesUploaded = await sendFileData(
                  _files, responseBody['data']['waybillRecord']['waybillId']);
              if (!filesUploaded) {
                throw Exception('Failed to upload files');
              }
            }
          }
        }

        Navigator.of(context).pop(); // go back to previous page
      } catch (error) {
        setState(() {
          _errorMessage = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  // send uploaded files to backend for storage
  Future<bool> sendFileData(List files, int waybillId) async {
    if (files.isEmpty) return false; // No files to upload

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '${settingsData["serverUrl"]}/api/v1/waybill/upload_files/$waybillId'),
      );

      for (var file in files) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files', // Must match the key in Flask
            file.path!,
          ),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Check if the upload was successful
        final Map<String, dynamic> responseBody = jsonDecode(responseData);
        if (responseBody['status'] != 1) {
          throw Exception(responseBody['message']);
        } else {
          // Files uploaded successfully
          // add the new record to the list of records
          widget.onSubmit(
              responseBody['data'] as Map<String, dynamic>, widget.recordIndex);
          return true;
        }
      } else {
        throw Exception('Failed to upload files');
      }
    } catch (e) {
      // print("Error uploading files: $e");
      return false;
    }
  }

  Future<void> _addGoodProductForm() async {
    final _productDescriptionController = TextEditingController();
    //final _itemCodeController = TextEditingController();
    final _numberOfPackagesController = TextEditingController();
    //final _quantityController = TextEditingController();
    //final _acceptedQuantityController = TextEditingController();
    final _remarksController = TextEditingController();
    // added features to replace some of the text fields.
    final TextEditingController _grossQuantityController =
        TextEditingController(); // to replace quantity
    final TextEditingController _netQuantityController =
        TextEditingController(); // to replace accepted quantity

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Product'),
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          content: Stack(
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
              Form(
                key: _productFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                            hintText: 'Select Product',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            )),
                        value: _productDescriptionController.text.isNotEmpty
                            ? _productDescriptionController.text
                            : null,
                        items: products
                            .where((item) => item['deleteFlag'] == 0)
                            .map((item) {
                          return DropdownMenuItem<String>(
                            value: item['productDescription'],
                            child: Text(item['productDescription']!),
                          );
                        }).toList(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a Product';
                          }
                          return null; // Input is valid
                        },
                        onChanged: (String? newValue) {
                          setState(() {
                            _productDescriptionController.text = newValue ?? '';
                          });
                        },
                      ),
                      //const SizedBox(width: 40),
                      /*TextFormField(
                        controller: _itemCodeController,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                        decoration: const InputDecoration(
                            labelText: 'Item Code',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            )),
                      ),*/
                      TextFormField(
                        controller: _numberOfPackagesController,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                        decoration: const InputDecoration(
                            labelText: 'Number of Packages (Bags/Cartons)',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            )),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null;
                          }

                          if (int.tryParse(value) == null &&
                              double.tryParse(value) == null) {
                            return "only numbers are allowed here.";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _grossQuantityController,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                        decoration: const InputDecoration(
                            labelText: 'Gross Quantity (Kg/MT/NOs)',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            )),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "gross quantity is required";
                          }

                          if (int.tryParse(value) == null &&
                              double.tryParse(value) == null) {
                            return "only numbers are allowed here.";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _netQuantityController,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                        decoration: const InputDecoration(
                            labelText: 'Net Quantity',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            )),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "net quantity is required";
                            // return null;
                          }

                          if (int.tryParse(value) == null &&
                              double.tryParse(value) == null) {
                            return "only numbers are allowed here.";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _remarksController,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                        decoration: const InputDecoration(
                            labelText: 'Remarks',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            SizedBox(width: MediaQuery.of(context).size.width * 0.3),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (_productFormKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  setState(() {
                    _isLoading = true;
                  });
                  await Future.delayed(const Duration(seconds: 2));
                  setState(() {
                    goodProductsList.add({
                      'productDescription': _productDescriptionController.text,
                      // use current date and time as item code
                      'itemCode': DateTime.now().toString(),
                      //'itemCode': ,//_itemCodeController.text,
                      'numberOfPackages': !_numberOfPackagesController
                              .text.isNotEmpty
                          ? _numberOfPackagesController.text
                          : int.tryParse(_numberOfPackagesController.text) !=
                                  null
                              ? int.parse(_numberOfPackagesController.text)
                              : double.parse(_numberOfPackagesController.text),
                      'quantity': 0.0,
                      /*!_quantityController.text.isNotEmpty
                          ? _quantityController.text
                          : int.tryParse(_quantityController.text) != null
                              ? int.parse(_quantityController.text)
                              : double.parse(_quantityController.text),*/
                      'grossQuantity': !_grossQuantityController.text.isNotEmpty
                          ? _grossQuantityController.text
                          : int.tryParse(_grossQuantityController.text) != null
                              ? int.parse(_grossQuantityController.text)
                              : double.parse(_grossQuantityController.text),
                      'netQuantity': !_netQuantityController.text.isNotEmpty
                          ? _netQuantityController.text
                          : int.tryParse(_netQuantityController.text) != null
                              ? int.parse(_netQuantityController.text)
                              : double.parse(_netQuantityController.text),
                      'acceptedQuantity': 0.0,
                      /*!_acceptedQuantityController
                              .text.isNotEmpty
                          ? _acceptedQuantityController.text
                          : int.tryParse(_acceptedQuantityController.text) !=
                                  null
                              ? int.parse(_acceptedQuantityController.text)
                              : double.parse(_acceptedQuantityController.text),*/
                      'remarks': _remarksController.text,
                    });
                    _isLoading = false;
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addBadProductForm() async {
    final _productDescriptionController = TextEditingController();
    final _damagedQuantityController = TextEditingController();
    final _shortageQuantityController = TextEditingController();
    final _batchNumberController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Record Damaged Product'),
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          content: Stack(
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
              Form(
                key: _badProductFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                            hintText: 'Select Product',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            )),
                        value: _productDescriptionController.text.isNotEmpty
                            ? _productDescriptionController.text
                            : null,
                        items: products
                            .where((item) => item['deleteFlag'] == 0)
                            .map((item) {
                          return DropdownMenuItem<String>(
                            value: item['productDescription'],
                            child: Text(item['productDescription']!),
                          );
                        }).toList(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a Product';
                          }
                          return null; // Input is valid
                        },
                        onChanged: (String? newValue) {
                          setState(() {
                            _productDescriptionController.text = newValue ?? '';
                          });
                        },
                      ),
                      TextFormField(
                        controller: _batchNumberController,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                        decoration: const InputDecoration(
                            labelText: 'Batch Number',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            )),
                      ),
                      TextFormField(
                        controller: _damagedQuantityController,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                        decoration: const InputDecoration(
                            labelText: 'Damaged Quantity',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            )),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Damaged quantity is required.";
                          }

                          if (int.tryParse(value) == null &&
                              double.tryParse(value) == null) {
                            return "only numbers are allowed here.";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _shortageQuantityController,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                        decoration: const InputDecoration(
                            labelText: 'Shortage Quantity',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            )),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null;
                          }

                          if (int.tryParse(value) == null &&
                              double.tryParse(value) == null) {
                            return "only numbers are allowed here.";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            SizedBox(width: MediaQuery.of(context).size.width * 0.3),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (_badProductFormKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  setState(() {
                    _isLoading = true;
                  });
                  await Future.delayed(const Duration(seconds: 2));
                  setState(() {
                    badProductsList.add({
                      'productDescription': _productDescriptionController.text,
                      'batchNumber': _batchNumberController.text,
                      'damagedQuantity': _damagedQuantityController.text.isEmpty
                          ? _damagedQuantityController.text
                          : int.tryParse(_damagedQuantityController.text) !=
                                  null
                              ? int.parse(_damagedQuantityController.text)
                              : double.parse(_damagedQuantityController.text),
                      'shortageQuantity': _shortageQuantityController
                              .text.isEmpty
                          ? _shortageQuantityController.text
                          : int.tryParse(_shortageQuantityController.text) !=
                                  null
                              ? int.parse(_shortageQuantityController.text)
                              : double.parse(_shortageQuantityController.text),
                    });
                    _isLoading = false;
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showProductDialog(BuildContext context, bool isGoodProduct) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProductDialog(
          products: isGoodProduct ? goodProductsList : badProductsList,
          onUpdate: (updatedList) {
            if (isGoodProduct) {
              if (mounted) {
                setState(() {
                  goodProductsList = updatedList;
                });
              }
            } else {
              if (mounted) {
                setState(() {
                  badProductsList = updatedList;
                });
              }
            }
          },
          onDelete: _showDeleteConfirmation,
          title: isGoodProduct ? 'Good Products' : 'Bad Products',
          isGoodProduct: isGoodProduct,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //print(widget.weightRecord['waybillRecord']['attachments']);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            color: Colors.grey[100],
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.isUpdate
                            ? 'Update Waybill Data for: ${widget.weightRecord['vehicleId']}'
                            : 'Create New Waybill Data for: ${widget.weightRecord['vehicleId']}',
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
                            SizedBox(
                              child: TextFormField(
                                controller: _waybillNumberController,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                    labelText: 'Loading Request Number',
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.black),
                                    ),
                                    border: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.black),
                                    )),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter laoding request number';
                                  }
                                  return null; // Input is valid
                                },
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                //elevation: 0,
                                decoration: const InputDecoration(
                                    labelText: 'Select Customer',
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.black),
                                    ),
                                    border: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.black),
                                    )),
                                value: _customer.text.isNotEmpty
                                    ? _customer.text
                                    : null,
                                items: customers
                                    .map<DropdownMenuItem<String>>((Map value) {
                                  return DropdownMenuItem<String>(
                                    value: value['customerId'].toString(),
                                    child: Text(value['customerName']!),
                                  );
                                }).toList(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a Customer';
                                  }
                                  return null; // Input is valid
                                },
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _customer.text = newValue ?? '';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              child: TextFormField(
                                controller: _driverNameController,
                                style: const TextStyle(color: Colors.black),
                                readOnly: true,
                                decoration: const InputDecoration(
                                    labelText: 'Driver\'s Name',
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.black),
                                    ),
                                    border: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.black),
                                    )),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the Driver\'s Name';
                                  }
                                  return null; // Input is valid
                                },
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              child: TextFormField(
                                controller: _deliveryAddressController,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                    labelText: 'Delivery Address',
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.black),
                                    ),
                                    border: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.black),
                                    )),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the Delivery Address';
                                  }
                                  return null; // Input is valid
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Container(
                                    height: 60.0,
                                    width: 200.0,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            margin: const EdgeInsets.all(2.0),
                                            child: Column(children: [
                                              Expanded(
                                                child: Container(
                                                  width: double.infinity,
                                                  alignment: Alignment.center,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  margin:
                                                      const EdgeInsets.all(2.0),
                                                  child: Text(
                                                    'Products [${goodProductsList.length}]',
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onPrimary),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                  child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.remove_red_eye,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      size: 15.0,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(
                                                      maxHeight: 30.0,
                                                      maxWidth: 30.0,
                                                    ),
                                                    hoverColor:
                                                        Colors.grey[200],
                                                    tooltip: 'view poduct list',
                                                    onPressed: () {
                                                      _showProductDialog(
                                                          context, true);
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.add,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      size: 15.0,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(
                                                      maxHeight: 30.0,
                                                      maxWidth: 30.0,
                                                    ),
                                                    hoverColor:
                                                        Colors.grey[200],
                                                    tooltip: 'add poduct',
                                                    onPressed:
                                                        _addGoodProductForm,
                                                  ),
                                                ],
                                              )),
                                            ]),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            margin: const EdgeInsets.all(2.0),
                                            child: Column(children: [
                                              Expanded(
                                                child: Container(
                                                  width: double.infinity,
                                                  alignment: Alignment.center,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  margin:
                                                      const EdgeInsets.all(2.0),
                                                  child: Text(
                                                    'Damages [${badProductsList.length}]',
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onPrimary),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                  child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.remove_red_eye,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      size: 15.0,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(
                                                      maxHeight: 30.0,
                                                      maxWidth: 30.0,
                                                    ),
                                                    hoverColor:
                                                        Colors.grey[200],
                                                    tooltip:
                                                        'view damaged poduct list',
                                                    onPressed: () {
                                                      _showProductDialog(
                                                          context, false);
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.add,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      size: 15.0,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(
                                                      maxHeight: 30.0,
                                                      maxWidth: 30.0,
                                                    ),
                                                    hoverColor:
                                                        Colors.grey[200],
                                                    tooltip:
                                                        'record damaged product',
                                                    onPressed:
                                                        _addBadProductForm,
                                                  ),
                                                ],
                                              )),
                                            ]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5.0,
                                  ),
                                  // this next box will contain the file upload widget.
                                  // upload button appear at the bottom while uploaded files appear at the top in a row or column depending on the screen width.
                                  Expanded(
                                    child: Container(
                                      height: 120.0,
                                      width: double.infinity,
                                      color: Colors.white,
                                      margin: const EdgeInsets.all(2.0),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              width: double.infinity,
                                              //alignment: Alignment.center,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              margin: const EdgeInsets.all(2.0),
                                              child: _filePaths.isEmpty
                                                  ? Text(
                                                      'No files uploaded',
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                    )
                                                  : SingleChildScrollView(
                                                      scrollDirection: Axis
                                                          .horizontal, // Enable horizontal scrolling
                                                      child: Row(
                                                        children: _filePaths
                                                            .map((file) {
                                                          return Container(
                                                            width:
                                                                60, // Adjust width as needed
                                                            margin:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        5.0),
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(5.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              boxShadow: const [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black12,
                                                                  blurRadius: 4,
                                                                  spreadRadius:
                                                                      2,
                                                                ),
                                                              ],
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                MouseRegion(
                                                                  cursor:
                                                                      SystemMouseCursors
                                                                          .click,
                                                                  child:
                                                                      GestureDetector(
                                                                    onTap: () {
                                                                      showFileViewerDialog(
                                                                          context,
                                                                          file);
                                                                    },
                                                                    child: const Icon(
                                                                        Icons
                                                                            .insert_drive_file,
                                                                        size:
                                                                            15,
                                                                        color: Colors
                                                                            .blue),
                                                                  ),
                                                                ), // File icon
                                                                const SizedBox(
                                                                    height: 5),
                                                                Text(
                                                                  file!
                                                                      .split(
                                                                          '\\')
                                                                      .last, // File name
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: const TextStyle(
                                                                      color: Colors
                                                                          .black,
                                                                      fontSize:
                                                                          8,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  maxLines: 2,
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),

                                                                SizedBox(
                                                                  height: 15,
                                                                  child:
                                                                      IconButton(
                                                                    onPressed:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        _filePaths
                                                                            .remove(file); // Remove file
                                                                        _files.removeWhere((element) =>
                                                                            element.path ==
                                                                            file);
                                                                      });
                                                                    },
                                                                    tooltip:
                                                                        'Delete ${file.split("\\").last}',
                                                                    splashRadius:
                                                                        8,
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .delete,
                                                                        size:
                                                                            8),
                                                                    style: ElevatedButton
                                                                        .styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red,
                                                                      foregroundColor:
                                                                          Colors
                                                                              .white,
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              4,
                                                                          vertical:
                                                                              4),
                                                                      textStyle:
                                                                          const TextStyle(
                                                                              fontSize: 8),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          _isUploading
                                              ? const SizedBox(
                                                  height: 30.0,
                                                  width: 30.0,
                                                  child:
                                                      CircularProgressIndicator())
                                              : Container(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  height: 30.0,
                                                  width: double.infinity,
                                                  child: TextButton.icon(
                                                    icon: Icon(
                                                      Icons.add,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimary,
                                                      size: 15.0,
                                                    ),
                                                    label: Text(
                                                      'Upload Files',
                                                      style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimary),
                                                    ),
                                                    onPressed: _pickFiles,
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 40),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
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
                              child:
                                  Text(widget.isUpdate ? 'Update' : 'Create'),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget to display the products
class ProductDialog extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Function(List<Map<String, dynamic>>) onUpdate;
  final Function(int, bool) onDelete;
  final String title;
  final bool isGoodProduct;

  const ProductDialog({
    super.key,
    required this.products,
    required this.onUpdate,
    required this.onDelete,
    required this.title,
    required this.isGoodProduct,
  });

  @override
  State createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  void _deleteProduct(int index) {
    setState(() {
      widget.products.removeAt(index);
    });
    widget.onUpdate(widget.products);
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
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                  const SizedBox(height: 16),
                  Table(
                    //border: TableBorder.all(),
                    columnWidths: {
                      0: const FlexColumnWidth(2),
                      1: const FlexColumnWidth(1),
                      2: const FlexColumnWidth(1),
                      3: const FlexColumnWidth(1),
                      if (widget.isGoodProduct) 4: const FlexColumnWidth(1),
                      if (widget.isGoodProduct) 5: const FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                        ),
                        children: widget.isGoodProduct
                            ? [
                                _buildHeader('Description'),
                                _buildHeader('Item Code'),
                                _buildHeader('No. of Packages'),
                                _buildHeader('Gross Quantity'),
                                _buildHeader('Net Quantity'),
                                _buildHeader('Remarks'),
                                _buildHeader('Actions'),
                              ]
                            : [
                                _buildHeader('Description'),
                                _buildHeader('Damaged Quantity'),
                                _buildHeader('Shortage Quantity'),
                                _buildHeader('Batch Number'),
                                _buildHeader('Actions'),
                              ],
                      ),
                      for (int i = 0; i < widget.products.length; i++)
                        TableRow(
                          decoration: BoxDecoration(
                            color: i.isEven ? Colors.grey[100] : Colors.white,
                          ),
                          children: [
                            _buildCell(
                                widget.products[i]['productDescription']),
                            _buildCell(widget.isGoodProduct
                                ? widget.products[i]['itemCode']
                                : widget.products[i]['damagedQuantity']),
                            _buildCell(widget.isGoodProduct
                                ? widget.products[i]['numberOfPackages']
                                : widget.products[i]['shortageQuantity']),
                            _buildCell(widget.isGoodProduct
                                ? widget.products[i]['grossQuantity'] ?? 0.0
                                : widget.products[i]['batchNumber']),
                            if (widget.isGoodProduct)
                              _buildCell(
                                  widget.products[i]['netQuantity'] ?? 0.0),
                            if (widget.isGoodProduct)
                              _buildCell(widget.products[i]['remarks']),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              constraints: const BoxConstraints(
                                maxHeight: 40.0,
                                maxWidth: 40.0,
                              ),
                              onPressed: () async {
                                final shouldDelete = await widget.onDelete(
                                    i, widget.isGoodProduct);
                                if (shouldDelete) {
                                  _deleteProduct(i);
                                }
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[800], //Theme.of(context).colorScheme.primary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCell(dynamic text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        '${text ?? ""}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
        ),
      ),
    );
  }
}
