import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:version/version.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:process_run/shell.dart';

void main(List<String> args) {
  String downloadUrl = "";
  Version latestVersion = Version(1, 0, 0);

  // Parse command-line arguments
  if (args.contains('--downloadUrl')) {
    int index = args.indexOf('--downloadUrl');
    if (index + 1 < args.length) {
      downloadUrl = args[index + 1];
    }
  }
  if (args.contains('--latestVersion')) {
    int index = args.indexOf('--latestVersion');
    if (index + 1 < args.length) {
      latestVersion = Version.parse(args[index + 1]);
    }
  }

  runApp(UpdateApp(downloadUrl: downloadUrl, latestVersion: latestVersion));
}

class UpdateApp extends StatelessWidget {
  final String downloadUrl;
  final Version latestVersion;

  const UpdateApp(
      {super.key, required this.downloadUrl, required this.latestVersion});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Updater',
      theme: ThemeData.dark(),
      home:
          UpdateDialog(downloadUrl: downloadUrl, latestVersion: latestVersion),
    );
  }
}

class UpdateDialog extends StatefulWidget {
  final String downloadUrl;
  final Version latestVersion;

  const UpdateDialog(
      {super.key, required this.downloadUrl, required this.latestVersion});

  @override
  State createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double _progress = 0.0;
  bool _isDownloading = false;
  bool _isDownloadComplete = false;
  bool _isExtracting = false;
  String _statusMessage = "Ready to download...";

  Future<void> _startDownload() async {
    if (widget.downloadUrl.isEmpty) {
      setState(() {
        _statusMessage = "Error: No download URL provided.";
      });
      return;
    }
    try {
      setState(() {
        _isDownloading = true;
        _statusMessage = "Starting download...";
      });
      final tempDir = await getTemporaryDirectory();
      final filePath = "${tempDir.path}/pikanto_update.zip";
      final request = http.Request('GET', Uri.parse(widget.downloadUrl));
      final streamedResponse = await request.send();
      final contentLength = streamedResponse.contentLength ?? 1;

      if (streamedResponse.statusCode == 200) {
        final file = File(filePath);
        final sink = file.openWrite();
        int downloadedBytes = 0;

        await for (var chunk in streamedResponse.stream) {
          downloadedBytes += chunk.length;
          sink.add(chunk);

          setState(() {
            _progress = downloadedBytes / contentLength;
            _statusMessage =
                "Downloading... ${(_progress * 100).toStringAsFixed(1)}%";
          });
        }
        await sink.close();

        setState(() {
          _statusMessage = "Download Complete!";
          _isDownloading = false;
        });

        await extractZipFile(filePath, tempDir.path);
      } else {
        setState(() {
          _statusMessage = "Download failed.";
          _isDownloading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
        _isDownloading = false;
      });
    }
  }

  Future<void> extractZipFile(String zipFilePath, String extractedPath) async {
    setState(() {
      _isExtracting = true;
      _statusMessage = "Extracting...";
    });

    await Future.delayed(const Duration(seconds: 3));

    try {
      final inputStream = InputFileStream(zipFilePath);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      for (final file in archive) {
        final filePath = "$extractedPath/${file.name}";
        if (file.isFile) {
          final outputStream = OutputFileStream(filePath);
          file.writeContent(outputStream);
          await outputStream.close();
        } else {
          Directory(filePath).createSync(recursive: true);
        }
      }

      setState(() {
        _isExtracting = false;
        _statusMessage = "Extraction complete.";
        _isDownloadComplete = true;
      });
      await installUpdate(extractedPath, settingsData['appFolderName'],
          settingsData['appExecutableName']);
    } catch (e) {
      setState(() {
        _statusMessage = "Error extracting update: $e";
      });
    }
  }

  Future<void> installUpdate(String extractedPath, String appFolderName,
      String appExecutableName) async {
    setState(() {
      _statusMessage = "Installing update...";
    });
    try {
      final appDir = Directory.current.path;
      final newAppDirPath = "$extractedPath/$appFolderName";
      final backupPath = "$appDir.bak";

      if (Directory(appDir).existsSync()) {
        Directory(appDir).renameSync(backupPath);
      }
      Directory(newAppDirPath).renameSync(appDir);

      settingsData['currentAppVersion'] = widget.latestVersion.toString();
      await restartApp("$appDir/$appExecutableName");
    } catch (e) {
      setState(() {
        _statusMessage = "Error installing update: $e";
      });
    }
  }

  Future<void> restartApp(String appExecutablePath) async {
    final shell = Shell();
    await shell.run(appExecutablePath);
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.update),
      title: const Text("Update Available"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_statusMessage),
          const SizedBox(height: 10),
          (_isDownloading || _isExtracting)
              ? LinearProgressIndicator(value: _progress)
              : const SizedBox(),
        ],
      ),
      actions: [
        if (!_isDownloading && !_isExtracting)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        if (!_isDownloading && !_isDownloadComplete && !_isExtracting)
          ElevatedButton(
            onPressed: () => _startDownload(),
            child: const Text("Yes, Download Now"),
          ),
      ],
    );
  }
}
