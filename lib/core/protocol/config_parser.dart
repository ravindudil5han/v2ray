import 'dart:convert';
import 'v2ray_url_base.dart';
import 'vmess_parser.dart';
import 'vless_parser.dart';
import 'trojan_parser.dart';
import 'shadowsocks_parser.dart';
import 'socks_parser.dart';

/// Master parser for V2Ray / Xray configuration strings and subscription payloads.
class ConfigParser {
  /// Parses a single connection URL into a [V2RayUrlBase] instance.
  static V2RayUrlBase parseUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('vmess://')) {
      return VmessParser(url: trimmed);
    } else if (trimmed.startsWith('vless://')) {
      return VlessParser(url: trimmed);
    } else if (trimmed.startsWith('trojan://')) {
      return TrojanParser(url: trimmed);
    } else if (trimmed.startsWith('ss://')) {
      return ShadowsocksParser(url: trimmed);
    } else if (trimmed.startsWith('socks://') || trimmed.startsWith('socks5://')) {
      return SocksParser(url: trimmed);
    }
    throw ArgumentError('Unsupported or unrecognized protocol URL: $trimmed');
  }

  /// Parses multiple links or base64 subscription content into a list of parsed URLs.
  static List<V2RayUrlBase> parseSubscriptionContent(String rawContent) {
    final results = <V2RayUrlBase>[];
    var content = rawContent.trim();

    // Check if entire content is base64 encoded (standard subscription format)
    if (!content.contains('\n') && !content.contains('://')) {
      try {
        var base64Str = content;
        if (base64Str.length % 4 > 0) {
          base64Str += '=' * (4 - base64Str.length % 4);
        }
        content = utf8.decode(base64Decode(base64Str));
      } catch (_) {
        // Not pure base64, proceed as raw
      }
    }

    final lines = const LineSplitter().convert(content);
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      try {
        final parsed = parseUrl(trimmed);
        results.add(parsed);
      } catch (_) {
        // Skip invalid lines
      }
    }

    return results;
  }
}
