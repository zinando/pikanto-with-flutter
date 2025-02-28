import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:process_run/shell.dart';
import 'package:pikanto/resources/settings.dart';
//import 'package:pikanto/widgets/download_dialog.dart';

class AppUpdater {
  // method to check for update.
  //update file is a json file containing latest version and download url
  Future<String> checkForUpdate(BuildContext context) async {
    String feedback = '';
    try {
      final response = await http.get(Uri.parse(settingsData["updateFileUrl"]));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = Version.parse(data['latest_version']);
        final downloadUrl = data['download_url'];
        // print('Latest version: ${latestVersion.toString()}');
        // print('Download URL: $downloadUrl');
        // print('Current version: $currentVersion');

        if (Version.parse(settingsData["currentAppVersion"]) < latestVersion) {
          // get the updater app path
          final appDirPath = Directory.current.path;
          final updaterAppPath =
              "${Directory.current.parent.path}/pikanto_updater/app_updater.exe";

          // run the updater app
          String command = 'cd .. && start "$updaterAppPath" '
              '--downloadUrl "$downloadUrl" '
              '--latestVersion "$latestVersion" '
              '--appDirPath "$appDirPath" '
              '--appExecutableName "${settingsData['appExecutableName']}" '
              '--appSettingsFilePath "${settingsData['appSettingsFile']}"';

          // await Process.start(
          //   'cmd',
          //   ['/c', command],
          //   mode: ProcessStartMode.detached,
          //   runInShell: true,
          // );

          await Shell().run(command);

          feedback = command;
          // await showDialog(
          //   context: context,
          //   barrierColor: Colors.black.withOpacity(0.9),
          //   barrierDismissible: false, // Prevent closing while downloading
          //   builder: (context) => UpdateDialog(
          //     downloadUrl: downloadUrl,
          //     latestVersion: latestVersion,
          //   ),
          // );
        } else {
          throw Exception('No updates available.');
        }
      } else {
        throw Exception('Failed to check for updates.');
      }
    } catch (e) {
      feedback = '$e';
    }

    return feedback;
  }

  // method to show confirmation dialogue
  Future<bool> _showUpdateDialog(
      BuildContext context, String latestVersion) async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.9),
          barrierDismissible: false,
          barrierLabel: 'Update to latest version',
          builder: (BuildContext context) {
            return AlertDialog(
              //add icon
              icon: const Icon(Icons.update),
              iconColor: Theme.of(context).colorScheme.tertiary,
              backgroundColor: Colors.white,
              elevation: 2.0,
              shadowColor: Colors.grey[200],
              surfaceTintColor: Colors.grey[200],
              semanticLabel: 'Update to latest version',
              title: const Text("Update Available"),
              titleTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
              content: Text(
                  "A new version ($latestVersion) is available. Would you like to update now?"),
              contentTextStyle:
                  TextStyle(color: Colors.grey[800], fontSize: 16),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("No"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Colors.white,
                    elevation: 2.0,
                  ),
                  child: const Text("Yes, update now"),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed
  }

  // method to download and install update
  Future<void> downloadAndInstallUpdate(
      BuildContext context, String downloadUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final zipFilePath = "${tempDir.path}/Release.zip";

      print("Starting download from: $downloadUrl");

      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {"User-Agent": "Mozilla/5.0"}, // Pretend to be a browser
      );

      if (response.statusCode == 200) {
        final file = File(zipFilePath);
        final sink = file.openWrite();
        int downloadedBytes = 0;
        int contentLength = response.contentLength ?? 0;

        print("File size: ${contentLength / 1024} KB");

        // Show progress dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text("Downloading Update"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Downloading update... Please wait."),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: contentLength > 0
                            ? downloadedBytes / contentLength
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                          "${(downloadedBytes / 1024).toStringAsFixed(2)} KB / ${(contentLength / 1024).toStringAsFixed(2)} KB"),
                    ],
                  ),
                );
              },
            );
          },
        );

        // Write to file in chunks
        for (var chunk in response.bodyBytes) {
          downloadedBytes += 1;
          //downloadedBytes += //(chunk.length);
          sink.add([chunk]);
          print("Downloaded: ${downloadedBytes / 1024} KB");

          // Update progress UI
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    setState(() {});
                    return AlertDialog(
                      title: const Text("Downloading Update"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Downloading update... Please wait."),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: contentLength > 0
                                ? downloadedBytes / contentLength
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                              "${(downloadedBytes / 1024).toStringAsFixed(2)} KB / ${(contentLength / 1024).toStringAsFixed(2)} KB"),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          }
        }

        await sink.close();
        Navigator.pop(context); // Close progress dialog
        print("Download completed: $zipFilePath");
      } else {
        print("Failed to download update. HTTP ${response.statusCode}");
        throw Exception(
            "Download failed with status code ${response.statusCode}");
      }
    } catch (e) {
      print("Error downloading update: $e");
    }
  }

  // method to extract zip file
  Future<void> extractZipFile(String zipFilePath, String extractedPath) async {
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
    print("Extraction complete.");
  }

  // method to install update
  Future<void> installUpdate(String extractedPath, String appFolderName,
      String appExecutableName) async {
    try {
      final appDir = Directory.current.path;
      final oldAppPath = "$appDir/$appFolderName";
      final newAppPath = "$extractedPath/$appFolderName";

      // Backup old version
      final backupPath = "$oldAppPath.bak";
      if (Directory(oldAppPath).existsSync()) {
        Directory(oldAppPath).renameSync(backupPath);
      }

      // Move new version to app directory
      Directory(newAppPath).renameSync(oldAppPath);

      // update app current version in settings
      settingsData['currentAppVersion'] =
          Version.parse(settingsData["currentAppVersion"]).toString();

      // Restart the app
      await restartApp("$oldAppPath/$appExecutableName");
    } catch (e) {
      print("Error installing update: $e");
    }
  }

  // method to restart app
  Future<void> restartApp(String appExecutablePath) async {
    final shell = Shell();
    await shell.run(appExecutablePath);
    exit(0);
  }
}
