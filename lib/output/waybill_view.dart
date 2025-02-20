import 'package:flutter/material.dart';
import 'package:printing/printing.dart' as prt; // Alias the printing library
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'package:pikanto/resources/settings.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class WaybillView extends StatelessWidget {
  final String? headerImageUrl;
  final Map<String, dynamic> recordData; // Waybill data

  const WaybillView({
    super.key,
    this.headerImageUrl,
    required this.recordData,
  });

  @override
  Widget build(BuildContext context) {
    num totalQuantity = recordData['goodProducts']
        .map<num>((row) => row['quantity'] as num)
        .reduce((num a, num b) => a + b);
    num totalPackages = recordData['goodProducts']
        .map<num>((row) => row['numberOfPackages'] as num)
        .reduce((num a, num b) => a + b);
    num totalQuantityAccepted = recordData['goodProducts']
        .map<num>((row) => row['acceptedQuantity'] as num)
        .reduce((num a, num b) => a + b);
    // also calculate total gross quantity and total net quantity
    num totalGrossQuantity = recordData['goodProducts']
        .map<num>((row) => (row['grossQuantity'] ?? 0.0) as num)
        .reduce((num a, num b) => a + b);
    num totalNetQuantity = recordData['goodProducts']
        .map<num>((row) => (row['netQuantity'] ?? 0.0) as num)
        .reduce((num a, num b) => a + b);
    return Scaffold(
      appBar: AppBar(
        title: Text('Waybill Data For: ${recordData["vehicleId"]}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        //backgroundColor: Colors.grey[800],
      ),
      body: Center(
        child: SizedBox(
          height: 700.0,
          child: SingleChildScrollView(
            child: SizedBox(
              width: 600.0, //printable width

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (headerImageUrl != null) ...[
                    Align(
                        alignment: Alignment.center,
                        child: Image.file(File(headerImageUrl!))),
                    Divider(
                      color: Colors.grey[500],
                      thickness: 2,
                      indent: 20,
                      endIndent: 20,
                    ),
                  ],
                  if (headerImageUrl != null) ...[],
                  const SizedBox(height: 10.0),
                  if (headerImageUrl == null) ...[
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        alignment: Alignment.center,
                        color: Colors.blue[600],
                        height: 50.0,
                        width: 400.0,
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          'WAYBILL DATA',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  ],

                  const SizedBox(height: 20),

                  _buildInfoDoubleRow(
                    'Waybill No',
                    recordData['waybillNumber'],
                    'Date',
                    recordData['date'],
                  ),
                  _buildInfoDoubleRow(
                      'Company Ref No',
                      recordData['companyRef'] ?? '',
                      'Location',
                      recordData['location'] ?? ''),
                  _buildInfoDoubleRow(
                      'Customer Name',
                      recordData['customerName'],
                      'Customer Ref No',
                      recordData['customerRef'] ?? ''),
                  _buildInfoRow(
                      'Delivery Address', recordData['deliveryAddress'] ?? ''),
                  _buildInfoDoubleRow(
                    'Vehicle No',
                    recordData['vehicleId'],
                    'Transporter',
                    recordData['haulierName'],
                  ),
                  // create table for product details here:
                  SizedBox(
                    height: (202.0 + 60.0 * recordData['goodProducts'].length)
                        .toDouble(),
                    width: double.infinity,
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.center,
                          //color: Colors.blue[600],
                          height: 50.0,
                          width: 400.0,
                          padding: const EdgeInsets.all(8.0),
                          child: const Text(
                            'Product Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        // Header Row
                        Table(
                          border: TableBorder.all(),
                          columnWidths: const {
                            0: FlexColumnWidth(1), // S/N
                            1: FlexColumnWidth(
                                2), // Product description (double width)
                            //2: FlexColumnWidth(1), // Item code
                            2: FlexColumnWidth(1), // No of packages
                            3: FlexColumnWidth(1), // Quantity
                            4: FlexColumnWidth(1), // Accepted quantity
                            5: FlexColumnWidth(1), // Remarks
                          },
                          children: const [
                            TableRow(
                              decoration: BoxDecoration(color: Colors.white),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'S/N',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Product description',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                /*Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Item code',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),*/
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'No of packages\n'
                                    '(Bags/Boxes)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Gross Quantity\n'
                                    '(MT/NOs)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Net quantity',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Remarks',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Data Rows
                        Expanded(
                          child: SingleChildScrollView(
                            child: Table(
                              border: TableBorder.all(),
                              columnWidths: const {
                                0: FlexColumnWidth(1),
                                1: FlexColumnWidth(2),
                                //2: FlexColumnWidth(1),
                                2: FlexColumnWidth(1),
                                3: FlexColumnWidth(1),
                                4: FlexColumnWidth(1),
                                5: FlexColumnWidth(1),
                              },
                              children: List.generate(
                                  recordData['goodProducts'].length, (index) {
                                final row = recordData['goodProducts'][index];
                                return TableRow(
                                  decoration: BoxDecoration(
                                      color: index.isEven
                                          ? Colors.grey[200]
                                          : Colors.white),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        '${index + 1}', // S/N
                                        style: const TextStyle(
                                            color: Colors.black),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        row['productDescription'].toString(),
                                        style: const TextStyle(
                                            color: Colors.black),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    /*Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        row['itemCode'].toString(),
                                        style: const TextStyle(
                                            color: Colors.black),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),*/
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        row['numberOfPackages'].toString(),
                                        style: const TextStyle(
                                            color: Colors.black),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        row['grossQuantity'].toString(),
                                        style: const TextStyle(
                                            color: Colors.black),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        row['netQuantity'].toString(),
                                        style: const TextStyle(
                                            color: Colors.black),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        row['remarks'].toString()
                                        //.trim()
                                        //.substring(0, 3)
                                        ,
                                        style: const TextStyle(
                                            color: Colors.black),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                        // Footer Row
                        Table(
                          border: TableBorder.all(),
                          columnWidths: const {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(2),
                            //2: FlexColumnWidth(1),
                            2: FlexColumnWidth(1),
                            3: FlexColumnWidth(1),
                            4: FlexColumnWidth(1),
                            5: FlexColumnWidth(1),
                          },
                          children: [
                            TableRow(
                              decoration:
                                  const BoxDecoration(color: Colors.white),
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Total:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    '',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                /*const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    '',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),*/
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    totalPackages.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    totalGrossQuantity.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    totalNetQuantity.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    '',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Remarks to be mentioned by Receiver:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'MATERIAL RECEIVED IN GOOD AND ACCEPTABLE CONDITION?',
                        style: TextStyle(
                          fontSize: 14,
                          //fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 15.0),
                      Text(
                        recordData['badProducts'].length == 0 ? 'Yes' : 'No',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  // create table for bad product details here if any: product description, damaged quantity, shortage quantity, batch number
                  if (recordData['badProducts'].length != 0)
                    SizedBox(
                      height: (102.0 + 60.0 * recordData['badProducts'].length)
                          .toDouble(),
                      width: double.infinity,
                      child: Column(
                        children: [
                          Container(
                            alignment: Alignment.center,
                            height: 50.0,
                            width: 400.0,
                            padding: const EdgeInsets.all(8.0),
                            child: const Text(
                              'Damaged Product Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),

                          // Header Row
                          Table(
                            //border: TableBorder.all(),
                            columnWidths: const {
                              0: FlexColumnWidth(1), // S/N
                              1: FlexColumnWidth(
                                  2), // Product description (double width)
                              2: FlexColumnWidth(1), // shortage qty
                              3: FlexColumnWidth(1), // damaged qty
                              4: FlexColumnWidth(1), // batch number
                            },
                            children: [
                              TableRow(
                                decoration:
                                    BoxDecoration(color: Colors.grey[300]),
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'S/N',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Product description',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Damaged Qty',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Shortage Qty',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Batch Number',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Data Rows
                          Expanded(
                            child: SingleChildScrollView(
                              child: Table(
                                //border: TableBorder.all(),
                                columnWidths: const {
                                  0: FlexColumnWidth(1),
                                  1: FlexColumnWidth(2),
                                  2: FlexColumnWidth(1),
                                  3: FlexColumnWidth(1),
                                  4: FlexColumnWidth(1),
                                },
                                children: List.generate(
                                    recordData['badProducts'].length, (index) {
                                  final row = recordData['badProducts'][index];
                                  return TableRow(
                                    decoration: BoxDecoration(
                                        color: index.isEven
                                            ? Colors.grey[100]
                                            : Colors.white),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          '${index + 1}', // S/N
                                          style: const TextStyle(
                                              color: Colors.black),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          row['productDescription'].toString(),
                                          style: const TextStyle(
                                              color: Colors.black),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          row['damagedQuantity'].toString(),
                                          style: const TextStyle(
                                              color: Colors.black),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          row['shortageQuantity'].toString(),
                                          style: const TextStyle(
                                              color: Colors.black),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          row['batchNumber'].toString(),
                                          style: const TextStyle(
                                              color: Colors.black),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                          // Footer Row
                          /*Table(
                            border: TableBorder.all(),
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(1),
                              3: FlexColumnWidth(1),
                              4: FlexColumnWidth(1),
                              5: FlexColumnWidth(1),
                              6: FlexColumnWidth(1),
                            },
                            children: [
                              TableRow(
                                decoration:
                                    const BoxDecoration(color: Colors.white),
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Total:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      totalPackages.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      totalQuantity.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      totalQuantityAccepted.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),*/
                        ],
                      ),
                    ),

                  const SizedBox(
                    height: 20,
                  ),
                  // Authorization Column

                  SizedBox(
                    width: 600.0,
                    child: Table(
                      border: TableBorder.all(),
                      columnWidths: const {
                        0: FlexColumnWidth(1), // Received by
                        1: FlexColumnWidth(1), // delivered by
                        2: FlexColumnWidth(1), // Approved by
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(color: Colors.white),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Prepared By',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                  _buildInfoRow(
                                      'Name', recordData['preparedBy'] ?? ''),
                                  _buildInfoRow(
                                      'Date', recordData['date'] ?? ''),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Transporter',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                  _buildInfoRow(
                                      'Name', recordData['driverName'] ?? ''),
                                  _buildInfoRow(
                                      'Date', recordData['date'] ?? ''),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Approved By',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                  _buildInfoRow(
                                      'Name',
                                      recordData['approvalStatus'] == 'approved'
                                          ? recordData['approvedBy']
                                          : recordData['approvalStatus']),
                                  _buildInfoRow(
                                      'Date',
                                      recordData['approvalStatus'] == 'approved'
                                          ? recordData['approvalTime']
                                          : ''),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (currentUser['permissions']['canPrintWaybill'])
                    Center(
                      child: Container(
                        color: Colors.grey[
                            200], // Background color to make the button stand out
                        padding: const EdgeInsets.all(
                            8.0), // Padding around the button
                        child: IconButton(
                          onPressed: _printWaybill,
                          icon: const Icon(
                            Icons.print,
                            size: 30,
                          ), // Adjust icon color for better visibility
                          tooltip: 'Print Waybill', // Optional tooltip
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {double width = 250.0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      child: SizedBox(
        width: width,
        child: Row(
          children: [
            Text(
              '$label:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoDoubleRow(
      String label1, String value1, String label2, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
            width: 250.0,
            child: Row(
              children: [
                Text(
                  '$label1:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Expanded(
                  child: Text(
                    value1,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 250.0,
            child: Row(
              children: [
                Text(
                  '$label2:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Expanded(
                  child: Text(
                    value2,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printWaybill() async {
    final pdf = pw.Document();

    // Load roboto font
    final fontRegular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/roboto/Roboto-Regular.ttf'));
    final fontBold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/roboto/Roboto-Bold.ttf'));
    final pw.MemoryImage? image = await _prepareImage();

    // Convert the build function to a pdf
    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          num totalQuantity = recordData['goodProducts']
              .map<num>((row) => row['quantity'] as num)
              .reduce((num a, num b) => a + b);
          num totalPackages = recordData['goodProducts']
              .map<num>((row) => row['numberOfPackages'] as num)
              .reduce((num a, num b) => a + b);
          num totalQuantityAccepted = recordData['goodProducts']
              .map<num>((row) => row['acceptedQuantity'] as num)
              .reduce((num a, num b) => a + b);
          // also calculate total gross quantity and total net quantity
          num totalGrossQuantity = recordData['goodProducts']
              .map<num>((row) => (row['grossQuantity'] ?? 0.0) as num)
              .reduce((num a, num b) => a + b);
          num totalNetQuantity = recordData['goodProducts']
              .map<num>((row) => (row['netQuantity'] ?? 0.0) as num)
              .reduce((num a, num b) => a + b);
          return <pw.Widget>[
            pw.Container(
              child: pw.Column(
                //mainAxisAlignment: pw.MainAxisAlignment.start,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (image != null) ...[
                    pw.Image(image),
                    pw.Divider(
                      color: const PdfColor.fromInt(0xFF2196F3),
                      thickness: 2,
                      indent: 20,
                      endIndent: 20,
                    ),
                  ],
                  if (image == null) ...[
                    pw.SizedBox(height: 20),
                    pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'WAYBILL DATA',
                        style: pw.TextStyle(
                          fontSize: 16,
                          font: fontBold,
                          color: const PdfColor.fromInt(0xFF2196F3),
                        ),
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 20),
                  _buildPdfInfoDoubleRow(
                      'Waybill No',
                      recordData['waybillNumber'].toString(),
                      'Date',
                      recordData['date'].toString(),
                      fontBold: fontBold,
                      fontRegular: fontRegular),
                  pw.SizedBox(height: 10.0),
                  _buildPdfInfoDoubleRow(
                      'company Ref No',
                      recordData['companyRef'] ?? '',
                      'Location',
                      recordData['location'] ?? '',
                      fontBold: fontBold,
                      fontRegular: fontRegular),
                  pw.SizedBox(height: 10.0),
                  _buildPdfInfoDoubleRow(
                      'Customer Name',
                      recordData['customerName'].toString(),
                      'customer Ref No',
                      recordData['customerRef'].toString(),
                      fontBold: fontBold,
                      fontRegular: fontRegular),
                  pw.SizedBox(height: 10.0),
                  _buildPdfInfoRow('Delivery Address',
                      recordData['deliveryAddress'].toString(),
                      fontBold: fontBold, fontRegular: fontRegular),
                  pw.SizedBox(height: 10.0),
                  _buildPdfInfoDoubleRow(
                      'Vehicle No',
                      recordData['vehicleId'].toString(),
                      'Transporter',
                      recordData['haulierName'].toString(),
                      fontBold: fontBold,
                      fontRegular: fontRegular),
                  pw.SizedBox(height: 10.0),
                  // create table for product details here:
                  pw.SizedBox(
                    height: (202.0 + 60.0 * recordData['goodProducts'].length)
                        .toDouble(),
                    width: double.infinity,
                    child: pw.Column(
                      children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          height: 50.0,
                          width: 400.0,
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            'Product Details',
                            style: pw.TextStyle(
                              fontSize: 14,
                              font: fontBold,
                              color: const PdfColor.fromInt(0x00000000),
                            ),
                          ),
                        ),

                        // Header Row
                        pw.Table(
                          border: pw.TableBorder.all(),
                          columnWidths: const {
                            0: pw.FlexColumnWidth(1), // S/N
                            1: pw.FlexColumnWidth(
                                2), // Product description (double width)
                            //2: pw.FlexColumnWidth(1), // Item code
                            2: pw.FlexColumnWidth(1), // No of packages
                            3: pw.FlexColumnWidth(1), // Gross Quantity
                            4: pw.FlexColumnWidth(1), // net quantity
                            5: pw.FlexColumnWidth(1), // Remarks
                          },
                          children: [
                            pw.TableRow(
                              decoration: const pw.BoxDecoration(
                                  color: PdfColor.fromInt(0x00ffffff)),
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'S/N',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 12.0,
                                        color:
                                            const PdfColor.fromInt(0xFF2196F3)),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'Product description',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 12.0,
                                        color:
                                            const PdfColor.fromInt(0xFF2196F3)),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                /*pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'Item code',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 12.0,
                                        color:
                                            const PdfColor.fromInt(0xFF2196F3)),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),*/
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'No of packages\n'
                                    '(Bags/Boxes)',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 12.0,
                                        color:
                                            const PdfColor.fromInt(0xFF2196F3)),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'Gross Quantity\n'
                                    '(MT/NOs)',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 12.0,
                                        color:
                                            const PdfColor.fromInt(0xFF2196F3)),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'Net Quantity',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 12.0,
                                        color:
                                            const PdfColor.fromInt(0xFF2196F3)),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'Remarks',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 12.0,
                                        color:
                                            const PdfColor.fromInt(0xFF2196F3)),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Data Rows
                        pw.Expanded(
                          child: pw.Table(
                            border: pw.TableBorder.all(),
                            columnWidths: const {
                              0: pw.FlexColumnWidth(1),
                              1: pw.FlexColumnWidth(2),
                              //2: pw.FlexColumnWidth(1),
                              2: pw.FlexColumnWidth(1),
                              3: pw.FlexColumnWidth(1),
                              4: pw.FlexColumnWidth(1),
                              5: pw.FlexColumnWidth(1),
                            },
                            children: List.generate(
                                recordData['goodProducts'].length, (index) {
                              final row = recordData['goodProducts'][index];
                              return pw.TableRow(
                                decoration: pw.BoxDecoration(
                                    color: index.isEven
                                        ? const PdfColor.fromInt(0xFFEEEEEE)
                                        : const PdfColor.fromInt(0xFFFFFFFF)),
                                children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: pw.Text(
                                      '${index + 1}', // S/N
                                      style: const pw.TextStyle(
                                        fontSize: 12.0,
                                        color: PdfColor.fromInt(0xff000000),
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: pw.Text(
                                      row['productDescription'].toString(),
                                      style: const pw.TextStyle(
                                        fontSize: 12.0,
                                        color: PdfColor.fromInt(0xff000000),
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  /*pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: pw.Text(
                                      row['itemCode'].toString(),
                                      style: const pw.TextStyle(
                                        fontSize: 12.0,
                                        color: PdfColor.fromInt(0xff000000),
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),*/
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: pw.Text(
                                      row['numberOfPackages'].toString(),
                                      style: const pw.TextStyle(
                                        fontSize: 12.0,
                                        color: PdfColor.fromInt(0xff000000),
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: pw.Text(
                                      row['grossQuantity'].toString(),
                                      style: const pw.TextStyle(
                                        fontSize: 12.0,
                                        color: PdfColor.fromInt(0xff000000),
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: pw.Text(
                                      row['netQuantity'].toString(),
                                      style: const pw.TextStyle(
                                        fontSize: 12.0,
                                        color: PdfColor.fromInt(0xff000000),
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: pw.Text(
                                      row['remarks'].toString(),
                                      style: const pw.TextStyle(
                                        fontSize: 12.0,
                                        color: PdfColor.fromInt(0xff000000),
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                        // Footer Row
                        pw.Table(
                          border: pw.TableBorder.all(),
                          columnWidths: const {
                            0: pw.FlexColumnWidth(1),
                            1: pw.FlexColumnWidth(2),
                            //2: pw.FlexColumnWidth(1),
                            2: pw.FlexColumnWidth(1),
                            3: pw.FlexColumnWidth(1),
                            4: pw.FlexColumnWidth(1),
                            5: pw.FlexColumnWidth(1),
                          },
                          children: [
                            pw.TableRow(
                              decoration: const pw.BoxDecoration(
                                  color: PdfColor.fromInt(0xffffffff)),
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'Total:',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 12.0,
                                      color: const PdfColor.fromInt(0xff000000),
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    '',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 12.0,
                                      color: const PdfColor.fromInt(0xff000000),
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                /*pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    '',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 12.0,
                                      color: const PdfColor.fromInt(0xff000000),
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),*/
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    totalPackages.toString(),
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 12.0,
                                      color: const PdfColor.fromInt(0xff000000),
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    totalGrossQuantity.toString(),
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 12.0,
                                      color: const PdfColor.fromInt(0xff000000),
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    totalNetQuantity.toString(),
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 12.0,
                                      color: const PdfColor.fromInt(0xff000000),
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    '',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 12.0,
                                      color: const PdfColor.fromInt(0xff000000),
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Remarks to be mentioned by Receiver:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      font: fontBold,
                      color: const PdfColor.fromInt(0xff000000),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    children: [
                      pw.Text(
                        'MATERIAL RECEIVED IN GOOD AND ACCEPTABLE CONDITION?',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColor.fromInt(0xff000000),
                        ),
                      ),
                      pw.SizedBox(width: 15.0),
                      pw.Text(
                        recordData['badProducts'].length == 0 ? 'Yes' : 'No',
                        style: pw.TextStyle(
                          fontSize: 12,
                          font: fontBold,
                          color: const PdfColor.fromInt(0xff000000),
                        ),
                      ),
                    ],
                  ),
                  // create table for bad product details here if any: product description, damaged quantity, shortage quantity, batch number
                  if (recordData['badProducts'].length != 0)
                    pw.SizedBox(
                      height: (102.0 + 60.0 * recordData['badProducts'].length)
                          .toDouble(),
                      width: double.infinity,
                      child: pw.Column(
                        children: [
                          pw.Container(
                            alignment: pw.Alignment.center,
                            height: 50.0,
                            width: 400.0,
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(
                              'Damaged Product Details',
                              style: pw.TextStyle(
                                fontSize: 14,
                                font: fontBold,
                                color: const PdfColor.fromInt(0x00000000),
                              ),
                            ),
                          ),

                          // Header Row
                          pw.Table(
                            columnWidths: const {
                              0: pw.FlexColumnWidth(1), // S/N
                              1: pw.FlexColumnWidth(
                                  2), // Product description (double width)
                              2: pw.FlexColumnWidth(1), // shortage qty
                              3: pw.FlexColumnWidth(1), // damaged qty
                              4: pw.FlexColumnWidth(1), // batch number
                            },
                            children: [
                              pw.TableRow(
                                decoration: const pw.BoxDecoration(
                                    color: PdfColor.fromInt(0x00ffffff)),
                                children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: pw.Text(
                                      'S/N',
                                      style: pw.TextStyle(
                                          font: fontBold,
                                          fontSize: 12.0,
                                          color: const PdfColor.fromInt(
                                              0xff2196f3)),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: pw.Text(
                                      'Product Description',
                                      style: pw.TextStyle(
                                          font: fontBold,
                                          fontSize: 12.0,
                                          color: const PdfColor.fromInt(
                                              0xff2196f3)),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: pw.Text(
                                      'Damaged Qty',
                                      style: pw.TextStyle(
                                          font: fontBold,
                                          fontSize: 12.0,
                                          color: const PdfColor.fromInt(
                                              0xff2196f3)),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: pw.Text(
                                      'Shortage Qty',
                                      style: pw.TextStyle(
                                          font: fontBold,
                                          fontSize: 12.0,
                                          color: const PdfColor.fromInt(
                                              0xff2196f3)),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: pw.Text(
                                      'Batch Number',
                                      style: pw.TextStyle(
                                          font: fontBold,
                                          fontSize: 12.0,
                                          color: const PdfColor.fromInt(
                                              0xff2196f3)),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Data Rows
                          pw.Expanded(
                            child: pw.Table(
                              columnWidths: const {
                                0: pw.FlexColumnWidth(1),
                                1: pw.FlexColumnWidth(2),
                                2: pw.FlexColumnWidth(1),
                                3: pw.FlexColumnWidth(1),
                                4: pw.FlexColumnWidth(1),
                              },
                              children: List.generate(
                                  recordData['badProducts'].length, (index) {
                                final row = recordData['badProducts'][index];
                                return pw.TableRow(
                                  decoration: pw.BoxDecoration(
                                      color: index.isEven
                                          ? const PdfColor.fromInt(0xffEEEEEE)
                                          : const PdfColor.fromInt(0xffffffff)),
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8.0),
                                      child: pw.Text(
                                        '${index + 1}', // S/N
                                        style: const pw.TextStyle(
                                            fontSize: 12.0,
                                            color:
                                                PdfColor.fromInt(0xff000000)),
                                        textAlign: pw.TextAlign.center,
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8.0),
                                      child: pw.Text(
                                        row['productDescription'].toString(),
                                        style: const pw.TextStyle(
                                            fontSize: 12.0,
                                            color:
                                                PdfColor.fromInt(0xff000000)),
                                        textAlign: pw.TextAlign.center,
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8.0),
                                      child: pw.Text(
                                        row['damagedQuantity'].toString(),
                                        style: const pw.TextStyle(
                                            fontSize: 12.0,
                                            color:
                                                PdfColor.fromInt(0xff000000)),
                                        textAlign: pw.TextAlign.center,
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8.0),
                                      child: pw.Text(
                                        row['shortageQuantity'].toString(),
                                        style: const pw.TextStyle(
                                            fontSize: 12.0,
                                            color:
                                                PdfColor.fromInt(0xff000000)),
                                        textAlign: pw.TextAlign.center,
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8.0),
                                      child: pw.Text(
                                        row['batchNumber'].toString(),
                                        style: const pw.TextStyle(
                                            fontSize: 12.0,
                                            color:
                                                PdfColor.fromInt(0xff000000)),
                                        textAlign: pw.TextAlign.center,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                          // Footer Row
                          /*Table(
                            border: TableBorder.all(),
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(1),
                              3: FlexColumnWidth(1),
                              4: FlexColumnWidth(1),
                              5: FlexColumnWidth(1),
                              6: FlexColumnWidth(1),
                            },
                            children: [
                              TableRow(
                                decoration:
                                    const BoxDecoration(color: Colors.white),
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Total:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      totalPackages.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      totalQuantity.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      totalQuantityAccepted.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),*/
                        ],
                      ),
                    ),

                  pw.SizedBox(
                    height: 10,
                  ),
                  // Authorization Column
                  pw.SizedBox(
                    width: 600.0,
                    child: pw.Table(
                      border: pw.TableBorder.all(),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(1), // Received by
                        1: pw.FlexColumnWidth(1), // delivered by
                        2: pw.FlexColumnWidth(1), // Approved by
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                              color: PdfColor.fromInt(0xffffffff)),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Column(
                                children: [
                                  pw.Text(
                                    'Prepared By',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 12.0,
                                        color:
                                            const PdfColor.fromInt(0xff000000)),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                  pw.SizedBox(height: 4.0),
                                  _buildPdfInfoRowForAut(
                                      'Name', recordData['preparedBy'] ?? ''),
                                  pw.SizedBox(height: 4.0),
                                  _buildPdfInfoRowForAut(
                                      'Date', recordData['date'] ?? ''),
                                ],
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Column(
                                children: [
                                  pw.Text(
                                    'Transporter',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 12.0,
                                        color:
                                            const PdfColor.fromInt(0xff000000)),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                  pw.SizedBox(height: 4.0),
                                  _buildPdfInfoRowForAut(
                                      'Name', recordData['driverName'] ?? ''),
                                  pw.SizedBox(height: 4.0),
                                  _buildPdfInfoRowForAut(
                                      'Date', recordData['date'] ?? ''),
                                ],
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Column(
                                children: [
                                  pw.Text(
                                    'Approved By',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 12.0,
                                        color:
                                            const PdfColor.fromInt(0xff000000)),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                  pw.SizedBox(height: 4.0),
                                  _buildPdfInfoRowForAut(
                                      'Name',
                                      recordData['approvalStatus'] == 'approved'
                                          ? recordData['approvedBy']
                                          : recordData['approvalStatus']),
                                  pw.SizedBox(height: 4.0),
                                  _buildPdfInfoRowForAut(
                                      'Date',
                                      recordData['approvalStatus'] == 'approved'
                                          ? recordData['approvalTime']
                                          : ''),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        }));

    //// Use the Printing package to print the document
    await prt.Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value,
      {double width = 230.0, pw.Font? fontBold, pw.Font? fontRegular}) {
    double fontSize = 12.0;
    return pw.Container(
      width: width,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label:',
            maxLines: 2,
            overflow: pw.TextOverflow.span,
            softWrap: true,
            style: pw.TextStyle(
              fontSize: fontSize,
              font: fontBold,
            ),
          ),
          pw.Spacer(),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Expanded(
              child: pw.Text(
                value,
                maxLines: 2,
                overflow: pw.TextOverflow.span,
                softWrap: true,
                style: pw.TextStyle(
                  fontSize: fontSize,
                  font: fontRegular,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  pw.Widget _buildPdfInfoDoubleRow(
      String label1, String value1, String label2, String value2,
      {pw.Font? fontBold, pw.Font? fontRegular}) {
    double fontSize = 12.0;
    return pw.Row(
      children: [
        pw.Container(
          width: 230.0,
          child: pw.Row(
            children: [
              pw.Text(
                '$label1:',
                maxLines: 2,
                overflow: pw.TextOverflow.span,
                softWrap: true,
                style: pw.TextStyle(
                  fontSize: fontSize,
                  font: fontBold,
                ),
              ),
              pw.Spacer(),
              pw.Text(
                value1,
                style: pw.TextStyle(
                  fontSize: fontSize,
                  font: fontRegular,
                ),
              )
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Container(
          width: 230.0,
          child: pw.Row(
            children: [
              pw.Text(
                '$label2:',
                maxLines: 2,
                overflow: pw.TextOverflow.span,
                softWrap: true,
                style: pw.TextStyle(
                  fontSize: fontSize,
                  font: fontBold,
                ),
              ),
              pw.Spacer(),
              pw.Text(
                value2,
                maxLines: 2,
                overflow: pw.TextOverflow.span,
                softWrap: true,
                style: pw.TextStyle(
                  fontSize: fontSize,
                  font: fontRegular,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfInfoRowForAut(String label, String value,
      {double width = 230.0, pw.Font? fontBold, pw.Font? fontRegular}) {
    double fontSize = 10.0;
    return pw.Container(
      width: width,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label:',
            maxLines: 2,
            overflow: pw.TextOverflow.span,
            softWrap: true,
            style: pw.TextStyle(
              fontSize: fontSize,
              font: fontBold,
            ),
          ),
          pw.SizedBox(width: 20),
          //pw.Spacer(),
          pw.SizedBox(
            width: 110.0,
            child: pw.Text(
              value,
              maxLines: 2,
              overflow: pw.TextOverflow.span,
              softWrap: true,
              style: pw.TextStyle(
                fontSize: fontSize,
                font: fontRegular,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<pw.MemoryImage?> _prepareImage() async {
    // Check if headerImageUrl is null or empty
    if (headerImageUrl == null || headerImageUrl!.isEmpty) {
      return null; // Return null if the path is not valid
    }

    final File imageFile = File(headerImageUrl!);

    // Check if the file exists
    if (!await imageFile.exists()) {
      return null; // Return null if the file doesn't exist
    }

    // Read the image file as bytes
    final Uint8List bytes = await imageFile.readAsBytes();

    // Return the image as a pw.MemoryImage
    return pw.MemoryImage(bytes);
  }
}
