import 'package:flutter/material.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApprovalRequestDialog extends StatefulWidget {
  final int waybillId;
  final bool isPending;
  final String vehicleId;
  final Map<String, dynamic>? primaryApprover;
  final List<Map<String, dynamic>>? secondaryApprovers;
  final Function(List<Map<String, dynamic>>, String) onSubmit;

  const ApprovalRequestDialog({
    super.key,
    required this.waybillId,
    required this.vehicleId,
    required this.onSubmit,
    this.primaryApprover,
    this.secondaryApprovers,
    this.isPending = false,
  });

  @override
  State createState() => _ApprovalRequestDialogState();
}

class _ApprovalRequestDialogState extends State<ApprovalRequestDialog> {
  Map<String, dynamic>? _selectedPrimaryApprover;

  late List<Map<String, dynamic>> _selectedSecondaryApprovers;
  String _approvalFlowType = 'sequence';
  bool _isLoading = false;
  String _error = '';

  // Example user list
  late List<Map<String, dynamic>> _users;

  @override
  void initState() {
    super.initState();
    _users = users;
    if (widget.primaryApprover != null &&
        widget.primaryApprover!.isNotEmpty &&
        _users.any(
            (user) => user['userId'] == widget.primaryApprover!['userId'])) {
      _selectedPrimaryApprover = _users.firstWhere(
        (user) => user['userId'] == widget.primaryApprover!['userId'],
      );
    }
    if (widget.secondaryApprovers != null &&
        widget.secondaryApprovers!.isNotEmpty) {
      _selectedSecondaryApprovers = List.from(widget.secondaryApprovers!);
    } else {
      _selectedSecondaryApprovers = [];
    }
  }

  void _addSecondaryApprover(Map<String, dynamic> approver) {
    setState(() {
      _selectedSecondaryApprovers.add(approver);
    });
  }

  void _removeSecondaryApprover(Map<String, dynamic>? approver) {
    // reduce the ranks of the other members
    _selectedSecondaryApprovers
        .map(
            (item) => {if (item['rank'] > approver!['rank']) item['rank'] -= 1})
        .toList();
    setState(() {
      //_selectedSecondaryApprover = null;
      _selectedSecondaryApprovers.remove(approver);
    });
  }

  void _submitRequest() async {
    if (_selectedPrimaryApprover == null) {
      setState(() {
        _error = 'You must select primary approver.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });

    // Construct the request data
    final requestData = {
      'waybillId': widget.waybillId,
      'primaryApprover': _selectedPrimaryApprover,
      'secondaryApprovers': _selectedSecondaryApprovers,
      'approvalFlowType': _approvalFlowType,
      'createdBy': currentUser['userId'] ?? 1,
      'settings': settingsData,
      'appId': settingsData['companyId'],
      'actor': currentUser,
    };

    try {
      final response = widget.primaryApprover == null ||
              widget.primaryApprover!.isEmpty
          ? await http.post(
              Uri.parse(
                  '${settingsData['serverUrl']}/api/v1/waybill_approval/create_request'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(requestData))
          : await http.put(
              Uri.parse(
                  '${settingsData['serverUrl']}/api/v1/waybill_approval/update_request'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(requestData));

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
        throw Exception('Server error. Pleas contact admin.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
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
                    child: Text(
                        'Send Waybill Approval Request For: ${widget.vehicleId}',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        )),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        label: Text('Select Approval Flow Type'),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      value: _approvalFlowType,
                      items: const [
                        DropdownMenuItem(
                          value: 'sequence',
                          child: Text('Sequence'),
                        ),
                        DropdownMenuItem(
                          value: 'parallel',
                          child: Text('Parallel'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _approvalFlowType = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedPrimaryApprover,
                      decoration: const InputDecoration(
                        label: Text('Select Primary Approver'),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      items: _users
                          .where((user) =>
                              user['adminType'] == 'approver' &&
                              user['deleteFlag'] == 0)
                          .map((user) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: user,
                          child: Text(user['fullName']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPrimaryApprover = value;
                          _removeSecondaryApprover(value);
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: const InputDecoration(
                        label: Text('Select Secondary Approvers'),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      items: _users
                          .where((user) =>
                              user['adminType'] == 'approver' &&
                              user['deleteFlag'] == 0)
                          .map((user) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: user,
                          child: Text(user['fullName']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null &&
                            value != _selectedPrimaryApprover &&
                            !_selectedSecondaryApprovers.any((approver) =>
                                approver['userId'] == value['userId'])) {
                          value['rank'] = _selectedSecondaryApprovers.length +
                              1; // rank based on order of selection
                          _addSecondaryApprover(value);
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: Text(
                      'In a sequential approval flow, user with rank number 1 will approve first, followed by number 2, in that order.',
                      style: TextStyle(
                          fontSize: 11.0,
                          color: Theme.of(context).colorScheme.tertiary),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Container(
                    alignment: Alignment.topCenter,
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: 250.0,
                    child: SingleChildScrollView(
                      child: Column(children: [
                        Text(
                          'List of Selected Secondary Approvers [${_selectedSecondaryApprovers.length}]',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold),
                        ),
                        Divider(
                          color: Colors.grey[300],
                        ),
                        ..._selectedSecondaryApprovers.map((approver) {
                          //print(approver['approvalStatus']);
                          return ListTile(
                            title: Text(
                                '${approver['fullName']} (Rank: ${approver['rank']})'),
                            trailing: !widget.isPending
                                ? Icon(
                                    approver['approvalStatus'] == 'pending' ||
                                            approver['approvalStatus'] == null
                                        ? Icons.pending
                                        : approver['approvalStatus'] ==
                                                'approved'
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                    color: approver['approvalStatus'] ==
                                                'pending' ||
                                            approver['approvalStatus'] == null
                                        ? Colors.orange
                                        : approver['approvalStatus'] ==
                                                'approved'
                                            ? Colors.green
                                            : Colors.red,
                                  )
                                : SizedBox(
                                    width: 120.0,
                                    height: 80.0,
                                    child: Row(
                                      children: [
                                        Icon(
                                          approver['approvalStatus'] ==
                                                      'pending' ||
                                                  approver['approvalStatus'] ==
                                                      null
                                              ? Icons.pending
                                              : approver['approvalStatus'] ==
                                                      'approved'
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                          color: approver['approvalStatus'] ==
                                                      'pending' ||
                                                  approver['approvalStatus'] ==
                                                      null
                                              ? Colors.orange
                                              : approver['approvalStatus'] ==
                                                      'approved'
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 12.0),
                                          onPressed: () =>
                                              _removeSecondaryApprover(
                                                  approver),
                                        ),
                                      ],
                                    ),
                                  ),
                          );
                        }),
                      ]),
                    ),
                  ),
                  if (_error != '') ...[
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.35,
                      child: Text(
                        _error,
                        style:
                            const TextStyle(fontSize: 12.0, color: Colors.red),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    )
                  ],
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
                          ? const Center(child: CircularProgressIndicator())
                          : !widget.isPending
                              ? const SizedBox()
                              : currentUser['permissions']
                                      ['canCreateApprovalRequest']
                                  ? ElevatedButton(
                                      onPressed: _submitRequest,
                                      child: Text(widget.primaryApprover ==
                                                  null ||
                                              widget.primaryApprover!.isEmpty
                                          ? 'Submit Request'
                                          : 'Update Request'),
                                    )
                                  : const SizedBox(),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
