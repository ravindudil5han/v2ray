import 'v2ray_url_base.dart';

/// Parser for standard `socks://` and `socks5://` share links.
class SocksParser extends V2RayUrlBase {
  late final Uri uri;

  SocksParser({required super.url}) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) {
      throw ArgumentError('Malformed SOCKS URL');
    }
    uri = parsed;
  }

  @override
  String get address => uri.host;

  @override
  int get port => uri.hasPort ? uri.port : 1080;

  @override
  String get remark => uri.fragment.isNotEmpty
      ? Uri.decodeFull(uri.fragment.replaceAll('+', '%20'))
      : 'SOCKS5 Server';

  @override
  String get protocol => 'socks';

  String? get username => uri.userInfo.isNotEmpty && uri.userInfo.contains(':')
      ? uri.userInfo.split(':')[0]
      : (uri.userInfo.isNotEmpty ? uri.userInfo : null);

  String? get password => uri.userInfo.isNotEmpty && uri.userInfo.contains(':')
      ? uri.userInfo.split(':')[1]
      : null;

  @override
  Map<String, dynamic> get proxyOutbound {
    final users = <Map<String, dynamic>>[];
    if (username != null && password != null) {
      users.add({
        'user': username,
        'pass': password,
        'level': 8,
      });
    }

    return {
      'tag': 'proxy',
      'protocol': 'socks',
      'settings': {
        'servers': [
          {
            'address': address,
            'port': port,
            'users': users.isNotEmpty ? users : null,
          }
        ]
      },
      'streamSettings': streamSettings,
    };
  }
}
