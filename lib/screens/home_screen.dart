import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/helpers/my_functions.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:pikanto/forms/weight_recordform.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pikanto/output/print_ticket.dart';
import 'package:pikanto/output/print_waybill.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //List<Map<String, dynamic>> _weightRecords = [];

  late String _scaleReading;
  late List<Map<String, dynamic>> notificationList;
  late int notificationCount;
  Timer? _timer;
  late SerialPort _port;
  final List<String> _availablePorts = SerialPort.availablePorts;
  StreamSubscription<String>? _subscription;
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _vehicleIdController = TextEditingController();

  // for websocket
  final SocketManager socketManager = SocketManager();

  @override
  void initState() {
    super.initState();
    currentPage = 'home';

    //listen with provider notifier for notifications and weight records
    SocketManager()
        .addListenerIfNeeded('notifications', _updateNotificationList);
    SocketManager()
        .addListenerIfNeeded('weight_records', _updateWeightRecordList);

    // listen for the current user if necessary
    SocketManager().listenToNotifications();
    SocketManager().listenToWeightRecords();
    fetchResources();
    _getNotifications();

    _scaleReading = '0.0';
    //settingsData['scaleReading'].toString();
    _outputController.text = _scaleReading;
    notificationList = []; //notificationsList;

    updateUI();
    _configureSerialPort();
    notificationCount = notificationList
        .where((element) => element['status'] == 'unread')
        .toList()
        .length; // Count the number of unread notifications
  }

  void updateNotificationCount(Map<String, dynamic> item) {
    // Mark the notification as read
    // send a message to the server to update the notification status
    if (item['status'] == 'unread') {
      var data = jsonEncode({
        'notificationId': item['notificationId'],
        'userId': currentUser["userId"],
      });
      socketManager.sendMessage('update_notification', data);
    }
  }

  void _updateNotificationList() {
    notificationsList = socketManager.notificationListNotifier.value;
    notificationList = notificationsList;

    notificationCount = notificationList
        .where((element) => element['status'] == 'unread')
        .toList()
        .length;
    if (mounted) {
      setState(() {});
    } else {
      // show local notification
      if (currentPage != 'home' && !isNotificationShown) {
        showLocalNotification(notificationList[0]['action']);
        isNotificationShown = false;
      }
    }
  }

  // create a function that fetches notifications for user
  void _getNotifications() {
    // Emit a message to the server
    var data = jsonEncode({'userId': currentUser['userId']});
    socketManager.sendMessage('fetch_notifications', data);
  }

  Future<String?> showAlertForm() async {
    final _formKey = GlobalKey<FormState>();
    _vehicleIdController.clear();

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          title: const Text('Enter Vehicle ID'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _vehicleIdController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                  hintText: 'Enter Vehicle ID',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  )),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a Vehicle ID';
                }
                return null; // Input is valid
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Close the dialog without returning any data
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop(_vehicleIdController
                      .text); // Return the input text if valid
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> verifyRecord() async {
    // check if scale reading is a valid number
    final bool isValidNumber = MyFunctions.isNumber(_outputController.text);
    if (!isValidNumber) {
      MyFunctions.showSnackBar(context, 'invalid scale data');
      return;
    }

    String? vehicleId = await showAlertForm();
    if (vehicleId != null) {
      // Verify id at the backend
      try {
        final response = await http.post(
          Uri.parse(
              '${settingsData["serverUrl"]}/api/v1/fetch_resources/weight_record'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            //'Authorization': 'Bearer ${settingsData["token"]}',
          },
          body: jsonEncode(<String, dynamic>{
            'vehicleId': vehicleId,
            'scope': 'last_uncompleted'
          }),
        );

        if (response.statusCode == 200) {
          // Save the weight record to the weightRecords list
          Map<String, dynamic> responseBody = jsonDecode(response.body);

          // check if uncompleted record was found
          if (responseBody['status'] == 1) {
            Map<String, dynamic> weightRecord =
                Map<String, dynamic>.from(responseBody['data']);
            setState(() {
              hauliers =
                  List<Map<String, dynamic>>.from(responseBody['hauliers']);
              customers =
                  List<Map<String, dynamic>>.from(responseBody['customers']);
              products =
                  List<Map<String, dynamic>>.from(responseBody['products']);
            });
            showWeightRecordForm(weightRecord, vehicleId);
          } else if (responseBody['status'] == 3) {
            setState(() {
              hauliers =
                  List<Map<String, dynamic>>.from(responseBody['hauliers']);
              customers =
                  List<Map<String, dynamic>>.from(responseBody['customers']);
              products =
                  List<Map<String, dynamic>>.from(responseBody['products']);
            });
            // Create a new weight record
            showWeightRecordForm(null, vehicleId);
          } else {
            MyFunctions.showSnackBar(context, responseBody['message']);
          }
        } else {
          MyFunctions.showSnackBar(context,
              'Error: Request failed. Please check backend server connection.');
        }
      } catch (e) {
        MyFunctions.showSnackBar(context, 'Error: $e');
      }
    }
  }

  // fetch weight records from the backend
  Future<void> fetchResources() async {
    // This function fetches app data such as weight records, customers, hauliers, products
    await fetchWeightRecords();
    try {
      final response = await http.get(
        Uri.parse(
            '${settingsData["serverUrl"]}/api/v1/fetch_resources/weight_records'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          //'Authorization': 'Bearer ${settingsData["token"]}',
        },
      );

      if (response.statusCode == 200) {
        // get the response body
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        // check if the response status is 1
        if (responseBody['status'] == 1) {
          // get the data from the response body
          // List<Map<String, dynamic>> data =
          //     List<Map<String, dynamic>>.from(responseBody['data']);
          // update the resources lists
          if (mounted) {
            setState(() {
              hauliers =
                  List<Map<String, dynamic>>.from(responseBody['hauliers']);
              customers =
                  List<Map<String, dynamic>>.from(responseBody['customers']);
              products =
                  List<Map<String, dynamic>>.from(responseBody['products']);
              //_weightRecords = data;
            });
          }
        } else {
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception(
            'Request failed. Please check backend server connection.');
      }
    } catch (e) {
      if (mounted) {
        MyFunctions.showSnackBar(context, e.toString());
      }
    }
  }

  Future<void> fetchWeightRecords() async {
    SocketManager().sendMessage('fetch_weight_records', '');
  }

  // Create function that takes in a weight record item and updates the weightRecords list
  void _updateWeightRecords(Map<String, dynamic> record, bool isUpdate) {
    if (mounted) {
      if (isUpdate) {
        // Update the weight record
        int index = weightRecords.indexWhere(
            (element) => element['weightRecordId'] == record['weightRecordId']);
        weightRecords[index] = record;
        //_weightRecords = weightRecords;
      } else {
        // Insert the weight record at the beginning of the list
        setState(() {
          weightRecords.insert(0, record);
          //_weightRecords = weightRecords;
        });
      }
    }
  }

  // Create a dialog to show the weight record form
  Future<void> showWeightRecordForm(
      Map<String, dynamic>? weightRecord, String vehicleId) async {
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return WeightRecordForm(
              vehicleId: vehicleId,
              weightRecord: weightRecord,
              scaleReading: _scaleReading,
              customers: customers,
              hauliers: hauliers,
              products: products,
              onSubmit: _updateWeightRecords);
        });
  }

  // Create a function that marks all notifications as read
  void markAllAsRead() {
    // check if any of the notifications is unread
    if (notificationList.any((element) => element['status'] == 'unread')) {
      // get the unread notifications
      var unreadNotifications = notificationList
          .where((element) => element['status'] == 'unread')
          .toList();
      // send a message to the server to update the notification status
      var data = jsonEncode({
        'notifications': unreadNotifications,
        'userId': currentUser["userId"] ?? 1,
      });
      socketManager.sendMessage('update_notifications', data);
    }
  }

  /*  Create a function that rebuilds the ui after every 60 seconds
      This ensures the notification time is updated every minute 
  */
  void updateUI() {
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // create a function that updates the weight record list
  void _updateWeightRecordList() {
    final List<Map<String, dynamic>> data =
        socketManager.weightRecordListNotifier.value;
    //_weightRecords = data;
    weightRecords = data;
    if (mounted) {
      setState(() {});
    }
  }

  void _configureSerialPort() {
    String portName = settingsData['scalePort'];
    _port = SerialPort(portName);

    if (!_availablePorts.contains(portName)) {
      setState(() {
        settingsData['scaleReading'] = '0.0';
        _scaleReading = 'Error: Port $portName does not exist';
      });
      return;
    }

    try {
      _port.openReadWrite();

      if (_port.isOpen) {
        // Write data to port
        //int writtenBytes = _port.write(MyFunctions.stringToUint8List('Hello World!'));

        // Read data from port
        String scaleData = '';
        SerialPortReader reader = SerialPortReader(_port, timeout: 1000);
        Stream<String> dataStream = reader.stream.map((Uint8List data) {
          return String.fromCharCodes(data);
        });
        _subscription = dataStream.listen((String data) {
          scaleData = data;
          setState(() {
            _scaleReading = MyFunctions.formatScaleReading(scaleData);
            settingsData['scaleReading'] =
                _scaleReading; // save to settings data
            _outputController.text =
                _scaleReading; // Update the TextEditingController
          });
        });
      } else {
        throw Exception('port $portName could not be opened.');
      }
    } catch (e) {
      setState(() {
        settingsData['scaleReading'] = '0.0';
        _scaleReading = e.toString();
        _outputController.text = _scaleReading;
      });
    }
  }

  void clearNotifications() {
    if (notificationList.isNotEmpty) {
      var data = jsonEncode({
        'notifications': notificationList,
        'userId': currentUser["userId"] ?? 1,
      });
      socketManager.sendMessage('delete_notifications', data);
    }
  }

  // Properly dispose the timer on screen exit
  @override
  void dispose() {
    _timer?.cancel();
    currentPage = '';
    _subscription?.cancel();
    _port.close();
    _vehicleIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.78,
                height: 100.0,
                child: Column(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _outputController,
                      //initialValue: _scaleReading,
                      readOnly: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28.0,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                          labelText: "Current Scale Reading",
                          enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                            color: Colors.black,
                          )),
                          focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                            color: Colors.black,
                          )),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(),
                            borderRadius: BorderRadius.circular(8.0),
                          )),
                    ),
                  ),
                  SizedBox(
                      height: 40.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                              onPressed: currentUser['permissions']
                                      ['canAddWeightRecord']
                                  ? verifyRecord
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                elevation: 10.0,
                              ),
                              child: const Text('Record weight')),
                          const SizedBox(width: 1.0),
                        ],
                      )),
                ])),
            const SizedBox(
              height: 60.0,
            ),
            Expanded(
                child: Center(
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    color: Colors.blueGrey,
                    child: Column(
                      children: [
                        const SizedBox(
                            height: 60.0,
                            child: Text(
                              "Recent Weight Records",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 28.0,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(5.0),
                            color: const Color(0xFFF8F8F8),
                            child: RecentItemsTableScreen(
                                //weightRecordsList: _weightRecords,
                                updateRecord: showWeightRecordForm),
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.3,
                        height: 40.0,
                        color: Theme.of(context).colorScheme.primary,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (MediaQuery.of(context).size.width > 800)
                              const Text(
                                'Notifications',
                                style: TextStyle(fontSize: 22.0),
                              ),
                            Stack(
                              children: [
                                Icon(
                                  Icons.notifications,
                                  size: 40.0,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                                if (notificationCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2.0, vertical: 2.0),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        maxWidth: 62,
                                        maxHeight: 17,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$notificationCount',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            InkWell(
                              mouseCursor: SystemMouseCursors.click,
                              onTap: markAllAsRead,
                              child: Icon(
                                Icons.visibility,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 40.0,
                              ),
                            ),
                            InkWell(
                              mouseCursor: SystemMouseCursors.click,
                              onTap: () async {
                                final confirm = await showDeleteConfirmation(
                                    context,
                                    'Are you sure you want to delete all notifications?');
                                if (confirm) {
                                  clearNotifications();
                                }
                              },
                              child: Icon(
                                Icons.clear_all,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 40.0,
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: notificationList.length,
                          itemBuilder: (context, index) {
                            return NotificationItem(
                              index: index,
                              onPressed: updateNotificationCount,
                              notificationList: notificationList,
                            );
                          },
                        ),
                      )
                    ]),
                  )
                ],
              ),
            )),
          ],
        ));
  }
}

