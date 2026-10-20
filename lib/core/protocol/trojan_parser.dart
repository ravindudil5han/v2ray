import 'v2ray_url_base.dart';

/// Parser for `trojan://` share links.
class TrojanParser extends V2RayUrlBase {
  late final Uri uri;

  TrojanParser({required super.url}) {
    if (!url.startsWith('trojan://')) {
      throw ArgumentError('Invalid Trojan URL: Must start with trojan://');
    }

    final parsed = Uri.tryParse(url);
    if (parsed == null) {
      throw ArgumentError('Malformed Trojan URL');
    }
    uri = parsed;

    final sni = populateTransportSettings(
      transport: uri.queryParameters['type'] ?? 'tcp',
      headerType: uri.queryParameters['headerType'],
      host: uri.queryParameters['host'],
      path: uri.queryParameters['path'],
      serviceName: uri.queryParameters['serviceName'],
    );

    populateTlsSettings(
      streamSecurity: uri.queryParameters['security'] ?? 'tls',
      sni: uri.queryParameters['sni'] ?? sni,
      fingerprint: uri.queryParameters['fp'],
      alpns: uri.queryParameters['alpn'],
      verifyPeerCertByName: uri.queryParameters['vcn'],
      pinnedPeerCertSha256: uri.queryParameters['pcs'] ?? uri.queryParameters['pinSHA256'],
    );
  }

  @override
  String get address => uri.host;

  @override
  int get port => uri.hasPort ? uri.port : 443;

  @override
  String get remark => uri.fragment.isNotEmpty
      ? Uri.decodeFull(uri.fragment.replaceAll('+', '%20'))
      : 'Trojan Server';

  @override
  String get protocol => 'trojan';

  String get password => uri.userInfo;

  @override
  Map<String, dynamic> get proxyOutbound => {
        'tag': 'proxy',
        'protocol': 'trojan',
        'settings': {
          'servers': [
            {
              'address': address,
              'port': port,
              'password': password,
              'level': 8,
            }
          ]
        },
        'streamSettings': streamSettings,
      };
}
