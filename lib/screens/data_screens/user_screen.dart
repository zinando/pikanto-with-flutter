import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/helpers/my_functions.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});
  @override
  State createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _adminTypeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String selectedAdminType = "user";

  bool _isLoading =
      false; // shows when page is loading data from database as user visits the screen
  bool _isEmptyList = true;
  bool _isEditLoading = false; // shows during edit operation
  bool _isDeletedUsersShown = false;
  bool _isRestoring = false;
  String? _editingUserId;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
          Uri.parse('${settingsData['serverUrl']}/api/v1/user/fetch_users'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          if (mounted) {
            setState(() {
              final allUsers =
                  List<Map<String, dynamic>>.from(responseBody['data']);
              _users = allUsers
                  .where((testUser) => testUser['deleteFlag'] == 0)
                  .toList();
              //update list of users
              users = allUsers;
              _isEmptyList = _users.isEmpty;
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

  Future<void> _updateUser(int userId) async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty) {
      MyFunctions.showSnackBar(context, 'All fields are required.');
      return;
    }

    // validate email: ensure email contains "@" and "."
    if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      MyFunctions.showSnackBar(
          context, 'Not a valid email. Please change the email and try again.');
      return;
    }

    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final email = _emailController.text;
    final adminType = selectedAdminType;
    setState(() {
      _isEditLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    try {
      final response = await http.put(
        Uri.parse('${settingsData["serverUrl"]}/api/v1/user/edit_user_data'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'userId': userId,
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'adminType': adminType,
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
            List<Map<String, dynamic>> customers =
                List<Map<String, dynamic>>.from(responseBody['data']);
            setState(() {
              _users = customers
                  .where((testUser) => testUser['deleteFlag'] == 0)
                  .toList();
              // update list of users
              users = customers;
              _editingUserId = null;
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

  Future<void> _deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${settingsData["serverUrl"]}/api/v1/user/delete_user'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'userId': userId,
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
              _users = newList
                  .where((testUser) => testUser['deleteFlag'] == 0)
                  .toList();
              //update users list
              users = newList;
              _isDeletedUsersShown = false;
              _isEmptyList = _users.isEmpty;
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

  Future<void> _restoreDeletedUser(int userId) async {
    setState(() {
      _isRestoring = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    try {
      final response = await http.put(
        Uri.parse(
            '${settingsData["serverUrl"]}/api/v1/user/restore_deleted_user'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'userId': userId,
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
              _users = newList;
              //update users list
              users = newList;
              _isEmptyList = _users.isEmpty;
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
      setState(() {
        _isRestoring = false;
      });
      MyFunctions.showSnackBar(context, 'An error occurred: $e');
    }
  }

  Future<bool> _showDeleteConfirmationDialog(String userId) async {
    final Map<String, dynamic> user = _users.firstWhere(
        (user) => user['userId'].toString() == userId,
        orElse: () => <String, dynamic>{}); // Return an empty map if not found
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Confirm Deletion'),
              content: user.isNotEmpty
                  ? Text(
                      'Are you sure you want to delete this user?\n\n'
                      'User name: ${user['firstName']} ${user['lastName']}'
                      '\n'
                      'User email ${user['email']}',
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
                user.isNotEmpty
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

  void _revealAddUserDialog() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _adminTypeController.clear();
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AddUserDialog(
          onAddUser: _addUserToList,
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          emailController: _emailController,
          adminTypeController: _adminTypeController,
        );
      },
    );
  }

  void _addUserToList(Map<String, dynamic> user) {
    setState(() {
      _users.insert(0, user);
      users.insert(0, user);
    });
  }

  void _toggleDeletedUsers() {
    if (_isDeletedUsersShown) {
      setState(() {
        _users =
            users.where((testUser) => testUser['deleteFlag'] == 0).toList();
        _isEmptyList = _users.isEmpty;
      });
    } else {
      setState(() {
        _users = users;
        _isEmptyList = _users.isEmpty;
      });
    }
    setState(() {
      _isDeletedUsersShown = !_isDeletedUsersShown;
    });
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
                'Users',
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
                      onPressed: currentUser['permissions']['canAddUser']
                          ? _revealAddUserDialog
                          : null,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      mini: true,
                      tooltip: 'Add user',
                      child: const Icon(Icons.add),
                    ),
                    if (currentUser['permissions']['canDeleteUser']) ...[
                      const SizedBox(width: 8.0),
                      FloatingActionButton(
                        onPressed: _toggleDeletedUsers,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        mini: true,
                        tooltip: _isDeletedUsersShown
                            ? 'Hide deleted users'
                            : 'Show deleted users',
                        child: _isDeletedUsersShown
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
                                    'First Name',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Last Name',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Admin Type',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Email',
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
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                final isEditing =
                                    _editingUserId == user['userId'].toString();

                                return ListTile(
                                  title: isEditing
                                      ? Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: _firstNameController
                                                  ..text = _firstNameController
                                                          .text.isNotEmpty
                                                      ? _firstNameController
                                                          .text
                                                      : user['firstName'],
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'First Name',
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
                                                controller: _lastNameController
                                                  ..text = _lastNameController
                                                          .text.isNotEmpty
                                                      ? _lastNameController.text
                                                      : user['lastName'],
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Last Name',
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
                                              child: DropdownButtonFormField<
                                                  String>(
                                                value: user['adminType'],
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Admin Type',
                                                  enabledBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.grey),
                                                  ),
                                                ),
                                                items: const [
                                                  DropdownMenuItem(
                                                    value: 'admin',
                                                    child: Text('Admin'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'super',
                                                    child: Text('Super Admin'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'user',
                                                    child: Text('User'),
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  setState(() {
                                                    selectedAdminType = value!;
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8.0),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _emailController
                                                  ..text = _emailController
                                                          .text.isNotEmpty
                                                      ? _emailController.text
                                                      : user['email'],
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Email',
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
                                                child: Text(user['firstName'],
                                                    style: TextStyle(
                                                      color:
                                                          user['deleteFlag'] ==
                                                                  0
                                                              ? Colors.black
                                                              : Colors
                                                                  .grey[500],
                                                    )),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                child: Text(user['lastName'],
                                                    style: TextStyle(
                                                      color:
                                                          user['deleteFlag'] ==
                                                                  0
                                                              ? Colors.black
                                                              : Colors
                                                                  .grey[500],
                                                    )),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                child: Text(user['adminType'],
                                                    style: TextStyle(
                                                      color:
                                                          user['deleteFlag'] ==
                                                                  0
                                                              ? Colors.black
                                                              : Colors
                                                                  .grey[500],
                                                    )),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                child: Text(user['email'],
                                                    style: TextStyle(
                                                      color:
                                                          user['deleteFlag'] ==
                                                                  0
                                                              ? Colors.black
                                                              : Colors
                                                                  .grey[500],
                                                    )),
                                              )
                                            ],
                                          ),
                                        ),
                                  trailing: user['deleteFlag'] == 1
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
                                              tooltip: 'Restore user',
                                              onPressed: () async {
                                                final bool shouldRestore =
                                                    await showRestoreConfirmation(
                                                        context,
                                                        'Are you sure you want to restore this user?\n\n'
                                                        'User name: ${user['firstName']} ${user['lastName']}');
                                                if (shouldRestore) {
                                                  _restoreDeletedUser(
                                                      user['userId']);
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
                                                            _updateUser(
                                                                user['userId']);
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
                                                              _editingUserId =
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
                                                      ['canEditUser']) {
                                                    return;
                                                  }
                                                  setState(() {
                                                    _editingUserId =
                                                        user['userId']
                                                            .toString();
                                                    _firstNameController.text =
                                                        user['firstName'];
                                                    _lastNameController.text =
                                                        user['lastName'];
                                                    _adminTypeController.text =
                                                        user['adminType'];

                                                    _emailController.text =
                                                        user['email'];
                                                  });
                                                },
                                              ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () async {
                                                if (!currentUser['permissions']
                                                    ['canDeleteUser']) {
                                                  return;
                                                }
                                                final shouldDelete =
                                                    await _showDeleteConfirmationDialog(
                                                        user['userId']
                                                            .toString());
                                                if (shouldDelete) {
                                                  _deleteUser(user['userId']);
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
      child: Text('No users available',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Color(0xaa000000),
          )),
    );
  }
}

class AddUserDialog extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAddUser;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController adminTypeController;
  final TextEditingController emailController;

  const AddUserDialog({
    super.key,
    required this.onAddUser,
    required this.firstNameController,
    required this.lastNameController,
    required this.adminTypeController,
    required this.emailController,
  });

  @override
  State createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController =
      TextEditingController();
  String selectedAdminType = 'user';
  bool isAddLoading = false;
  String errorMessage = '';

  Future<void> _addUser() async {
    setState(() {
      errorMessage = '';
    });

    if (widget.firstNameController.text.isEmpty ||
        widget.lastNameController.text.isEmpty ||
        widget.emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        errorMessage = 'All fields are required.';
      });
      return;
    }
    // validate email: ensure email contains "@" and "."
    if (!widget.emailController.text.contains('@') ||
        !widget.emailController.text.contains('.')) {
      setState(() {
        errorMessage =
            'Not a valid email. Please change the email and try again.';
      });
      return;
    }
    // validate password: ensure the two passwords match
    if (passwordController.text != repeatPasswordController.text) {
      setState(() {
        errorMessage = "passwords do not match.";
      });
      return;
    }

    setState(() {
      isAddLoading = true;
    });

    final firstName = widget.firstNameController.text;
    final lastName = widget.lastNameController.text;
    final adminType = selectedAdminType;
    final email = widget.emailController.text;
    final password = passwordController.text;

    await Future.delayed(const Duration(seconds: 2));

    try {
      final response = await http.post(
        Uri.parse('${settingsData['serverUrl']}/api/v1/user/save_data'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'firstName': firstName,
          'lastName': lastName,
          'adminType': adminType,
          'email': email,
          'password': password,
          'actor': currentUser,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody =
            Map<String, dynamic>.from(json.decode(response.body));
        if (responseBody['status'] == 1) {
          if (mounted) {
            widget.onAddUser(responseBody['data']);
            Navigator.of(context).pop();
          }
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception('Server error.');
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
        vertical: MediaQuery.of(context).size.height * 0.15,
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
                  'Add New User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff000000),
                  ),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: widget.firstNameController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                        TextField(
                          controller: widget.lastNameController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: selectedAdminType,
                          decoration: const InputDecoration(
                            labelText: 'Admin Type',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'super',
                              child: Text('Super Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'user',
                              child: Text('User'),
                            ),
                            DropdownMenuItem(
                              value: 'approver',
                              child: Text('Approver'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedAdminType = value!;
                            });
                          },
                        ),
                        TextField(
                          controller: widget.emailController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          obscuringCharacter: "x",
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                        TextField(
                          controller: repeatPasswordController,
                          obscureText: true,
                          obscuringCharacter: "x",
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Repeat Password',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        height: 80.0,
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: Text(
                          errorMessage,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
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
            bottom: 20,
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
                        onPressed: _addUser,
                        child: const Text('Add User'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
