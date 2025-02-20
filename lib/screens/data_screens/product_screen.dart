//import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pikanto/helpers/my_functions.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/forms/add_product_form.dart';

class ProductListWidget extends StatefulWidget {
  const ProductListWidget({super.key});

  @override
  State createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<ProductListWidget> {
  List<Map<String, dynamic>> _products = [];
  String? _editingProductId;

  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _productDescriptionController =
      TextEditingController();
  final TextEditingController _countPerCaseController = TextEditingController();
  final TextEditingController _weightPerCountController =
      TextEditingController();
  bool _isLoading = true;
  bool _isEmptyList = false;
  bool _isEditLoading = false;
  bool _isDeletedProductsShown = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(
          '${settingsData['serverUrl']}/api/v1/product/fetch_products'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        if (responseBody['status'] == 1) {
          if (mounted) {
            if (responseBody['data'].isEmpty) {
              setState(() {
                _isEmptyList = true;
                _isLoading = false;
              });
            } else {
              List<Map<String, dynamic>> data =
                  List<Map<String, dynamic>>.from(responseBody['data']);

              _products =
                  data.where((product) => product['deleteFlag'] == 0).toList();
              products = data;
              setState(() {
                _isLoading = false;
                _isEmptyList = false;
              });
            }
          }
        } else {
          // Handle server errors
          setState(() {
            _isLoading = false;
            _isEmptyList = true;
          });
        }
      } else {
        // Handle server errors
        setState(() {
          _isLoading = false;
          _isEmptyList = true;
        });
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors
      setState(() {
        _isLoading = false;
        _isEmptyList = true;
      });
      MyFunctions.showSnackBar(context, e.toString());
    }
  }

