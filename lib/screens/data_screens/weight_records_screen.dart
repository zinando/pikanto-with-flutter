import 'package:flutter/material.dart';
import 'package:pikanto/output/waybill_view.dart';
import 'dart:convert';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/helpers/my_functions.dart';
import 'package:pikanto/forms/waybill_form.dart';
import 'package:pikanto/forms/weight_recordform.dart';
import 'package:pikanto/forms/approval_req_form.dart';
import 'package:pikanto/forms/approval_action_form.dart';
import 'package:pikanto/output/ticket_view.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:pikanto/forms/add_comment_form.dart';

class DataHistory extends StatefulWidget {
  const DataHistory({super.key});
  @override
  State createState() => _DataHistoryState();
}

class _DataHistoryState extends State<DataHistory> {
  final ScrollController _horizontalScrollController = ScrollController();
  //List<Map<String, dynamic>> _weightList = weightRecords;
  List<Map<String, dynamic>> _weightList =
      WeightRecordsProvider().weightRecordsList;
  /*List.filled(10, weightRecords).expand((element) => element).toList(); */
  final SocketManager socketManager = SocketManager();

  // define pagination variables
  int _currentPage = 0;
  static const int _recordsPerPage = 10;
  int _calculateTotalPages(int numerator, int denominator) {
    // ensure that the denominator is not zero
    if (denominator == 0) {
      return 0;
    }
    return (numerator / denominator).ceil();
  }

