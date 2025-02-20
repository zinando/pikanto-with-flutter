import 'package:flutter/material.dart';
import 'package:pikanto/helpers/my_functions.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:printing/printing.dart' as prt; // Alias the printing library
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class TicketView extends StatelessWidget {
  final String? headerImageUrl;
  final Map<String, dynamic> recordData;

  const TicketView({
    super.key,
    this.headerImageUrl,
    required this.recordData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weight Record Data For: ${recordData["vehicleId"]}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        //backgroundColor: Colors.grey[800],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 600.0, //printable width
            height: 900.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (headerImageUrl != null) ...[
                  Align(
                      alignment: Alignment.center,
                      child: Image.file(File(headerImageUrl!))),
                  //const SizedBox(height: 10.0),
                ],
                const SizedBox(height: 10.0),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    alignment: Alignment.center,
                    color: Colors.blue[500],
                    height: 50.0,
                    width: 400.0,
                    padding: const EdgeInsets.all(8.0),
                    child: const Text(
                      'Weight Record Slip',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Delivery Note', 'Duplicate'),
                _buildInfoDoubleRow('Date', recordData['initialTime'],
                    'Ticket No', recordData['weightRecordId'].toString()),
                _buildInfoDoubleRow('Vehicle Reg.', recordData['vehicleId'],
                    'Delivery No', recordData['deliveryNumber'] ?? ''),
                _buildInfoDoubleRow('Client', recordData['customerName'],
                    'Order Number', recordData['orderNumber']),
                _buildInfoDoubleRow('Haulier', recordData['haulierName'],
                    'Destination', recordData['destination']),
                _buildInfoRow('Product', recordData['product']),
                _buildInfoRow(
                    'Gross Mass',
                    MyFunctions.getMaxi(
                        recordData['initialWeight'],
                        recordData['finalWeight'],
                        recordData['initialTime'],
                        recordData['finalTime']),
                    width: 500.0),
                _buildInfoRow(
                    'Tare Mass',
                    MyFunctions.getMini(
                        recordData['initialWeight'],
                        recordData['finalWeight'],
                        recordData['initialTime'],
                        recordData['finalTime']),
                    width: 500.0),
                _buildInfoRow(
                    'Net Mass',
                    '${MyFunctions.subtractAndFormat(recordData['finalWeight'], recordData['initialWeight']).toString()}'
                        ' ${settingsData["scaleWeightUnit"]}'),
                const SizedBox(height: 10.0),
                _buildInfoDoubleRow('Driver\'s Name', recordData['driverName'],
                    "Driver's Signature", "______________"),
                const SizedBox(height: 30),
                if (currentUser['permissions']['canPrintTicket'])
                  Center(
                    child: Container(
                      color: Colors.grey[
                          200], // Background color to make the button stand out
                      padding: const EdgeInsets.all(
                          8.0), // Padding around the button
                      child: IconButton(
                        onPressed: _printTicket,
                        icon: const Icon(
                          Icons.print,
                          size: 30,
                        ), // Adjust icon color for better visibility
                        tooltip: 'Print Ticket', // Optional tooltip
                      ),
                    ),
                  ),
              ],
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

  Future<void> _printTicket() async {
    final pdf = pw.Document();

    // Load roboto font
    final fontRegular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/roboto/Roboto-Regular.ttf'));
    final fontBold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/roboto/Roboto-Bold.ttf'));
    final pw.MemoryImage? image = await _prepareImage();

    // Convert your widget to a PDF page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (image != null) ...[
                  pw.Image(image),
                  //pw.SizedBox(height: 20),
                ],
                pw.SizedBox(height: 20),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Weight Record Slip',
                    style: pw.TextStyle(
                      fontSize: 24,
                      font: fontBold,
                      color: const PdfColor.fromInt(0xFF2196F3),
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildPdfInfoRow('Delivery Note', 'Duplicate',
                    fontBold: fontBold, fontRegular: fontRegular),
                pw.SizedBox(height: 10.0),
                _buildPdfInfoDoubleRow('Date', recordData['initialTime'],
                    'Ticket No', recordData['weightRecordId'].toString(),
                    fontBold: fontBold, fontRegular: fontRegular),
                pw.SizedBox(height: 10.0),
                _buildPdfInfoDoubleRow('Vehicle Reg.', recordData['vehicleId'],
                    'Delivery No', recordData['deliveryNumber'] ?? '',
                    fontBold: fontBold, fontRegular: fontRegular),
                pw.SizedBox(height: 10.0),
                _buildPdfInfoDoubleRow('Client', recordData['customerName'],
                    'Order Number', recordData['orderNumber'],
                    fontBold: fontBold, fontRegular: fontRegular),
                pw.SizedBox(height: 10.0),
                _buildPdfInfoDoubleRow('Haulier', recordData['haulierName'],
                    'Destination', recordData['destination'],
                    fontBold: fontBold, fontRegular: fontRegular),
                pw.SizedBox(height: 10.0),
                _buildPdfInfoRow('Product', recordData['product'],
                    fontBold: fontBold, fontRegular: fontRegular),
                pw.SizedBox(height: 10.0),
                _buildPdfInfoRow(
                    'Gross Mass',
                    MyFunctions.getMaxi(
                        recordData['initialWeight'],
                        recordData['finalWeight'],
                        recordData['initialTime'],
                        recordData['finalTime']),
                    width: 500.0,
                    fontBold: fontBold,
                    fontRegular: fontRegular),
                pw.SizedBox(height: 10.0),
                _buildPdfInfoRow(
                    'Tare Mass',
                    MyFunctions.getMini(
                        recordData['initialWeight'],
                        recordData['finalWeight'],
                        recordData['initialTime'],
                        recordData['finalTime']),
                    width: 500.0,
                    fontBold: fontBold,
                    fontRegular: fontRegular),
                pw.SizedBox(height: 10.0),
                _buildPdfInfoRow(
                    'Net Mass',
                    '${MyFunctions.subtractAndFormat(recordData['finalWeight'], recordData['initialWeight']).toString()}'
                        ' ${settingsData["scaleWeightUnit"]}',
                    fontBold: fontBold,
                    fontRegular: fontRegular),
                pw.SizedBox(height: 10.0),
                _buildPdfInfoDoubleRow(
                    'Driver\'s Name',
                    recordData['driverName'],
                    "Driver's Signature",
                    "______________",
                    fontBold: fontBold,
                    fontRegular: fontRegular),
              ],
            ),
          );
        },
      ),
    );

    // Use the Printing package to print the document
    await prt.Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value,
      {double width = 230.0, pw.Font? fontBold, pw.Font? fontRegular}) {
    double fontSize = 12;
    return pw.Container(
      width: width,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontSize: fontSize,
              font: fontBold,
            ),
          ),
          //pw.SizedBox(width: 50.0),
          pw.Spacer(),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Expanded(
              child: pw.Text(
                value,
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
    double fontSize = 12;
    return pw.Row(
      children: [
        pw.Container(
          width: 230.0,
          child: pw.Row(
            children: [
              pw.Text(
                '$label1:',
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
                style: pw.TextStyle(
                  fontSize: fontSize,
                  font: fontBold,
                ),
              ),
              pw.Spacer(),
              pw.Text(
                value2,
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
