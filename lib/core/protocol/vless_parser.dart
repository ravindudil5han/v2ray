import 'v2ray_url_base.dart';

/// Parser for `vless://` share links.
class VlessParser extends V2RayUrlBase {
  late final Uri uri;

  VlessParser({required super.url}) {
    if (!url.startsWith('vless://')) {
      throw ArgumentError('Invalid VLESS URL: Must start with vless://');
    }

    final parsed = Uri.tryParse(url);
    if (parsed == null) {
      throw ArgumentError('Malformed VLESS URL');
    }
    uri = parsed;

    final sni = populateTransportSettings(
      transport: uri.queryParameters['type'] ?? 'tcp',
      headerType: uri.queryParameters['headerType'],
      host: uri.queryParameters['host'],
      path: uri.queryParameters['path'],
      serviceName: uri.queryParameters['serviceName'],
      mode: uri.queryParameters['mode'],
    );

    populateTlsSettings(
      streamSecurity: uri.queryParameters['security'] ?? '',
      sni: uri.queryParameters['sni'] ?? sni,
      fingerprint: uri.queryParameters['fp'],
      alpns: uri.queryParameters['alpn'],
      publicKey: uri.queryParameters['pbk'],
      shortId: uri.queryParameters['sid'],
      spiderX: uri.queryParameters['spx'],
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
      : 'VLESS Server';

  @override
  String get protocol => 'vless';

  String get uuid => uri.userInfo;
  String get flow => uri.queryParameters['flow'] ?? '';
  String get encryption => uri.queryParameters['encryption'] ?? 'none';

  @override
  Map<String, dynamic> get proxyOutbound => {
        'tag': 'proxy',
        'protocol': 'vless',
        'settings': {
          'vnext': [
            {
              'address': address,
              'port': port,
              'users': [
                {
                  'id': uuid,
                  'encryption': encryption,
                  'flow': flow,
                  'level': 8,
                }
              ]
            }
          ]
        },
        'streamSettings': streamSettings,
      };
}
