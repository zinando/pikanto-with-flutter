import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/helpers/my_functions.dart';

class PermissionsWidget extends StatefulWidget {
  const PermissionsWidget({super.key});

  @override
  State createState() => _PermissionsWidgetState();
}

class _PermissionsWidgetState extends State<PermissionsWidget> {
  List<Map<String, dynamic>> userPermissions = [];
  final List<String> userTypes = ['user', 'admin', 'super', 'approver'];
  Map<String, dynamic>? selectedPermissions;
  String selectedUserType = 'user';
  bool isLoading = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchUserPermissions();
  }

  Future<void> fetchUserPermissions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            '${settingsData['serverUrl']}/api/v1/fetch_resources/user_permissions'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          setState(() {
            userPermissions =
                List<Map<String, dynamic>>.from(responseBody['data']);
            isLoading = false;
          });
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      MyFunctions.showSnackBar(context, e.toString());
    }
  }

  Future<void> savePermissions() async {
    setState(() {
      isSaving = true;
    });
    try {
      final response = await http.put(
        Uri.parse(
            '${settingsData['serverUrl']}/api/v1/user/edit_user_permission'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'permissionTitle': selectedUserType,
          'permissions': selectedPermissions!['permissions'],
          'actor': currentUser,
        }),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          setState(() {
            isSaving = false;
          });
          MyFunctions.showSnackBar(
              context, 'Permissions updated successfully!');
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception('Failed to update permissions: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      MyFunctions.showSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    selectedPermissions = userPermissions.isNotEmpty
        ? userPermissions.firstWhere(
            (element) => element['permissionTitle'] == selectedUserType,
            orElse: () => <String, dynamic>{}) // empty map if not found
        : <String, dynamic>{};
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Dropdown to select user type
                SizedBox(
                  width: 300.0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      elevation: 4.0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            16.0), // Optional: round the corners
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButton<String>(
                          value: selectedUserType,
                          items: userTypes.map((String userType) {
                            return DropdownMenuItem<String>(
                              value: userType,
                              child: Text(userType),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedUserType = newValue!;
                            });
                          },
                          isExpanded: true,
                          underline: Container(),
                          dropdownColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Permissions list
                selectedPermissions != null && selectedPermissions!.isNotEmpty
                    ? Container(
                        width: 450.0,
                        height: MediaQuery.of(context).size.height * 0.44,
                        color: Colors.white,
                        child: ListView(
                          children: selectedPermissions!['permissions']
                              .keys
                              .map<Widget>((permission) {
                            //print(permission);
                            //print(selectedPermissions);
                            return SwitchListTile(
                              activeColor:
                                  Theme.of(context).colorScheme.tertiary,
                              inactiveThumbColor: Colors.grey[600],
                              inactiveTrackColor: Colors.grey[200],
                              splashRadius: 15.0,
                              title: Text(permission),
                              value: selectedPermissions!['permissions']
                                  [permission]!,
                              onChanged: (dynamic newValue) {
                                setState(() {
                                  selectedPermissions!['permissions']
                                      [permission] = newValue;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      )
                    : const Expanded(
                        child: Center(
                          child: Text('No permissions available'),
                        ),
                      ),

                // Save button
                isSaving
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : currentUser['permissions']['canEditAppSettings']
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: savePermissions,
                              child: const Text('Save'),
                            ),
                          )
                        : const SizedBox(),
              ],
            ),
    );
  }
}
