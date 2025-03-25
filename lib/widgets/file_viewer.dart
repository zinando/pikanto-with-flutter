import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;

class FileViewer extends StatelessWidget {
  final String filePath;

  FileViewer({super.key, required this.filePath});

  bool isUrl(String path) {
    return Uri.tryParse(path)?.hasScheme ?? false;
  }

  @override
  Widget build(BuildContext context) {
    String extension = filePath.split('.').last.toLowerCase();

    if (isUrl(filePath)) {
      if (["png", "jpg", "jpeg"].contains(extension)) {
        // Show Image from URL
        return Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.white,
          child: Image.network(filePath, fit: BoxFit.contain),
        );
      } else if (extension == "pdf") {
        // Show PDF from URL
        return Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.white,
          child: SfPdfViewer.network(
            filePath,
            initialZoomLevel: 1.5,
          ),
        );
      } else if (extension == "txt") {
        // Fetch and Show Text File from URL
        return FutureBuilder<String>(
          future: http.read(Uri.parse(filePath)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                  color: Colors.white,
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: const Center(
                      child: SizedBox(
                          height: 50,
                          width: 50,
                          child: CircularProgressIndicator())));
            }
            if (snapshot.hasError) {
              return Container(
                color: Colors.white,
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: const Center(
                  child: Text("Error loading text file",
                      style: TextStyle(color: Colors.red)),
                ),
              );
            }
            return Container(
              color: Colors.white,
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    snapshot.data ?? "Empty file",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      } else {
        // Open unsupported files externally
        return _buildUnsupportedFileUI(context, filePath);
      }
    } else {
      // Handle local files
      if (["png", "jpg", "jpeg"].contains(extension)) {
        // Show Image
        return Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
            child: Image.file(File(filePath), fit: BoxFit.contain));
      } else if (extension == "pdf") {
        // Show PDF
        return Container(
          color: Colors.white,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: SfPdfViewer.file(
            File(filePath),
            initialZoomLevel: 1.5,
          ),
        );
      } else if (extension == "txt") {
        // Show Text File
        return FutureBuilder<String>(
          future: File(filePath).readAsString(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                  color: Colors.white,
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: const Center(
                      child: SizedBox(
                          height: 50,
                          width: 50,
                          child: CircularProgressIndicator())));
            }
            if (snapshot.hasError) {
              return Container(
                color: Colors.white,
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: const Center(
                  child: Text("Error loading text file",
                      style: TextStyle(color: Colors.red)),
                ),
              );
            }
            return Container(
              color: Colors.white,
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: Center(
                  child: Text(
                    snapshot.data ?? "Empty file",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      } else {
        return _buildUnsupportedFileUI(context, filePath);
      }
    }
  }

  Widget _buildUnsupportedFileUI(BuildContext context, String filePath) {
    return Container(
      color: Colors.white,
      height: 120.0,
      width: 120.0,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Unsupported file type",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.blue,
              backgroundColor: Colors.blue[100],
            ),
            onPressed: () => OpenFilex.open(filePath),
            child: const Text("Open in External App"),
          ),
        ],
      ),
    );
  }
}
