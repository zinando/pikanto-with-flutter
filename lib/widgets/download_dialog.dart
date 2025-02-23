import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:version/version.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:process_run/shell.dart';

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
    try {
      setState(() {
        _isDownloading = true;
        _statusMessage = "Starting download...";
      });

      final tempDir = await getTemporaryDirectory();
      final filePath = "${tempDir.path}\\pikanto_update.zip";

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

          // Update UI progress
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

        print("Update downloaded successfully at $filePath");

        // Extract the downloaded zip file
        final extractedPath = tempDir.path;
        await extractZipFile(filePath, extractedPath);

        // Optionally, install or notify the user
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

  // method to extract zip file
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
      print("Extraction complete.");

      // Install the update
      await installUpdate(extractedPath, settingsData['appFolderName'],
          settingsData['appExecutableName']);
    } catch (e) {
      setState(() {
        _statusMessage = "Error extracting update: $e";
      });
    }
  }

  // method to install update
  Future<void> installUpdate(String extractedPath, String appFolderName,
      String appExecutableName) async {
    setState(() {
      _statusMessage = "Installing update...";
    });
    try {
      // get the parent directory of app directory
      final appDir = Directory.current.path;
      final newAppDirPath = "$extractedPath\\$appFolderName";

      setState(() {
        _statusMessage = "Old app path: $appDir";
      });

      // // Backup old version
      final backupPath = "$appDir.bak";
      if (Directory(appDir).existsSync()) {
        Directory(appDir).renameSync(backupPath);
      }

      // Move new version to app directory
      Directory(newAppDirPath).renameSync(appDir);

      // update app current version in settings
      settingsData['currentAppVersion'] = widget.latestVersion.toString();

      // Restart the app
      await restartApp("$appDir/$appExecutableName");
    } catch (e) {
      setState(() {
        _statusMessage = "Error installing update: $e";
      });
    }
  }

  // method to restart app
  Future<void> restartApp(String appExecutablePath) async {
    final shell = Shell();
    await shell.run(appExecutablePath);
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.update),
      iconColor: Theme.of(context).colorScheme.tertiary,
      backgroundColor: Colors.white,
      elevation: 2.0,
      shadowColor: Colors.grey[200],
      surfaceTintColor: Colors.grey[200],
      semanticLabel: 'Update to latest version',
      title: const Text("Update Available"),
      titleTextStyle: const TextStyle(
          color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_statusMessage),
          const SizedBox(height: 10),
          _isDownloading || _isExtracting
              ? LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.tertiary,
                  ),
                )
              : const SizedBox(),
        ],
      ),
      contentTextStyle: TextStyle(color: Colors.grey[800], fontSize: 16),
      actions: [
        if (!_isDownloading && !_isExtracting)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.tertiary,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        if (!_isDownloading && !_isDownloadComplete && !_isExtracting)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              foregroundColor: Colors.white,
              elevation: 2.0,
            ),
            child: const Text("Yes, Download Now"),
            onPressed: () => _startDownload(),
          ),
      ],
    );
  }
}
