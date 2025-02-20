/*
* Thisform is used to add comments to weighbill records by users
*/
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pikanto/resources/settings.dart';

class AddCommentForm extends StatefulWidget {
  final int recordId;
  final String comment;
  const AddCommentForm({
    super.key,
    required this.recordId,
    required this.comment,
  });

  @override
  State<StatefulWidget> createState() => _AddCommentFormState();
}

class _AddCommentFormState extends State<AddCommentForm> {
  final TextEditingController _commentController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isChanged = false; // detects when changes are made to comment text

  @override
  void initState() {
    super.initState();
    _commentController.text = widget.comment;
  }

  void _activateUpdateButton() {
    setState(() {
      _isChanged = true;
    });
  }

  Future<void> _updateComment() async {
    await Future.delayed(const Duration(seconds: 3));
    try {
      final response = await http.put(
          Uri.parse(
              '${settingsData['serverUrl']}/api/v1/weight_record/update_comment'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'weightRecordId': widget.recordId,
            'comment': _commentController.text,
            'actor': currentUser
          }));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        if (responseBody['status'] == 1) {
          setState(() {
            _commentController.text = responseBody['data'];
            _errorMessage = responseBody['message'];
            _isLoading = false;
          });
          await Future.delayed(const Duration(seconds: 2));
          Navigator.of(context).pop();
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception("Failed with error code ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isChanged = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(children: [
          Expanded(
            flex: 2,
            child: Center(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  focusedBorder: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                maxLines: null,
                readOnly: !currentUser['permissions']['canEditWeightRecord'],
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  _activateUpdateButton();
                  _commentController.text = value;
                },
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('cancel'),
                ),
                const SizedBox(
                  width: 20.0,
                ),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _isChanged
                            ? () {
                                setState(() {
                                  _isLoading = true;
                                });
                                _updateComment();
                              }
                            : null,
                        child: const Text('update comment'),
                      ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
