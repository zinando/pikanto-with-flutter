import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pikanto/resources/settings.dart';

class ApprovalActionDialog extends StatefulWidget {
  final int approvalRequestId;
  final Function(List<Map<String, dynamic>>, String) onSubmit;

  const ApprovalActionDialog({
    super.key,
    required this.approvalRequestId,
    required this.onSubmit,
  });

  @override
  State createState() => _ApprovalActionDialogState();
}

class _ApprovalActionDialogState extends State<ApprovalActionDialog> {
  final _formKey = GlobalKey<FormState>();
  String _action = 'approved';
  String _comments = '';
  bool _isLoading = false;
  String _error = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: const Text(
                      'Approval Action',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Action:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600]),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Approve'),
                                value: 'approved',
                                groupValue: _action,
                                onChanged: (value) {
                                  setState(() {
                                    _action = value!;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Decline'),
                                value: 'declined',
                                groupValue: _action,
                                onChanged: (value) {
                                  setState(() {
                                    _action = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          style: TextStyle(color: Colors.grey[600]),
                          decoration: const InputDecoration(
                            label: Text('comments'),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (_action == 'declined' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Comments are required for declining.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _comments = value ?? '';
                          },
                        ),
                        const SizedBox(height: 16.0),
                        if (_error.isNotEmpty)
                          Text(
                            _error,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12.0,
                            ),
                          ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16.0),
                            _isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: _submitApprovalAction,
                                    child: const Text('Submit'),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitApprovalAction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    // check that approval action was selected
    if (_action.isEmpty) {
      setState(() {
        _error = 'Please select an action.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    // Construct the request data
    final requestData = {
      'approvalRequestId': widget.approvalRequestId,
      'approverId': currentUser['userId'],
      'action': _action,
      'comments': _comments,
      'settings': settingsData,
      'appId': settingsData['companyId'],
      'actor': currentUser,
    };

    try {
      final response = await http.put(
        Uri.parse(
            '${settingsData['serverUrl']}/api/v1/waybill_approval/approve_request'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestData),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          List<Map<String, dynamic>> weightRecords =
              List<Map<String, dynamic>>.from(responseBody['data']);

          widget.onSubmit(weightRecords, responseBody['message']);
          Navigator.of(context).pop();
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception('Server error. Please contact admin.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }
}
