import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

// Load user32.dll for Windows UI functions
final user32 = DynamicLibrary.open('user32.dll');

// Define MessageBox function
typedef MessageBoxNative = Int32 Function(
    IntPtr hWnd, Pointer<Utf16> text, Pointer<Utf16> caption, Uint32 type);
typedef MessageBoxDart = int Function(
    int hWnd, Pointer<Utf16> text, Pointer<Utf16> caption, int type);
final MessageBox =
    user32.lookupFunction<MessageBoxNative, MessageBoxDart>('MessageBoxW');

void main(List<String> args) async {
  if (args.length < 3) {
    print("Usage: updater.exe <zipPath> <appFolder> <exeName>");
    await Future.delayed(Duration(seconds: 15));
    exit(1);
  }

  String zipPath = args[0]; // Path to downloaded update ZIP
  String appFolder = args[1]; // Folder of the existing app
  String exeName = args[2]; // Name of the main app executable

  final text =
      'An update is available. Do you want to install it?'.toNativeUtf16();
  final caption = 'Update Available'.toNativeUtf16();

  int result = MessageBox(0, text, caption, 1); // 1 = OK/Cancel
  calloc.free(text);
  calloc.free(caption);

  if (result == 1) {
    print("User accepted the update. Proceeding...");

    // Kill the main app
    await _killProcess(exeName);

    // Extract the update ZIP
    await _extractZip(zipPath, appFolder);

    // Restart the app
    _startApp("$appFolder\\$exeName");
  } else {
    print("User canceled the update.");
    exit(0);
  }
}

Future<void> _killProcess(String exeName) async {
  print("Closing $exeName...");
  await Process.run("taskkill", ["/IM", exeName, "/F"]);
  await Future.delayed(Duration(seconds: 2)); // Ensure process is stopped
}

Future<void> _extractZip(String zipPath, String appFolder) async {
  print("Extracting update...");
  final bytes = File(zipPath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  for (final file in archive) {
    final filePath = "$appFolder/${file.name}";
    if (file.isFile) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(file.content as List<int>);
    } else {
      Directory(filePath).createSync(recursive: true);
    }
  }
  print("Update applied successfully.");
}

void _startApp(String exePath) {
  print("Starting updated app...");
  Process.start(exePath, []);
  exit(0);
}