  // function to open approval request dialog
  Future<void> _openApprovalRequestDialog(
      int waybillId, String vehicleId, bool isPending,
      {Map<String, dynamic>? primaryApprover,
      List<Map<String, dynamic>>? secondaryApprovers}) async {
    await showDialog<String>(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return ApprovalRequestDialog(
            waybillId: waybillId,
            vehicleId: vehicleId,
            onSubmit: (List<Map<String, dynamic>> weightList, String message) {
              _weightList = weightList;

              setState(() {});
              MyFunctions.showSnackBar(context, message);
            },
            primaryApprover: primaryApprover,
            secondaryApprovers: secondaryApprovers,
            isPending: isPending,
          );
        });
  }

  // function to open approval action dialog
  Future<void> _openApprovalActionDialog(int approvalRequestId) async {
    await showDialog<String>(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return ApprovalActionDialog(
              approvalRequestId: approvalRequestId,
              onSubmit:
                  (List<Map<String, dynamic>> weightList, String message) {
                _weightList = weightList;

                setState(() {});
                MyFunctions.showSnackBar(context, message);
              });
        });
  }

  Future<void> _openCommentForm(int recordId, String comment) async {
    //do something
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AddCommentForm(recordId: recordId, comment: comment);
        });
  }

  Future<void> editTicket(Map<String, dynamic> record, int index) async {
    // call the weightRecordForm widget

    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return WeightRecordForm(
              weightRecord: record,
              scaleReading: '',
              vehicleId: record['vehicleId'],
              customers: customers,
              hauliers: hauliers,
              products: products,
              onSubmit: (Map<String, dynamic> editedRecord, bool isEdited) {
                if (mounted) {
                  setState(() {
                    _weightList[index] = editedRecord;
                  });
                  MyFunctions.showSnackBar(
                      context, "Record was modified successfully.");
                }
              });
        });
  }

  void updateWeightRecord(Map<String, dynamic> record, int index) {
    // update the weight record
    if (mounted) {
      setState(() {
        _weightList[index] = record;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    //listen to the socket manager for weight records
    SocketManager()
        .addListenerIfNeeded('weight_records', _updateWeightRecordList);
  }

  // create a function that updates the weight record list
  void _updateWeightRecordList() {
    final List<Map<String, dynamic>> data =
        socketManager.weightRecordListNotifier.value;
    _weightList = data;
    //List.filled(10, data).expand((element) => element).toList();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteRecord(int weightRecordId, bool isTicket) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '${settingsData["serverUrl"]}/api/v1/${isTicket ? "weight_record" : "waybill"}/delete_record'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'weightRecordId': weightRecordId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 1) {
          final List<Map<String, dynamic>> newList =
              List<Map<String, dynamic>>.from(responseBody['data']);

          if (mounted) {
            setState(() {
              weightRecords = newList;
              _weightList = List.filled(10, weightRecords)
                  .expand((element) => element)
                  .toList();
            });
          }
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception("Failed to delete record: Check server connection.");
      }
    } catch (e) {
      MyFunctions.showSnackBar(context, e.toString());
    }
  }

  Future<bool> _showDeleteConfirmation(int index, bool isTicket) async {
    final Map<String, dynamic> item = _weightList[index]; // get the item
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Confirm Deletion'),
              content: Text(
                  isTicket
                      ? 'Are you sure you want to delete this record?\n'
                          'This will erase the entire record including the waybill data.\n\n'
                          'Vehicle ID: ${item['vehicleId']}'
                      : 'Are you sure you want to delete the waybill data for this record?\n\n'
                          'Vehicle ID: ${item['vehicleId']}',
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

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weightRecordsProvider = context.watch<WeightRecordsProvider>();
    //print(weightRecordsProvider.weightRecordsList);
    //print(currentUser['permissions']);
    bool _isSmallHeight = MediaQuery.of(context).size.height <= 700;
    int startIndex = _currentPage * _recordsPerPage;
    int endIndex = startIndex + _recordsPerPage;
    List<Map<String, dynamic>> _weightRecords =
        weightRecordsProvider.weightRecordsList.sublist(
            startIndex,
            endIndex > weightRecordsProvider.weightRecordsList.length
                ? weightRecordsProvider.weightRecordsList.length
                : endIndex);
    final int totalPages = _calculateTotalPages(
        weightRecordsProvider.weightRecordsList.length, _recordsPerPage);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            color: Colors.grey[400],
            child: const Text(
              'WEIGHT RECORD HISTORY',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xff000000),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8.0),
            color: _weightRecords.isEmpty ? Colors.grey[200] : Colors.white,
            child: _weightRecords.isEmpty
                ? Text(
                    'No weight records available!',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  )
                : Column(
                    children: [
                      Scrollbar(
                        controller: _horizontalScrollController,
                        //thumbVisibility: true,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _horizontalScrollController,
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            width: 995,
                            /*_isSmallScreen
                                ? 710
                                : _isMediuScreen
                                    ? 770
                                    : 1040,*/
                            height: _isSmallHeight
                                ? MediaQuery.of(context).size.height * 0.65
                                : MediaQuery.of(context).size.height * 0.70,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 255,
                                      margin: const EdgeInsets.fromLTRB(
                                          0.0, 0.0, 0.0, 4.0),
                                      color: Colors.grey[300],
                                      //alignment: ,
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Vehicle ID',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 125.25,
                                      margin: const EdgeInsets.fromLTRB(
                                          4.0, 0.0, 0.0, 4.0),
                                      color: Colors.grey[300],
                                      //alignment: ,
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Entry',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 125.25,
                                      margin: const EdgeInsets.fromLTRB(
                                          4.0, 0.0, 0.0, 4.0),
                                      color: Colors.grey[300],
                                      //alignment: ,
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Exit',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 125.25,
                                      margin: const EdgeInsets.fromLTRB(
                                          4.0, 0.0, 0.0, 4.0),
                                      color: Colors.grey[300],
                                      //alignment: ,
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Net',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 40.0,
                                      margin: const EdgeInsets.fromLTRB(
                                          4.0, 0.0, 0.0, 4.0),
                                      color: Colors.white,
                                      //alignment: ,
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        '',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      //width: MediaQuery.of(context).size.width *
                                      //  0.2,
                                      width: 260.0,
                                      margin: const EdgeInsets.fromLTRB(
                                          4.0, 0.0, 0.0, 0.0),
                                      color: Colors.grey[300],
                                      //alignment: ,
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Action',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _weightRecords.length,
                                    itemBuilder: (context, index) {
                                      final bool finalWeightNotReady =
                                          double.tryParse(_weightRecords[index]
                                                      ['finalWeight']
                                                  .toString()) ==
                                              null;
                                      final bool canApprove =
                                          _weightRecords[index]
                                                  ['approvalStatus'] ==
                                              'pending';

                                      return Container(
                                        margin: const EdgeInsets.fromLTRB(
                                            0.0, 4.0, 0.0, 0.0),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 255,
                                              margin: const EdgeInsets.fromLTRB(
                                                  0.0, 0.0, 0.0, 4.0),
                                              color: Colors.grey[200],
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                _weightRecords[index]
                                                    ['vehicleId'],
                                                style: TextStyle(
                                                  fontSize: 16.0,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 125.25,
                                              margin: const EdgeInsets.fromLTRB(
                                                  4.0, 0.0, 0.0, 4.0),
                                              color: Colors.grey[200],
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                _weightRecords[index]
                                                        ['initialWeight']
                                                    .toString(),
                                                style: TextStyle(
                                                  fontSize: 16.0,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 125.25,
                                              margin: const EdgeInsets.fromLTRB(
                                                  4.0, 0.0, 0.0, 4.0),
                                              color: Colors.grey[200],
                                              //alignment: ,
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                _weightRecords[index]
                                                        ['finalWeight']
                                                    .toString(),
                                                style: TextStyle(
                                                  fontSize: 16.0,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 125.25,
                                              margin: const EdgeInsets.fromLTRB(
                                                  4.0, 0.0, 0.0, 4.0),
                                              color: Colors.grey[200],
                                              //alignment: ,
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                MyFunctions.subtractAndFormat(
                                                    _weightRecords[index]
                                                        ['initialWeight'],
                                                    _weightRecords[index]
                                                        ['finalWeight']),
                                                style: TextStyle(
                                                  fontSize: 16.0,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 40.0,
                                              margin: const EdgeInsets.fromLTRB(
                                                  4.0, 0.0, 0.0, 4.0),
                                              color: Colors.white,
                                              alignment: Alignment.center,
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Tooltip(
                                                message: _weightRecords[index]
                                                            ['waybillRecord']
                                                        ['remarks'] ??
                                                    '',
                                                child: Icon(
                                                  _weightRecords[index][
                                                              'approvalStatus'] ==
                                                          'pending'
                                                      ? Icons.pending
                                                      : _weightRecords[index][
                                                                  'approvalStatus'] ==
                                                              'approved'
                                                          ? Icons.check_circle
                                                          : Icons.cancel,
                                                  color: _weightRecords[index][
                                                              'approvalStatus'] ==
                                                          'pending'
                                                      ? Colors.orange
                                                      : _weightRecords[index][
                                                                  'approvalStatus'] ==
                                                              'approved'
                                                          ? Colors.green
                                                          : Colors.red,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              width: 260.0,
                                              color: Colors.white,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    color: Colors.grey[300],
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    width: 100.0,
                                                    child: Column(
                                                      children: [
                                                        Container(
                                                          alignment:
                                                              Alignment.center,
                                                          width: 90.0,
                                                          height: 15.0,
                                                          color: Colors.white,
                                                          child: Text(
                                                            'Ticket Data',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[700],
                                                              fontSize: 11.0,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          child: Row(
                                                            children: [
                                                              IconButton(
                                                                icon: Icon(
                                                                  Icons
                                                                      .remove_red_eye,
                                                                  color: Colors
                                                                          .grey[
                                                                      700],
                                                                  size: 15.0,
                                                                ),
                                                                constraints:
                                                                    const BoxConstraints(
                                                                  maxHeight:
                                                                      30.0,
                                                                  maxWidth:
                                                                      30.0,
                                                                ),
                                                                hoverColor:
                                                                    Colors.grey[
                                                                        200],
                                                                tooltip:
                                                                    'view ticket',
                                                                onPressed: () {
                                                                  if (currentUser[
                                                                          'permissions']
                                                                      [
                                                                      'canViewWeightRecord']) {
                                                                    Navigator.of(
                                                                            context)
                                                                        .push(MaterialPageRoute(builder:
                                                                            (context) {
                                                                      return TicketView(
                                                                        headerImageUrl:
                                                                            settingsData['ticketHeaderImage'],
                                                                        recordData:
                                                                            _weightRecords[index],
                                                                      );
                                                                    }));
                                                                  }
                                                                },
                                                              ),
                                                              IconButton(
                                                                icon: Icon(
                                                                  Icons.edit,
                                                                  color: Colors
                                                                          .grey[
                                                                      700],
                                                                  size: 15.0,
                                                                ),
                                                                constraints:
                                                                    const BoxConstraints(
                                                                  maxHeight:
                                                                      30.0,
                                                                  maxWidth:
                                                                      30.0,
                                                                ),
                                                                hoverColor:
                                                                    Colors.grey[
                                                                        200],
                                                                tooltip:
                                                                    'edit ticket',
                                                                onPressed: () {
                                                                  if (currentUser[
                                                                          'permissions']
                                                                      [
                                                                      'canEditWeightRecord']) {
                                                                    editTicket(
                                                                        _weightRecords[
                                                                            index],
                                                                        index);
                                                                  }
                                                                },
                                                              ),
                                                              IconButton(
                                                                  icon: Icon(
                                                                    /*Icons
                                                                        .delete,*/
                                                                    Icons
                                                                        .comment,
                                                                    color: Colors
                                                                            .grey[
                                                                        700],
                                                                    size: 15.0,
                                                                  ),
                                                                  constraints:
                                                                      const BoxConstraints(
                                                                    maxHeight:
                                                                        30.0,
                                                                    maxWidth:
                                                                        30.0,
                                                                  ),
                                                                  hoverColor:
                                                                      Colors.grey[
                                                                          200],
                                                                  tooltip:
                                                                      'comment',
                                                                  onPressed:
                                                                      () async {
                                                                    /*
                                                                    if (!currentUser[
                                                                            'permissions']
                                                                        [
                                                                        'canDeleteWeightRecord']) {
                                                                      return;
                                                                    }
                                                                    final shouldDelete =
                                                                        await _showDeleteConfirmation(
                                                                            index,
                                                                            true);
                                                                    if (shouldDelete) {
                                                                      _deleteRecord(
                                                                          _weightRecords[index]
                                                                              [
                                                                              'weightRecordId'],
                                                                          true);
                                                                    }
                                                                    */
                                                                    _openCommentForm(
                                                                        _weightRecords[index]
                                                                            [
                                                                            'weightRecordId'],
                                                                        _weightRecords[index]['comment'] ??
                                                                            '');
                                                                  }),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Container(
                                                      color: Colors.grey[300],
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2.0),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            alignment: Alignment
                                                                .center,
                                                            color: Colors.white,
                                                            child: Text(
                                                              'Waybill Data',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .grey[700],
                                                                fontSize: 11.0,
                                                              ),
                                                            ),
                                                          ),
                                                          _weightRecords[index][
                                                                  'waybillReady']
                                                              ? SizedBox(
                                                                  child: Row(
                                                                    children: [
                                                                      IconButton(
                                                                        icon:
                                                                            Icon(
                                                                          Icons
                                                                              .remove_red_eye,
                                                                          color:
                                                                              Colors.grey[700],
                                                                          size:
                                                                              15.0,
                                                                        ),
                                                                        constraints:
                                                                            const BoxConstraints(
                                                                          maxHeight:
                                                                              30.0,
                                                                          maxWidth:
                                                                              30.0,
                                                                        ),
                                                                        splashRadius:
                                                                            10.0,
                                                                        hoverColor:
                                                                            Colors.grey[200],
                                                                        tooltip:
                                                                            'view waybill',
                                                                        onPressed:
                                                                            () {
                                                                          if (currentUser['permissions']
                                                                              [
                                                                              'canViewWaybill']) {
                                                                            Navigator.of(context).push(MaterialPageRoute(builder:
                                                                                (context) {
                                                                              return WaybillView(
                                                                                headerImageUrl: settingsData['waybillHeaderImage'],
                                                                                recordData: _weightRecords[index]['waybillRecord'],
                                                                              );
                                                                            }));
                                                                          }
                                                                        },
                                                                      ),
                                                                      IconButton(
                                                                        icon:
                                                                            Icon(
                                                                          Icons
                                                                              .edit,
                                                                          color:
                                                                              Colors.grey[700],
                                                                          size:
                                                                              15.0,
                                                                        ),
                                                                        constraints:
                                                                            const BoxConstraints(
                                                                          maxHeight:
                                                                              30.0,
                                                                          maxWidth:
                                                                              30.0,
                                                                        ),
                                                                        hoverColor:
                                                                            Colors.grey[200],
                                                                        tooltip:
                                                                            'edit waybill',
                                                                        onPressed:
                                                                            () {
                                                                          if (!currentUser['permissions']
                                                                              [
                                                                              'canEditWaybill']) {
                                                                            return;
                                                                          }
                                                                          // navigate to waybill form
                                                                          Navigator.of(context).push(MaterialPageRoute(builder:
                                                                              (context) {
                                                                            return WaybillForm(
                                                                              isUpdate: true,
                                                                              weightRecord: _weightRecords[index],
                                                                              recordIndex: index,
                                                                              onSubmit: updateWeightRecord,
                                                                            );
                                                                          }));
                                                                        },
                                                                      ),
                                                                      IconButton(
                                                                        icon:
                                                                            Icon(
                                                                          Icons
                                                                              .delete,
                                                                          color:
                                                                              Colors.grey[700],
                                                                          size:
                                                                              15.0,
                                                                        ),
                                                                        constraints:
                                                                            const BoxConstraints(
                                                                          maxHeight:
                                                                              30.0,
                                                                          maxWidth:
                                                                              30.0,
                                                                        ),
                                                                        hoverColor:
                                                                            Colors.grey[200],
                                                                        tooltip:
                                                                            'delete waybill data',
                                                                        onPressed:
                                                                            () async {
                                                                          if (!currentUser['permissions']
                                                                              [
                                                                              'canDeleteWaybill']) {
                                                                            return;
                                                                          }
                                                                          final shouldDelete = await _showDeleteConfirmation(
                                                                              index,
                                                                              false);
                                                                          if (shouldDelete) {
                                                                            _deleteRecord(_weightRecords[index]['weightRecordId'],
                                                                                false);
                                                                          }
                                                                        },
                                                                      ),
                                                                      IconButton(
                                                                        icon:
                                                                            Icon(
                                                                          Icons
                                                                              .how_to_reg,
                                                                          color: finalWeightNotReady
                                                                              ? Colors.grey[200]
                                                                              : Colors.grey[700],
                                                                          size:
                                                                              15.0,
                                                                        ),
                                                                        constraints:
                                                                            const BoxConstraints(
                                                                          maxHeight:
                                                                              30.0,
                                                                          maxWidth:
                                                                              30.0,
                                                                        ),
                                                                        hoverColor:
                                                                            Colors.grey[200],
                                                                        tooltip:
                                                                            'request waybill approval',
                                                                        onPressed:
                                                                            () {
                                                                          if (!currentUser['permissions']
                                                                              [
                                                                              'canViewApprovalRequest']) {
                                                                            return;
                                                                          }
                                                                          if (!finalWeightNotReady) {
                                                                            _openApprovalRequestDialog(
                                                                              _weightRecords[index]['waybillRecord']['waybillId'],
                                                                              _weightRecords[index]['vehicleId'],
                                                                              canApprove,
                                                                              primaryApprover: Map<String, dynamic>.from(_weightRecords[index]['waybillRecord']['primaryApprover']),
                                                                              secondaryApprovers: List<Map<String, dynamic>>.from(_weightRecords[index]['waybillRecord']['secondaryApprovers']),
                                                                            );
                                                                          }
                                                                        },
                                                                      ),
                                                                      IconButton(
                                                                        icon:
                                                                            Icon(
                                                                          Icons
                                                                              .approval,
                                                                          color: finalWeightNotReady
                                                                              ? Colors.grey[200]
                                                                              : MyFunctions.itemNeedsApproval(_weightRecords[index])
                                                                                  ? Theme.of(context).primaryColor
                                                                                  : Colors.grey[700],
                                                                          size:
                                                                              15.0,
                                                                        ),
                                                                        constraints:
                                                                            const BoxConstraints(
                                                                          maxHeight:
                                                                              30.0,
                                                                          maxWidth:
                                                                              30.0,
                                                                        ),
                                                                        hoverColor:
                                                                            Colors.grey[200],
                                                                        tooltip:
                                                                            'approve waybill',
                                                                        onPressed:
                                                                            () {
                                                                          if (!currentUser['permissions']
                                                                              [
                                                                              'canApproveWaybill']) {
                                                                            return;
                                                                          }
                                                                          if (canApprove) {
                                                                            _openApprovalActionDialog(_weightRecords[index]['waybillRecord']['approvalRequestId']);
                                                                          }
                                                                        },
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )
                                                              : SizedBox(
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      IconButton(
                                                                        icon:
                                                                            Icon(
                                                                          Icons
                                                                              .add,
                                                                          color:
                                                                              Colors.grey[700],
                                                                          size:
                                                                              15.0,
                                                                        ),
                                                                        constraints:
                                                                            const BoxConstraints(
                                                                          maxHeight:
                                                                              30.0,
                                                                          maxWidth:
                                                                              30.0,
                                                                        ),
                                                                        hoverColor:
                                                                            Colors.grey[200],
                                                                        tooltip:
                                                                            'create waybill',
                                                                        onPressed:
                                                                            () {
                                                                          if (!currentUser['permissions']
                                                                              [
                                                                              'canAddWaybill']) {
                                                                            return;
                                                                          }
                                                                          // navigate to waybill form
                                                                          Navigator.of(context).push(MaterialPageRoute(builder:
                                                                              (context) {
                                                                            return WaybillForm(
                                                                              isUpdate: false,
                                                                              weightRecord: _weightRecords[index],
                                                                              recordIndex: index,
                                                                              onSubmit: updateWeightRecord,
                                                                            );
                                                                          }));
                                                                        },
                                                                      ),
                                                                    ],
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
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.navigate_before,
                                  color: _currentPage > 0
                                      ? Colors.grey[700]
                                      : Colors.grey[400],
                                  size: 25.0,
                                ),
                                autofocus: _currentPage > 0,
                                focusColor: Colors.grey[200],
                                hoverColor: Colors.grey[200],
                                mouseCursor: _currentPage > 0
                                    ? SystemMouseCursors.click
                                    : MouseCursor.defer,
                                tooltip: 'previous page',
                                onPressed: _currentPage > 0
                                    ? () {
                                        setState(() {
                                          _currentPage--;
                                        });
                                      }
                                    : null,
                              ),
                              Text(
                                "Previous",
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: _currentPage > 0
                                      ? Colors.grey[700]
                                      : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                          Text(
                              "Page ${_currentPage + 1} of ${totalPages.toString()}",
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey[400],
                              )),
                          Row(
                            children: [
                              Text(
                                "Next",
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: _currentPage < totalPages - 1
                                      ? Colors.grey[700]
                                      : Colors.grey[400],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.navigate_next,
                                  color: _currentPage < totalPages - 1
                                      ? Colors.grey[700]
                                      : Colors.grey[400],
                                  size: 25.0,
                                ),
                                autofocus: _currentPage < totalPages - 1,
                                focusColor: Colors.grey[200],
                                hoverColor: Colors.grey[200],
                                mouseCursor: _currentPage < totalPages - 1
                                    ? SystemMouseCursors.click
                                    : MouseCursor.defer,
                                tooltip: 'next page',
                                onPressed: _currentPage < totalPages - 1
                                    ? () {
                                        setState(() {
                                          _currentPage++;
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
