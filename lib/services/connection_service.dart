import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/engine/v2ray_engine.dart';
import '../core/engine/windows_v2ray_engine.dart';
import '../core/engine/android_v2ray_engine.dart';
import '../core/protocol/config_parser.dart';
import '../models/app_settings.dart';
import '../models/server_profile.dart';
import 'log_service.dart';

/// Central connection manager coordinating V2Ray engine, routing modes, and stats.
class ConnectionService extends ChangeNotifier {
  static const String _settingsStorageKey = 'app_settings_config';

  final LogService _logService;
  late final IV2RayEngine _engine;

  AppSettings _settings = const AppSettings();
  ServerProfile? _activeProfile;
  EngineState _state = EngineState.disconnected;
  TrafficStats _stats = const TrafficStats();

  Duration _connectionDuration = Duration.zero;
  Timer? _durationTimer;
  DateTime? _connectedTimestamp;

  int? _currentLatencyMs;
  Map<String, dynamic>? _outboundIpInfo;
  bool _isCheckingIp = false;

  ConnectionService(this._logService) {
    if (Platform.isWindows) {
      _engine = WindowsV2RayEngine();
    } else {
      _engine = AndroidV2RayEngine();
    }

    _engine.stateStream.listen((state) {
      _state = state;
      if (state == EngineState.connected) {
        _startDurationTimer();
        checkOutboundIp();
        testLatency();
      } else if (state == EngineState.disconnected || state == EngineState.error) {
        _stopDurationTimer();
        _currentLatencyMs = null;
        _outboundIpInfo = null;
      }
      notifyListeners();
    });

    _engine.logStream.listen((log) {
      _logService.addLog(log);
    });

    _engine.statsStream.listen((stats) {
      _stats = stats;
      notifyListeners();
    });
  }

  AppSettings get settings => _settings;
  ServerProfile? get activeProfile => _activeProfile;
  EngineState get state => _state;
  TrafficStats get stats => _stats;
  Duration get duration => _connectionDuration;
  int? get latencyMs => _currentLatencyMs;
  Map<String, dynamic>? get outboundIpInfo => _outboundIpInfo;
  bool get isCheckingIp => _isCheckingIp;

  bool get isConnected => _state == EngineState.connected;
  bool get isConnecting => _state == EngineState.connecting;

  String get durationString {
    final hours = _connectionDuration.inHours.toString().padLeft(2, '0');
    final minutes =
        (_connectionDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds =
        (_connectionDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> initialize(List<ServerProfile> initialProfiles) async {
    await _engine.initialize();
    await _loadSettings();

    // Select active profile
    if (_settings.activeProfileId != null) {
      final found = initialProfiles.where((p) => p.id == _settings.activeProfileId);
      if (found.isNotEmpty) {
        _activeProfile = found.first;
      }
    }
    if (_activeProfile == null && initialProfiles.isNotEmpty) {
      _activeProfile = initialProfiles.first;
    }
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsStorageKey);
      if (raw != null) {
        _settings = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  Future<void> saveSettings(AppSettings newSettings) async {
    _settings = newSettings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsStorageKey, jsonEncode(_settings.toJson()));
    } catch (_) {}
    notifyListeners();
  }

  void setActiveProfile(ServerProfile profile) {
    _activeProfile = profile;
    _settings = _settings.copyWith(activeProfileId: profile.id);
    saveSettings(_settings);
    notifyListeners();
  }

  void updateRoutingMode(RoutingMode mode) {
    _settings = _settings.copyWith(routingMode: mode);
    saveSettings(_settings);
    notifyListeners();
  }

  void updateBypassLan(bool bypass) {
    _settings = _settings.copyWith(bypassLan: bypass);
    saveSettings(_settings);
    notifyListeners();
  }

  void updatePorts({required int socksPort, required int httpPort}) {
    _settings = _settings.copyWith(
      socksPort: socksPort,
      httpPort: httpPort,
    );
    saveSettings(_settings);
    notifyListeners();
  }

  void _startDurationTimer() {
    _connectedTimestamp = DateTime.now();
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_connectedTimestamp != null) {
        _connectionDuration = DateTime.now().difference(_connectedTimestamp!);
        notifyListeners();
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _connectionDuration = Duration.zero;
    _connectedTimestamp = null;
  }

  /// Toggles VPN connection state.
  Future<void> toggleConnection() async {
    if (isConnected || isConnecting) {
      await disconnect();
    } else {
      await connect();
    }
  }

  /// Connects to the active server profile.
  Future<bool> connect() async {
    if (_activeProfile == null) {
      _logService.addLog('[App] No profile selected. Please select a server.');
      return false;
    }

    _logService.addLog('[App] Preparing connection to: ${_activeProfile!.name}');

    try {
      final parsedUrl = ConfigParser.parseUrl(_activeProfile!.rawUrl);
      final fullConfigJson = parsedUrl.generateFullConfig(
        routingMode: _settings.routingMode,
        socksPort: _settings.socksPort,
        httpPort: _settings.httpPort,
        bypassLan: _settings.bypassLan,
        netModPayload: _activeProfile!.netModPayload.enabled
            ? _activeProfile!.netModPayload
            : null,
      );

      final success = await _engine.start(
        configJson: fullConfigJson,
        routingMode: _settings.routingMode,
        remark: _activeProfile!.name,
        socksPort: _settings.socksPort,
        httpPort: _settings.httpPort,
        bypassLan: _settings.bypassLan,
      );

      return success;
    } catch (e) {
      _logService.addLog('[App ERROR] Failed to generate configuration: $e');
      return false;
    }
  }

  /// Disconnects the active VPN connection.
  Future<void> disconnect() async {
    await _engine.stop();
  }

  /// Measures real-time latency through the active proxy.
  Future<void> testLatency() async {
    final ms = await _engine.measureDelay();
    _currentLatencyMs = ms;
    notifyListeners();
  }

  /// Fetches public IP and Geo info to prove network traffic routing.
  Future<void> checkOutboundIp() async {
    _isCheckingIp = true;
    notifyListeners();

    try {
      final client = HttpClient();
      if (isConnected && _settings.routingMode != RoutingMode.tun) {
        // Query through local proxy
        client.findProxy = (uri) => 'PROXY 127.0.0.1:${_settings.httpPort}';
      }
      client.connectionTimeout = const Duration(seconds: 5);

      final ioClient = IOClient(client);
      final response = await ioClient
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _outboundIpInfo = jsonDecode(response.body) as Map<String, dynamic>;
        _logService.addLog(
          '[App Info] Verified Outbound IP: ${_outboundIpInfo?['query']} (${_outboundIpInfo?['country']}, ${_outboundIpInfo?['isp']})',
        );
      }
    } catch (e) {
      _logService.addLog('[App Info] Outbound IP check returned: $e');
    }

    _isCheckingIp = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _engine.stop();
    super.dispose();
  }
}
