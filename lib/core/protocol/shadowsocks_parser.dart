import 'dart:convert';
import 'v2ray_url_base.dart';

/// Parser for Shadowsocks `ss://` share links (SIP002 standard).
class ShadowsocksParser extends V2RayUrlBase {
  late final String method;
  late final String password;
  late final String serverAddress;
  late final int serverPort;
  late final String serverRemark;

  ShadowsocksParser({required super.url}) {
    if (!url.startsWith('ss://')) {
      throw ArgumentError('Invalid Shadowsocks URL');
    }

    final parsed = Uri.tryParse(url);
    if (parsed == null) {
      throw ArgumentError('Malformed SS URL');
    }

    serverRemark = parsed.fragment.isNotEmpty
        ? Uri.decodeFull(parsed.fragment.replaceAll('+', '%20'))
        : 'Shadowsocks Server';

    if (parsed.userInfo.isNotEmpty) {
      // Standard SIP002: ss://base64(method:password)@host:port#remark
      var raw = parsed.userInfo;
      if (raw.length % 4 > 0) raw += '=' * (4 - raw.length % 4);
      try {
        final decoded = utf8.decode(base64Decode(raw));
        final idx = decoded.indexOf(':');
        method = decoded.substring(0, idx);
        password = decoded.substring(idx + 1);
      } catch (_) {
        method = 'aes-256-gcm';
        password = raw;
      }
      serverAddress = parsed.host;
      serverPort = parsed.hasPort ? parsed.port : 8388;
    } else {
      // Legacy format: ss://base64(method:password@host:port)#remark
      var raw = parsed.host;
      if (raw.length % 4 > 0) raw += '=' * (4 - raw.length % 4);
      try {
        final decoded = utf8.decode(base64Decode(raw));
        final atIdx = decoded.indexOf('@');
        final userPass = decoded.substring(0, atIdx);
        final hostPort = decoded.substring(atIdx + 1);

        final colonUser = userPass.indexOf(':');
        method = userPass.substring(0, colonUser);
        password = userPass.substring(colonUser + 1);

        final colonHost = hostPort.lastIndexOf(':');
        serverAddress = hostPort.substring(0, colonHost);
        serverPort = int.tryParse(hostPort.substring(colonHost + 1)) ?? 8388;
      } catch (_) {
        method = 'aes-256-gcm';
        password = '';
        serverAddress = '';
        serverPort = 8388;
      }
    }

    populateTlsSettings(
      streamSecurity: parsed.queryParameters['security'] ?? '',
      sni: parsed.queryParameters['sni'],
      fingerprint: parsed.queryParameters['fp'],
      alpns: parsed.queryParameters['alpn'],
      verifyPeerCertByName: parsed.queryParameters['vcn'],
      pinnedPeerCertSha256: parsed.queryParameters['pcs'] ?? parsed.queryParameters['pinSHA256'],
    );
  }

  @override
  String get address => serverAddress;

  @override
  int get port => serverPort;

  @override
  String get remark => serverRemark;

  @override
  String get protocol => 'shadowsocks';

  @override
  Map<String, dynamic> get proxyOutbound => {
        'tag': 'proxy',
        'protocol': 'shadowsocks',
        'settings': {
          'servers': [
            {
              'address': address,
              'port': port,
              'method': method,
              'password': password,
              'level': 8,
            }
          ]
        },
        'streamSettings': streamSettings,
      };
}