// Create recent items table
class RecentItemsTableScreen extends StatefulWidget {
  //final List<Map<String, dynamic>> weightRecordsList;
  final Function(Map<String, dynamic>, String) updateRecord;
  const RecentItemsTableScreen(
      {super.key,
      //required this.weightRecordsList,
      required this.updateRecord});

  @override
  State<RecentItemsTableScreen> createState() => _RecentItemsTableScreenState();
}

class _RecentItemsTableScreenState extends State<RecentItemsTableScreen> {
  final SocketManager socketManager = SocketManager();

  // create a function that emits socket communication
  void getNotifications() {
    // Emit a message to the server
    socketManager.sendMessage(
        'request_notifications', 'Give me notications data.');
  }

  @override
  Widget build(BuildContext context) {
    final weightRecordsProvider = context.watch<WeightRecordsProvider>();
    bool smallScreen = MediaQuery.of(context).size.width < 700;
    bool mediumScreen = MediaQuery.of(context).size.width < 1000;
    return weightRecordsProvider.weightRecordsList.isEmpty
        ? const Center(
            child: Text(
              'No records found!',
              style: TextStyle(
                color: Color(0xaa000000),
                fontSize: 18.0,
              ),
            ),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columnSpacing: 16.0,
              columns: [
                DataColumn(label: _tableHeader('Vehicle ID')),
                if (!smallScreen)
                  DataColumn(label: _tableHeader('Entry Weight')),
                if (!smallScreen)
                  DataColumn(label: _tableHeader('Exit Weight')),
                if (!mediumScreen)
                  DataColumn(label: _tableHeader('Net Weight')),
                DataColumn(label: _tableHeader('Status')),
                DataColumn(label: _tableHeader('')),
              ],
              rows: weightRecordsProvider.weightRecordsList
                  .take(10)
                  .toList()
                  .map((record) {
                return DataRow(
                  color: weightRecordsProvider.weightRecordsList
                          .indexOf(record)
                          .isEven
                      ? WidgetStateProperty.all(Colors.grey[200])
                      : null,
                  cells: [
                    DataCell(Text(
                      record['vehicleId'],
                      style: const TextStyle(color: Color(0xff000000)),
                    )),
                    if (!smallScreen)
                      DataCell(Text(
                        record['initialWeight'].toString(),
                        style: const TextStyle(color: Color(0xff000000)),
                      )),
                    if (!smallScreen)
                      DataCell(Text(
                        record['finalWeight'].toString(),
                        style: const TextStyle(color: Color(0xff000000)),
                      )),
                    if (!mediumScreen)
                      DataCell(Text(
                        MyFunctions.subtractAndFormat(
                            record['finalWeight'], record['initialWeight']),
                        style: const TextStyle(color: Color(0xff000000)),
                      )),
                    DataCell(
                      Center(
                        child: Tooltip(
                          message: record['waybillRecord']['remarks'] ?? '',
                          child: Icon(
                            record['approvalStatus'] == 'pending'
                                ? Icons.pending
                                : record['approvalStatus'] == 'approved'
                                    ? Icons.check_circle
                                    : Icons.cancel,
                            color: record['approvalStatus'] == 'pending'
                                ? Colors.orange
                                : record['approvalStatus'] == 'approved'
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: record['finalWeight'] != null
                            ? showPrintMenu(record)
                            : currentUser['permissions']['canAddWeightRecord']
                                ? IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      widget.updateRecord(
                                          record, record['vehicleId']);
                                    },
                                  )
                                : const SizedBox(),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
  }

  // Design the table header text
  Widget _tableHeader(String title) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.07,
      child: Center(
        child: Text(
          title,
          softWrap: true,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xff000000),
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget showPrintMenu(Map<String, dynamic> ticketData) {
    return Builder(
      builder: (BuildContext context) {
        return IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _showContextMenu(context, ticketData);
          },
          tooltip: 'Click to show options',
        );
      },
    );
  }

  void _showContextMenu(
      BuildContext context, Map<String, dynamic> ticketData) async {
    // final RenderBox overlay =
    //     Overlay.of(context).context.findRenderObject() as RenderBox;

    final result = await showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(
        //overlay.size.width -
        1000, // Adjust this to position the menu where you want it
        380, // Adjust this to set the vertical position
        330,
        0,
      ),
      elevation: 5.0,
      items: [
        // add header
        PopupMenuItem(
          value: '',
          enabled: false,
          child: Text(ticketData['vehicleId'],
              style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0)),
        ),
        const PopupMenuItem(
          value: 'ticket',
          child: Text('Print Ticket'),
        ),
        if (ticketData['waybillReady'])
          const PopupMenuItem(
            value: 'waybill',
            child: Text('Print Waybill'),
          ),
      ],
    );

    if (result != null) {
      _handleSelection(result, ticketData);
    }
  }

  void _handleSelection(String result, Map<String, dynamic> ticketData) {
    if (result == 'ticket') {
      printTicket(ticketData, settingsData['ticketHeaderImage']);
    } else if (result == 'waybill') {
      printWaybill(
          ticketData['waybillRecord'], settingsData['waybillHeaderImage']);
    }
  }
}

//create a notification instance class
class NotificationItem extends StatefulWidget {
  final void Function(Map<String, dynamic>) onPressed;
  final List<Map<String, dynamic>> notificationList;
  final int index;
  const NotificationItem({
    super.key,
    required this.index,
    required this.onPressed,
    required this.notificationList,
  });
  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  Color backgroundColor = const Color(0x11ff0000);
  FontWeight textWeight = FontWeight.bold;

  @override
  Widget build(BuildContext context) {
    final smallScreen = MediaQuery.of(context).size.width < 800;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 0.0),
      child: InkWell(
        onTap: () {
          widget.onPressed(widget.notificationList[widget.index]);
        },
        child: Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
              color: widget.notificationList[widget.index]['status'] == 'unread'
                  ? backgroundColor
                  : Colors.white,
              border: Border(
                  bottom: BorderSide(
                      color: Theme.of(context).colorScheme.tertiary))),
          width: MediaQuery.of(context).size.width * 0.25,
          //height: 60.0,
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  widget.notificationList[widget.index]['action'],
                  style: TextStyle(
                    color: const Color(0xff000000),
                    fontSize: smallScreen ? 9.0 : 12.0,
                    fontWeight: widget.notificationList[widget.index]
                                ['status'] ==
                            'unread'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  softWrap: true,
                  //maxLines: 3,
                  //overflow: TextOverflow.ellipsis,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: SizedBox(
                  height: 15.0,
                  child: Text(
                    formatDateTime(
                        widget.notificationList[widget.index]['time']),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: smallScreen ? 7.0 : 10.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
