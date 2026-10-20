import 'dart:convert';
import 'v2ray_url_base.dart';

/// Parser for `vmess://` standard share links.
class VmessParser extends V2RayUrlBase {
  late final Map<String, dynamic> rawJson;

  VmessParser({required super.url}) {
    if (!url.startsWith('vmess://')) {
      throw ArgumentError('Invalid VMess URL: Must start with vmess://');
    }

    var raw = url.substring(8).trim().replaceAll(RegExp(r'\s+'), '');
    try {
      raw = base64.normalize(raw);
    } catch (_) {}

    try {
      final decodedStr = utf8.decode(base64Decode(raw));
      rawJson = jsonDecode(decodedStr) as Map<String, dynamic>;
    } catch (e) {
      throw ArgumentError('Invalid VMess payload encoding: $e');
    }

    final sni = populateTransportSettings(
      transport: rawJson['net']?.toString(),
      headerType: rawJson['type']?.toString(),
      host: rawJson['host']?.toString(),
      path: rawJson['path']?.toString(),
    );

    populateTlsSettings(
      streamSecurity: rawJson['tls']?.toString(),
      sni: (rawJson['sni'] != null && rawJson['sni'].toString().isNotEmpty)
          ? rawJson['sni'].toString()
          : sni,
      fingerprint: rawJson['fp']?.toString(),
      alpns: rawJson['alpn']?.toString(),
      verifyPeerCertByName: rawJson['vcn']?.toString() ??
          rawJson['verifyPeerCertByName']?.toString(),
      pinnedPeerCertSha256: rawJson['pcs']?.toString() ??
          rawJson['pinSHA256']?.toString() ??
          rawJson['pinnedPeerCertSha256']?.toString(),
    );
  }

  @override
  String get remark => (rawJson['ps']?.toString().isNotEmpty == true)
      ? rawJson['ps'].toString()
      : 'VMess Server';

  @override
  String get address => rawJson['add']?.toString() ?? '';

  @override
  int get port => int.tryParse(rawJson['port']?.toString() ?? '443') ?? 443;

  @override
  String get protocol => 'vmess';

  String get uuid => rawJson['id']?.toString() ?? '';
  int get alterId => int.tryParse(rawJson['aid']?.toString() ?? '0') ?? 0;
  String get security => rawJson['scy']?.toString() ?? 'auto';

  @override
  Map<String, dynamic> get proxyOutbound => {
        'tag': 'proxy',
        'protocol': 'vmess',
        'settings': {
          'vnext': [
            {
              'address': address,
              'port': port,
              'users': [
                {
                  'id': uuid,
                  'alterId': alterId,
                  'security': security,
                  'level': 8,
                }
              ]
            }
          ]
        },
        'streamSettings': streamSettings,
      };
}
