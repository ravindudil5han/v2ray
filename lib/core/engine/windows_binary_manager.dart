import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages extraction and resolution of Xray-core binaries on Windows.
class WindowsBinaryManager {
  static const List<String> requiredFiles = [
    'xray.exe',
    'wintun.dll',
    'geoip.dat',
    'geosite.dat',
  ];

  static String? _coreDirPath;

  /// Gets the directory path where Xray binaries and dat files reside.
  static Future<String> getCoreDirectory() async {
    if (_coreDirPath != null && Directory(_coreDirPath!).existsSync()) {
      return _coreDirPath!;
    }

    final appDocDir = await getApplicationSupportDirectory();
    final coreDir = Directory(p.join(appDocDir.path, 'netmod_core'));
    if (!coreDir.existsSync()) {
      coreDir.createSync(recursive: true);
    }

    // Check if files are already installed in coreDir
    bool allExist = true;
    for (final filename in requiredFiles) {
      final targetFile = File(p.join(coreDir.path, filename));
      if (!targetFile.existsSync() || targetFile.lengthSync() == 0) {
        allExist = false;
        break;
      }
    }

    if (!allExist) {
      await _copyFromLocalOrAssets(coreDir.path);
    }

    _coreDirPath = coreDir.path;
    return coreDir.path;
  }

  /// Copies files from working directory or Flutter asset bundle into [targetDirPath].
  static Future<void> _copyFromLocalOrAssets(String targetDirPath) async {
    // 1. Try local project assets directory first
    final localAssetDir = Directory(p.join(Directory.current.path, 'assets', 'bin'));
    if (localAssetDir.existsSync()) {
      for (final filename in requiredFiles) {
        final src = File(p.join(localAssetDir.path, filename));
        final dst = File(p.join(targetDirPath, filename));
        if (src.existsSync()) {
          try {
            src.copySync(dst.path);
          } catch (_) {}
        }
      }
    }

    // 2. Try app runner directory (for release builds)
    final exeDir = File(Platform.resolvedExecutable).parent;
    final bundleAssetDir = Directory(
      p.join(exeDir.path, 'data', 'flutter_assets', 'assets', 'bin'),
    );
    if (bundleAssetDir.existsSync()) {
      for (final filename in requiredFiles) {
        final src = File(p.join(bundleAssetDir.path, filename));
        final dst = File(p.join(targetDirPath, filename));
        if (src.existsSync() && (!dst.existsSync() || dst.lengthSync() == 0)) {
          try {
            src.copySync(dst.path);
          } catch (_) {}
        }
      }
    }

    // 3. Fallback: load through rootBundle
    for (final filename in requiredFiles) {
      final dst = File(p.join(targetDirPath, filename));
      if (!dst.existsSync() || dst.lengthSync() == 0) {
        try {
          final assetData = await rootBundle.load('assets/bin/$filename');
          final bytes = assetData.buffer.asUint8List();
          await dst.writeAsBytes(bytes, flush: true);
        } catch (_) {}
      }
    }
  }

  /// Gets the path to `xray.exe`.
  static Future<String> getXrayExecutablePath() async {
    final coreDir = await getCoreDirectory();
    final exe = File(p.join(coreDir, 'xray.exe'));
    if (exe.existsSync()) {
      return exe.path;
    }
    // Fallback directly to local asset if present
    final localExe = File(p.join(Directory.current.path, 'assets', 'bin', 'xray.exe'));
    if (localExe.existsSync()) {
      return localExe.path;
    }
    return 'xray.exe';
  }
}
