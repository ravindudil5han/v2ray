import 'dart:async';

/// Supported network routing modes.
enum RoutingMode {
  /// Routes device network traffic via Windows Internet Settings / System Proxy.
  systemProxy,

  /// Full system network routing via Wintun / TUN virtual adapter.
  tun,

  /// Only starts local SOCKS (10808) & HTTP (10809) proxies without altering OS routing.
  proxyOnly,
}

extension RoutingModeExtension on RoutingMode {
  String get displayName {
    switch (this) {
      case RoutingMode.systemProxy:
        return 'System Proxy';
      case RoutingMode.tun:
        return 'TUN Mode (Full VPN)';
      case RoutingMode.proxyOnly:
        return 'Proxy Only (Manual)';
    }
  }

  String get description {
    switch (this) {
      case RoutingMode.systemProxy:
        return 'Routes web browsers and system HTTP/HTTPS apps';
      case RoutingMode.tun:
        return 'Intercepts 100% of network traffic (TCP, UDP, DNS)';
      case RoutingMode.proxyOnly:
        return 'Local SOCKS5 (10808) and HTTP (10809) only';
    }
  }
}

/// Status of the V2Ray core engine.
enum EngineState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// Real-time traffic statistics.
class TrafficStats {
  final int uploadSpeedBytes; // bytes per second
  final int downloadSpeedBytes; // bytes per second
  final int totalUploadBytes;
  final int totalDownloadBytes;

  const TrafficStats({
    this.uploadSpeedBytes = 0,
    this.downloadSpeedBytes = 0,
    this.totalUploadBytes = 0,
    this.totalDownloadBytes = 0,
  });

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String formatSpeed(int bytesPerSec) {
    return '${formatBytes(bytesPerSec)}/s';
  }
}

/// Abstract interface for cross-platform V2Ray Core management.
abstract class IV2RayEngine {
  /// Initializes the engine (extracts binaries, initializes services).
  Future<bool> initialize();

  /// Starts the core with the given configuration string and routing mode.
  Future<bool> start({
    required String configJson,
    required RoutingMode routingMode,
    required String remark,
    required int socksPort,
    required int httpPort,
    bool bypassLan = true,
  });

  /// Stops the core and restores system proxy / routing state.
  Future<bool> stop();

  /// Gets current state.
  EngineState get state;

  /// Stream of engine state changes.
  Stream<EngineState> get stateStream;

  /// Stream of log messages.
  Stream<String> get logStream;

  /// Stream of real-time traffic statistics.
  Stream<TrafficStats> get statsStream;

  /// Measures latency (ping) in milliseconds to the server or target.
  Future<int> measureDelay({String? targetUrl});
}
