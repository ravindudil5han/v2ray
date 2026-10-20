import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server_profile.dart';
import '../core/protocol/config_parser.dart';

/// Manages persistence, testing, and lifecycle of server profiles.
class ProfileService extends ChangeNotifier {
  static const String _storageKey = 'saved_server_profiles';
  final List<ServerProfile> _profiles = [];
  bool _isLoading = false;

  List<ServerProfile> get profiles => List.unmodifiable(_profiles);
  bool get isLoading => _isLoading;

  Future<void> loadProfiles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _profiles.clear();
        for (final item in list) {
          _profiles.add(ServerProfile.fromJson(item as Map<String, dynamic>));
        }
      } else {
        // Populate sample profiles if empty
        _createDefaultSampleProfiles();
        await _saveToDisk();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void _createDefaultSampleProfiles() {
    _profiles.addAll([
      ServerProfile(
        name: 'Cloudflare Zero-Trust Edge (Sample VMess)',
        protocol: 'vmess',
        address: '104.16.132.229',
        port: 443,
        rawUrl:
            'vmess://eyJ2IjoiMiIsInBzIjoiQ2xvdWRmbGFyZSBaZXJvLVRydXN0IEVkZ2UiLCJhZGQiOiIxMDQuMTYuMTMyLjIyOSIsInBvcnQiOjQ0MywiaWQiOiJkNjU0Y2NhNS00M2Y2LTRiODctOTA4MS1mYzUxMDkzMTRiNjQiLCJhaWQiOjAsInNjeSI6ImF1dG8iLCJuZXQiOiJ3cyIsInR5cGUiOiJub25lIiwiaG9zdCI6ImNmLm5ldG1vZC5vcGVuIiwicGF0aCI6Ii92MnJheSIsInRscyI6InRscyJ9',
      ),
      ServerProfile(
        name: 'US East VLESS Reality (Sample)',
        protocol: 'vless',
        address: '1.1.1.1',
        port: 443,
        rawUrl:
            'vless://b66c4217-1836-419b-a01b-c7438e8cbfa2@1.1.1.1:443?type=tcp&security=reality&pbk=w69y8f31XwQ0hS3E_q8j5N7mX_2b8c9d0e1f2a3b4c5&fp=chrome&sni=cloudflare.com#US%20East%20VLESS%20Reality',
      ),
      ServerProfile(
        name: 'Europe Fast Trojan (Sample)',
        protocol: 'trojan',
        address: '8.8.8.8',
        port: 443,
        rawUrl:
            'trojan://sample_secret_key_9982@8.8.8.8:443?security=tls&type=ws&host=dns.google&path=%2Ftrojan#Europe%20Fast%20Trojan',
      ),
    ]);
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _profiles.map((p) => p.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> addProfile(ServerProfile profile) async {
    _profiles.insert(0, profile);
    await _saveToDisk();
    notifyListeners();
  }

  Future<void> updateProfile(ServerProfile profile) async {
    final idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx != -1) {
      _profiles[idx] = profile;
      await _saveToDisk();
      notifyListeners();
    }
  }

  Future<void> deleteProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    await _saveToDisk();
    notifyListeners();
  }

  /// Imports one or multiple profiles from text (e.g. from clipboard or subscription).
  Future<int> importFromText(String rawText) async {
    final parsedList = ConfigParser.parseSubscriptionContent(rawText);
    if (parsedList.isEmpty) {
      // Try parsing as single URL
      try {
        final single = ConfigParser.parseUrl(rawText);
        final profile = ServerProfile(
          name: single.remark.isNotEmpty ? single.remark : '${single.protocol.toUpperCase()} Server',
          protocol: single.protocol,
          address: single.address,
          port: single.port,
          rawUrl: rawText.trim(),
        );
        await addProfile(profile);
        return 1;
      } catch (_) {
        return 0;
      }
    }

    int count = 0;
    for (final parsed in parsedList) {
      final profile = ServerProfile(
        name: parsed.remark.isNotEmpty ? parsed.remark : '${parsed.protocol.toUpperCase()} Server',
        protocol: parsed.protocol,
        address: parsed.address,
        port: parsed.port,
        rawUrl: parsed.url,
      );
      _profiles.insert(0, profile);
      count++;
    }

    await _saveToDisk();
    notifyListeners();
    return count;
  }

  /// Measures TCP latency directly to the server address and port.
  Future<int> testProfilePing(ServerProfile profile) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        profile.address,
        profile.port,
        timeout: const Duration(seconds: 3),
      );
      stopwatch.stop();
      await socket.close();
      final ms = stopwatch.elapsedMilliseconds;

      final updated = profile.copyWith(pingMs: ms);
      await updateProfile(updated);
      return ms;
    } catch (_) {
      final updated = profile.copyWith(pingMs: -1);
      await updateProfile(updated);
      return -1;
    }
  }

  /// Tests latency for all saved profiles.
  Future<void> testAllPings() async {
    for (final profile in List<ServerProfile>.from(_profiles)) {
      await testProfilePing(profile);
    }
  }
}
