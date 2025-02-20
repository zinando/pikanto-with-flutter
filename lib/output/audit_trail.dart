import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/helpers/my_functions.dart';

class AuditTrailWidget extends StatefulWidget {
  const AuditTrailWidget({super.key});

  @override
  State createState() => _AuditTrailWidgetState();
}

class _AuditTrailWidgetState extends State<AuditTrailWidget> {
  List<dynamic> auditTrail = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  final int limit = 20; // Number of items per page
  bool hasMore = true; // To track if there are more pages to load

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchAuditTrail();
    _scrollController.addListener(_scrollListener); // Add scroll listener
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Clean up the controller
    super.dispose();
  }

  Future<void> fetchAuditTrail({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        isLoading = true;
      });
    } else {
      setState(() {
        isLoadingMore = true;
      });
    }

    try {
      final response = await http.get(
          Uri.parse(
              '${settingsData['serverUrl']}/api/v1/fetch_resources/audit_trail?page=$currentPage&limit=$limit'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          setState(() {
            isLoading = false;
            isLoadingMore = false;

            // If there's no more data, set hasMore to false
            if (responseBody['data'].length < limit) {
              hasMore = false;
            }

            // Append new data if loading more, else reset list
            if (loadMore) {
              auditTrail.addAll(responseBody['data']);
            } else {
              auditTrail = responseBody['data'];
            }
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
        isLoadingMore = false;
      });
      MyFunctions.showSnackBar(context, e.toString());
    }
  }

  // Scroll listener to trigger pagination when reaching the bottom of the list
  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        hasMore &&
        !isLoadingMore) {
      // Fetch the next page
      setState(() {
        currentPage++;
      });
      fetchAuditTrail(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: auditTrail.length +
                      (hasMore ? 1 : 0), // Add 1 for the loading indicator
                  itemBuilder: (context, index) {
                    if (index == auditTrail.length) {
                      // Show a loading indicator at the bottom if more data is being fetched
                      return const Center(child: CircularProgressIndicator());
                    }

                    final record = auditTrail[index];
                    return Card(
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${record['action']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Text('${record['actionDetails']}'),
                          ],
                        ),
                        subtitle: Text(
                            'By: ${record['actor']} on ${record['timestamp']}',
                            style: const TextStyle(
                                fontSize: 12, fontStyle: FontStyle.italic)),
                        leading: const Icon(Icons.history),
                      ),
                    );
                  },
                ),
              ),
              if (isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          );
  }
}