  Future<void> _deleteProduct(int productId) async {
    // Implement API call to delete the product
    try {
      final response = await http.delete(
        Uri.parse('${settingsData['serverUrl']}/api/v1/product/delete_product'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'productId': productId,
          'actor': currentUser,
        }),
      );

      setState(() {
        _isLoading = false;
      });
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          if (mounted) {
            _products
                .removeWhere((product) => product['productId'] == productId);
            products.firstWhere(
                (test) => test['productId'] == productId)['deleteFlag'] = 1;

            setState(() {
              _isEmptyList = _products.isEmpty;
              _isDeletedProductsShown = false;
            });
          }
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        // Handle server errors
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors
      setState(() {
        _isLoading = false;
      });
      MyFunctions.showSnackBar(context, e.toString());
    }
  }

  Future<void> _restoreDeletedProduct(int productId) async {
    setState(() {
      _isRestoring = true;
    });
    await Future.delayed(const Duration(seconds: 2));

    // Implement API call to restore the product
    try {
      final response = await http.put(
        Uri.parse(
            '${settingsData['serverUrl']}/api/v1/product/restore_deleted_product'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'productId': productId,
          'actor': currentUser,
        }),
      );

      setState(() {
        _isLoading = false;
      });
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          if (mounted) {
            products.firstWhere(
                (test) => test['productId'] == productId)['deleteFlag'] = 0;
            _products = products;

            setState(() {
              _isEmptyList = _products.isEmpty;
              _isRestoring = false;
            });
          }
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        // Handle server errors
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors
      setState(() {
        _isRestoring = false;
      });
      MyFunctions.showSnackBar(context, e.toString());
    }
  }

  Future<void> _updateProduct(int productId) async {
    // Check if productCode and productDescription are not empty
    if (_productCodeController.text.isEmpty) {
      MyFunctions.showSnackBar(context, 'Product Code cannot be empty');
      return;
    }
    if (_productDescriptionController.text.isEmpty) {
      MyFunctions.showSnackBar(context, 'Product Description cannot be empty');
      return;
    }
    final productIndex =
        _products.indexWhere((product) => product['productId'] == productId);
    if (productIndex != -1) {
      _products[productIndex]['productCode'] = _productCodeController.text;
      _products[productIndex]['productDescription'] =
          _productDescriptionController.text;
      _products[productIndex]['countPerCase'] =
          (_countPerCaseController.text.isEmpty ||
                  _countPerCaseController.text == 'null')
              ? null
              : int.parse(_countPerCaseController.text);
      _products[productIndex]['weightPerCount'] =
          (_weightPerCountController.text.isEmpty ||
                  _weightPerCountController.text == 'null')
              ? null
              : int.parse(_weightPerCountController.text);
      _products[productIndex]['actor'] = currentUser;

      setState(() {
        _isEditLoading = true;
      });
      await Future.delayed(const Duration(seconds: 2));

      // Make api call here
      try {
        final response = await http.put(
            Uri.parse(
                '${settingsData['serverUrl']}/api/v1/product/update_product'),
            headers: <String, String>{
              "Content-Type": "application/json; charset=UTF-8"
            },
            body: jsonEncode(_products[productIndex]));
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseBody = json.decode(response.body);
          if (responseBody['status'] == 1) {
            final List<Map<String, dynamic>> updatedList =
                List<Map<String, dynamic>>.from(responseBody['data']);
            _products = updatedList
                .where((product) => product['deleteFlag'] == 0)
                .toList();
            products = updatedList;
          } else {
            throw Exception(responseBody['message']);
          }
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      } catch (e) {
        // Handle error
        MyFunctions.showSnackBar(context, 'an error occurred: $e');
      }
    }

    setState(() {
      _editingProductId = null;
      _isEditLoading = false;
    });
  }

  Future<bool> _showDeleteConfirmationDialog(String productId) async {
    final Map<String, dynamic> product = _products.firstWhere(
        (product) => product['productId'].toString() == productId,
        orElse: () => <String, dynamic>{}); // Return an empty map if not found
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Confirm Deletion'),
              content: product.isNotEmpty
                  ? Text(
                      'Are you sure you want to delete this product?\n\n'
                      'Product Code: ${product['productCode']}\n'
                      'Description: ${product['productDescription']}',
                      style: TextStyle(color: Colors.grey[800]))
                  : Text(
                      'You cannot delete this product because it does not have productid.',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                product.isNotEmpty
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

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddProductForm(
          onAddProduct: _addProductToList,
        );
      },
    );
  }

  void _addProductToList(Map<String, dynamic> product) {
    setState(() {
      _products.insert(0, product);
      products.insert(0, product);
    });
  }

  void _toggleDeletedProducts() {
    if (_isDeletedProductsShown) {
      setState(() {
        _products = products
            .where((testProduct) => testProduct['deleteFlag'] == 0)
            .toList();
        _isEmptyList = _products.isEmpty;
      });
    } else {
      setState(() {
        _products = products;
        _isEmptyList = _products.isEmpty;
      });
    }
    setState(() {
      _isDeletedProductsShown = !_isDeletedProductsShown;
    });
  }

  // Create a function that returns a Text showing that the list is empty
  Widget _buildEmptyList() {
    return const Center(
      child: Text(
        'No products found',
        style: TextStyle(
          color: Color(0xff000000), //Theme.of(context).colorScheme.secondary,
          fontSize: 24.0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    //_nameController.dispose();
    _productCodeController.dispose();
    _productDescriptionController.dispose();
    _countPerCaseController.dispose();
    _weightPerCountController.dispose();
    //_customerController.dispose();
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
              //add screen title
              const Text("Product List",
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff000000),
                  )),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  children: [
                    FloatingActionButton(
                      onPressed: currentUser['permissions']['canAddProduct']
                          ? _showAddProductDialog
                          : null,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      mini: true,
                      tooltip: 'Add product',
                      child: const Icon(Icons.add),
                    ),
                    if (currentUser['permissions']['canDeleteProduct']) ...[
                      const SizedBox(width: 8.0),
                      FloatingActionButton(
                        onPressed: _toggleDeletedProducts,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        mini: true,
                        tooltip: _isDeletedProductsShown
                            ? 'Hide deleted products'
                            : 'Show deleted products',
                        child: _isDeletedProductsShown
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
                                    'Product Code',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Description',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Count Per Case',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Weight Per Count',
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
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                final product = _products[index];
                                final isEditing = _editingProductId ==
                                    product['productId'].toString();

                                return ListTile(
                                  title: isEditing
                                      ? Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller:
                                                    _productCodeController
                                                      ..text = product[
                                                          'productCode'],
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Product Code',
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
                                                controller:
                                                    _productDescriptionController
                                                      ..text = product[
                                                          'productDescription'],
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Description',
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
                                                controller:
                                                    _countPerCaseController
                                                      ..text = product[
                                                              'countPerCase']
                                                          .toString(),
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Count Per Case',
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
                                                controller:
                                                    _weightPerCountController
                                                      ..text = product[
                                                              'weightPerCount']
                                                          .toString(),
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Weight Per Count',
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
                                                      product['productCode'],
                                                      style: TextStyle(
                                                        color:
                                                            product['deleteFlag'] ==
                                                                    0
                                                                ? Colors.black
                                                                : Colors
                                                                    .grey[500],
                                                      ))),
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                  child: Text(
                                                product['productDescription'],
                                                style: TextStyle(
                                                  color:
                                                      product['deleteFlag'] == 0
                                                          ? Colors.black
                                                          : Colors.grey[500],
                                                ),
                                              )),
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                  child: Text(
                                                product['countPerCase']
                                                    .toString(),
                                                style: TextStyle(
                                                  color:
                                                      product['deleteFlag'] == 0
                                                          ? Colors.black
                                                          : Colors.grey[500],
                                                ),
                                              )),
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                  child: Text(
                                                product['weightPerCount']
                                                    .toString(),
                                                style: TextStyle(
                                                  color:
                                                      product['deleteFlag'] == 0
                                                          ? Colors.black
                                                          : Colors.grey[500],
                                                ),
                                              )),
                                            ],
                                          ),
                                        ),
                                  trailing: product['deleteFlag'] == 1
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
                                              tooltip: 'Restore product',
                                              onPressed: () async {
                                                final bool shouldRestore =
                                                    await showRestoreConfirmation(
                                                        context,
                                                        'Are you sure you want to restore this product?\n\n'
                                                        'Product description: ${product['productDescription']}');
                                                if (shouldRestore) {
                                                  _restoreDeletedProduct(
                                                      product['productId']);
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
                                                            _updateProduct(
                                                                product[
                                                                    'productId']);
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
                                                              _editingProductId =
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
                                                      ['canEditProduct']) {
                                                    return;
                                                  }
                                                  setState(() {
                                                    _editingProductId =
                                                        product['productId']
                                                            .toString();
                                                    _productCodeController
                                                            .text =
                                                        product['productCode'];
                                                    _productDescriptionController
                                                            .text =
                                                        product[
                                                            'productDescription'];
                                                    _countPerCaseController
                                                            .text =
                                                        product['countPerCase']
                                                            .toString();
                                                    _weightPerCountController
                                                        .text = product[
                                                            'weightPerCount']
                                                        .toString();
                                                  });
                                                },
                                              ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () async {
                                                if (!currentUser['permissions']
                                                    ['canDeleteProduct']) {
                                                  return;
                                                }
                                                final shouldDelete =
                                                    await _showDeleteConfirmationDialog(
                                                        product['productId']
                                                            .toString());
                                                if (shouldDelete) {
                                                  _deleteProduct(
                                                      product['productId']);
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
}
