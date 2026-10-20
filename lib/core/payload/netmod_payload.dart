/// Configuration for NetMod-style HTTP payload injection and Bug Host spoofing.
class NetModPayloadConfig {
  final bool enabled;
  final String payloadText;
  final String bugHost;
  final String sni;
  final String requestMethod;

  const NetModPayloadConfig({
    this.enabled = false,
    this.payloadText = '',
    this.bugHost = '',
    this.sni = '',
    this.requestMethod = 'CONNECT',
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'payloadText': payloadText,
        'bugHost': bugHost,
        'sni': sni,
        'requestMethod': requestMethod,
      };

  factory NetModPayloadConfig.fromJson(Map<String, dynamic> json) =>
      NetModPayloadConfig(
        enabled: json['enabled'] as bool? ?? false,
        payloadText: json['payloadText'] as String? ?? '',
        bugHost: json['bugHost'] as String? ?? '',
        sni: json['sni'] as String? ?? '',
        requestMethod: json['requestMethod'] as String? ?? 'CONNECT',
      );

  NetModPayloadConfig copyWith({
    bool? enabled,
    String? payloadText,
    String? bugHost,
    String? sni,
    String? requestMethod,
  }) {
    return NetModPayloadConfig(
      enabled: enabled ?? this.enabled,
      payloadText: payloadText ?? this.payloadText,
      bugHost: bugHost ?? this.bugHost,
      sni: sni ?? this.sni,
      requestMethod: requestMethod ?? this.requestMethod,
    );
  }
}

/// Helper that applies NetMod payload tokens and Bug Host substitutions to Xray outbounds.
class NetModPayloadInjector {
  /// Common NetMod default payload templates.
  static const String defaultConnectPayload =
      'CONNECT [host_port] [protocol][crlf]Host: [host][crlf]X-Online-Host: [host][crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][crlf]';

  static const String defaultHttpPayload =
      'GET / HTTP/1.1[crlf]Host: [host][crlf]Connection: Upgrade[crlf]Upgrade: websocket[crlf]User-Agent: [ua][crlf][crlf]';

  /// Replaces NetMod template variables in a raw payload string.
  static String formatPayload({
    required String rawPayload,
    required String serverAddress,
    required int serverPort,
    String? bugHost,
  }) {
    final effectiveHost =
        (bugHost != null && bugHost.isNotEmpty) ? bugHost : serverAddress;

    var formatted = rawPayload
        .replaceAll('[host_port]', '$effectiveHost:$serverPort')
        .replaceAll('[host]', effectiveHost)
        .replaceAll('[port]', serverPort.toString())
        .replaceAll('[protocol]', 'HTTP/1.1')
        .replaceAll('[crlf]', '\r\n')
        .replaceAll('[lf]', '\n')
        .replaceAll('[cr]', '\r')
        .replaceAll(
          '[ua]',
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        );

    return formatted;
  }

  /// Injects Bug Host and SNI overrides directly into the Xray outbound structure.
  static void apply({
    required Map<String, dynamic> outbound,
    required NetModPayloadConfig payloadConfig,
    required String serverAddress,
    required int serverPort,
  }) {
    final streamSettings = outbound['streamSettings'] as Map<String, dynamic>?;
    if (streamSettings == null) return;

    final targetBugHost = payloadConfig.bugHost.trim();
    final targetSni = payloadConfig.sni.trim();

    // 1. Override SNI if specified
    if (targetSni.isNotEmpty || targetBugHost.isNotEmpty) {
      final sniToUse = targetSni.isNotEmpty ? targetSni : targetBugHost;
      final tlsSettings =
          streamSettings['tlsSettings'] as Map<String, dynamic>?;
      if (tlsSettings != null) {
        tlsSettings['serverName'] = sniToUse;
        if (serverAddress.isNotEmpty && !RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(serverAddress)) {
          tlsSettings['verifyPeerCertByName'] = serverAddress;
        }
      }
      final realitySettings =
          streamSettings['realitySettings'] as Map<String, dynamic>?;
      if (realitySettings != null) {
        realitySettings['serverName'] = sniToUse;
      }
    }

    // 2. Override WebSocket Host header if WS transport
    if (streamSettings['network'] == 'ws' && targetBugHost.isNotEmpty) {
      final wsSettings = streamSettings['wsSettings'] as Map<String, dynamic>?;
      if (wsSettings != null) {
        final headers = wsSettings['headers'] as Map<String, dynamic>? ?? {};
        headers['Host'] = targetBugHost;
        wsSettings['headers'] = headers;
      }
    }

    // 3. Override HTTP / TCP header Host if TCP HTTP transport
    if (streamSettings['network'] == 'tcp' && targetBugHost.isNotEmpty) {
      final tcpSettings =
          streamSettings['tcpSettings'] as Map<String, dynamic>?;
      if (tcpSettings != null) {
        final header = tcpSettings['header'] as Map<String, dynamic>?;
        if (header != null && header['type'] == 'http') {
          final request = header['request'] as Map<String, dynamic>? ?? {};
          final headers = request['headers'] as Map<String, dynamic>? ?? {};
          headers['Host'] = [targetBugHost];
          request['headers'] = headers;
          header['request'] = request;
        }
      }
    }
  }
}
