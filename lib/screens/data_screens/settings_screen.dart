import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/helpers/my_functions.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final SocketManager socketManager = SocketManager();
  bool _isSaving = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();
  File? _waybillHeaderImage;
  File? _ticketHeaderImage;

  // Controllers for form fields
  final TextEditingController _scalePortController = TextEditingController();
  final TextEditingController _scaleBaudRateController =
      TextEditingController();
  final TextEditingController _scaleTimeoutController = TextEditingController();
  final TextEditingController _emailTriggerUrlController =
      TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _scaleUnitController = TextEditingController();
  final TextEditingController _companyIdController = TextEditingController();
  final TextEditingController _preTextController = TextEditingController();
  final TextEditingController _postTextController = TextEditingController();
  final TextEditingController _pikantoEmailTokenController =
      TextEditingController();
  final TextEditingController _pikantoEmailSenderController =
      TextEditingController();

  //String? _ticketHeaderImagePath;
  //String? _waybillHeaderImagePath;
  String? _selectedDataBits;
  String? _selectedParity;
  String? _selectedStopBits;
  String? _selectedTheme;

  final Map<String, int> appTheme = {
    'brickRedTheme': 0,
    'lightBlueTheme': 1,
    'lemonGreenTheme': 2,
  };

  @override
  void initState() {
    super.initState();
    // Initialize with current settings data
    _scalePortController.text = settingsData['scalePort'];
    _scaleBaudRateController.text = settingsData['scaleBaudRate'].toString();
    _scaleTimeoutController.text = settingsData['scaleTimeout'].toString();
    _emailTriggerUrlController.text = settingsData['emailTriggerUrl'] ?? '';
    _serverUrlController.text = settingsData['serverUrl'];
    _selectedDataBits = settingsData['scaleDataBits'].toString();
    _selectedParity = settingsData['scaleParity'];
    _selectedStopBits = settingsData['scaleStopBits'].toString();
    _scaleUnitController.text = settingsData['scaleWeightUnit'];
    _companyIdController.text = settingsData['companyId'].toString();
    _selectedTheme = settingsData['appTheme'].toString();
    _preTextController.text = settingsData['preText'].toString();
    _postTextController.text = settingsData['postText'].toString();
    _pikantoEmailSenderController.text =
        settingsData['pikantoEmailSender'] ?? "";
    _pikantoEmailTokenController.text = settingsData['pikantoEmailToken'] ?? "";

    // Initialize the image from existing settings
    if (settingsData['waybillHeaderImage'] != null) {
      _waybillHeaderImage = File(settingsData['waybillHeaderImage']);
    }
    if (settingsData['ticketHeaderImage'] != null) {
      _ticketHeaderImage = File(settingsData['ticketHeaderImage']);
    }
  }

  Future<bool> _validateServerUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      await Future.delayed(const Duration(seconds: 2));

      try {
        // Validate the server URL
        if (!await _validateServerUrl(_serverUrlController.text)) {
          throw Exception('Invalid server URL');
        }

        // Save the settings data
        settingsData['scalePort'] = _scalePortController.text;
        settingsData['scaleBaudRate'] =
            int.parse(_scaleBaudRateController.text);
        settingsData['scaleTimeout'] = int.parse(_scaleTimeoutController.text);
        settingsData['emailTriggerUrl'] = _emailTriggerUrlController.text;
        settingsData['serverUrl'] = _serverUrlController.text;
        settingsData['scaleDataBits'] = int.parse(_selectedDataBits!);
        settingsData['scaleParity'] = _selectedParity!;
        settingsData['scaleStopBits'] = double.parse(_selectedStopBits!);
        settingsData['scaleWeightUnit'] = _scaleUnitController.text;
        settingsData['companyId'] = int.parse(_companyIdController.text);
        settingsData['appTheme'] = int.parse(_selectedTheme!);
        settingsData['preText'] = int.parse(_preTextController.text);
        settingsData['postText'] = int.parse(_postTextController.text);
        settingsData['pikantoEmailSender'] = _pikantoEmailSenderController.text;
        settingsData['pikantoEmailToken'] = _pikantoEmailTokenController.text;

        // Save the waybill header image
        if (_waybillHeaderImage != null) {
          //final Directory appDocDir = await getApplicationDocumentsDirectory();
          final String appDocPath = settingsData['appImageDirectory'];
          final String waybillHeaderImagePath =
              '$appDocPath\\waybill_header_image.png';
          await _waybillHeaderImage!.copy(waybillHeaderImagePath);
          settingsData['waybillHeaderImage'] = waybillHeaderImagePath;
        }

        // Save the ticket header image
        if (_ticketHeaderImage != null) {
          //final Directory appDocDir = await getApplicationDocumentsDirectory();
          final String appDocPath = settingsData['appImageDirectory'];
          final String ticketHeaderImagePath =
              '$appDocPath\\ticket_header_image.png';
          await _ticketHeaderImage!.copy(ticketHeaderImagePath);
          settingsData['ticketHeaderImage'] = ticketHeaderImagePath;
        }

        // Update the settings file
        var result = await MyFunctions.updateSettingsFile();
        if (!result) {
          throw Exception('Failed to save settings');
        }

        // Update the server app settings
        if (_pikantoEmailTokenController.text.isNotEmpty ||
            _pikantoEmailSenderController.text.isNotEmpty ||
            _serverUrlController.text.isNotEmpty ||
            _emailTriggerUrlController.text.isNotEmpty) {
          await _updateServerAppSettings();
        }

        setState(() {
          _isSaving = false;
          _errorMessage = 'Settings saved successfully';
        });
      } catch (e) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _pickWaybillImage(String tag) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && tag == 'waybill') {
      setState(() {
        _waybillHeaderImage = File(pickedFile.path);
      });
    } else if (pickedFile != null && tag == 'ticket') {
      setState(() {
        _ticketHeaderImage = File(pickedFile.path);
      });
    }
  }

  // function that updates server app settings
  Future<void> _updateServerAppSettings() async {
    // Construct the request data
    // data item will be added if it's not empty
    // settings data will be sent to server for saving if current user has permission to edit app settings
    Map<String, dynamic> setting = {};
    if (_emailTriggerUrlController.text.isNotEmpty) {
      setting['emailTriggerUrl'] = _emailTriggerUrlController.text;
    }
    if (_serverUrlController.text.isNotEmpty) {
      setting['serverUrl'] = _serverUrlController.text;
    }
    if (_pikantoEmailTokenController.text.isNotEmpty) {
      setting['pikantoEmailToken'] = _pikantoEmailTokenController.text;
    }
    if (_pikantoEmailSenderController.text.isNotEmpty) {
      setting['pikantoEmailSender'] = _pikantoEmailSenderController.text;
    }
    final Map<String, dynamic> data = {
      'companyId': int.parse(_companyIdController.text),
      'settings': setting,
      'actor': currentUser,
    };

    if (currentUser['permissions']['canEditAppSettings']) {
      socketManager.sendMessage('update_app_settings', jsonEncode(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    //print(weightRecords);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // title
          const Text('Application Settings',
              style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          //divider
          const Divider(
            color: Colors.black,
            thickness: 1.0,
          ),

          const SizedBox(height: 30.0),
          if (_errorMessage != null) ...[
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16.0),
          ],
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 16.0),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _scalePortController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Scale Port',
                              hintText: 'Enter the port name of the scale',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a valid scale port';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: TextFormField(
                            controller: _scaleBaudRateController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Baud Rate',
                              hintText: 'Enter the baud rate of the scale',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  int.tryParse(value) == null) {
                                return 'Please enter a valid baud rate';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        // Scale Timeout Input
                        Expanded(
                          child: TextFormField(
                            controller: _scaleTimeoutController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Timeout (ms)',
                              hintText: 'Enter the timeout in milliseconds',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  int.tryParse(value) == null) {
                                return 'Please enter a valid timeout in milliseconds';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        // Scale Data Bits Input: Dropdown with 5, 6, 7, 8
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedDataBits,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedDataBits = newValue;
                              });
                            },
                            items: ['5', '6', '7', '8']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              labelText: 'Data Bits',
                              hintText: 'Select the number of data bits',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        // Scale Parity Input: Dropdown with none, odd, even
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedParity,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedParity = newValue;
                              });
                            },
                            items: ['none', 'odd', 'even']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              labelText: 'Parity',
                              hintText: 'Select the parity',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        // Scale Stop Bits Input: Dropdown with 1, 1.5, 2
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStopBits,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedStopBits = newValue;
                              });
                            },
                            items: ['1.0', '1.5', '2.0']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              labelText: 'Stop Bits',
                              hintText: 'Select the number of stop bits',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        // Company ID Input
                        Expanded(
                          child: TextFormField(
                            controller: _companyIdController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Company ID',
                              hintText: 'Enter the ID of the company',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a valid company ID';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        // preText
                        Expanded(
                          child: TextFormField(
                            controller: _preTextController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'preText',
                              hintText: '',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        // postText
                        Expanded(
                          child: TextFormField(
                            controller: _postTextController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'postText',
                              hintText: '',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        // Scale Weight Unit Input
                        Expanded(
                          child: TextFormField(
                            controller: _scaleUnitController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Scale Weight Unit',
                              hintText: 'Enter the unit of the scale weight',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a valid weight unit';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        // App Theme Input: Dropdown with brickRed, lightBlue, lemonGreen
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedTheme,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedTheme = newValue;
                              });
                              if (newValue != null) {
                                // Update the app theme notifier and notify listeners
                                appThemeNotifier.value = int.parse(newValue);
                                appThemeNotifier.notifyListeners();
                              }
                            },
                            items: appTheme.keys
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: appTheme[value].toString(),
                                child: Text(value),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              labelText: 'App Theme',
                              hintText: 'Select the theme of the app',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        // mailchimpApiKey
                        Expanded(
                          child: TextFormField(
                            controller: _pikantoEmailTokenController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Pikanto Email Token',
                              hintText: 'Enter the Pikanto email token',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            obscureText: true,
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        // mailchimpEmailSender
                        Expanded(
                          child: TextFormField(
                            controller: _pikantoEmailSenderController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Pikanto Email Sender',
                              hintText:
                                  'Enter the Pikanto Email Sender (e.g. pikanto@zinando.com.ng)',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        // Server URL Input
                        Expanded(
                          child: TextFormField(
                            controller: _serverUrlController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Server URL',
                              hintText: 'Enter the URL of the server',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a valid URL';
                              }
                              if (!Uri.parse(value).isAbsolute) {
                                return 'Please enter a valid URL';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        // Email Trigger URL Input
                        Expanded(
                          child: TextFormField(
                            controller: _emailTriggerUrlController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Email Trigger URL',
                              hintText:
                                  'Enter the URL to trigger email sending',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            /*validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a valid URL';
                              }
                              if (!Uri.parse(value).isAbsolute) {
                                return 'Please enter a valid URL';
                              }
                              return null;
                            },*/
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    // Waybill Header Image
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _pickWaybillImage('waybill');
                          },
                          label: const Text('Upload Waybill Header Image'),
                          icon: const Icon(Icons.upload, size: 40.0),
                        ),
                        const SizedBox(width: 16.0),
                        if (_waybillHeaderImage != null ||
                            settingsData['waybillHeaderImage'] != null)
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    _waybillHeaderImage?.path ??
                                        settingsData['waybillHeaderImage'] ??
                                        'No image selected',
                                    style: const TextStyle(
                                        fontSize: 16.0, color: Colors.black)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_red_eye),
                                      onPressed: () {
                                        if (_waybillHeaderImage != null) {
                                          // View the selected image
                                          showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              child: Image.file(
                                                  _waybillHeaderImage!),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          _waybillHeaderImage = null;
                                          settingsData['waybillHeaderImage'] =
                                              null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    // Ticket Header Image
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _pickWaybillImage('ticket');
                          },
                          label: const Text('Upload Ticket Header Image'),
                          icon: const Icon(Icons.upload, size: 40.0),
                        ),
                        const SizedBox(width: 16.0),
                        if (_ticketHeaderImage != null ||
                            settingsData['ticketHeaderImage'] != null)
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    _ticketHeaderImage?.path ??
                                        settingsData['ticketHeaderImage'] ??
                                        'No image selected',
                                    style: const TextStyle(
                                        fontSize: 16.0, color: Colors.black)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_red_eye),
                                      onPressed: () {
                                        if (_ticketHeaderImage != null) {
                                          // View the selected image
                                          showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              child: Image.file(
                                                  _ticketHeaderImage!),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          _ticketHeaderImage = null;
                                          settingsData['ticketHeaderImage'] =
                                              null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16.0),
                    _isSaving
                        ? loadingScreenWidgets[
                            settingsData['loadingScreenWidget']]
                        : currentUser['permissions']['canEditAppSettings']
                            ? ElevatedButton(
                                onPressed: _saveSettings,
                                child: const Text('Save Settings'),
                              )
                            : const SizedBox(),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scalePortController.dispose();
    _scaleBaudRateController.dispose();
    _scaleTimeoutController.dispose();
    _emailTriggerUrlController.dispose();
    super.dispose();
  }
}
