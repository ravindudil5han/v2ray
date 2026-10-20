import 'package:flutter_test/flutter_test.dart';
import 'package:netmod_v2ray/core/engine/v2ray_engine.dart';
import 'package:netmod_v2ray/core/payload/netmod_payload.dart';
import 'package:netmod_v2ray/core/protocol/config_parser.dart';
import 'package:netmod_v2ray/core/protocol/vless_parser.dart';
import 'package:netmod_v2ray/core/protocol/vmess_parser.dart';
import 'package:netmod_v2ray/core/protocol/trojan_parser.dart';
import 'package:netmod_v2ray/core/protocol/shadowsocks_parser.dart';

void main() {
  group('V2Ray & NetMod Protocol Tests', () {
    test('VMess URL Parser & Config Generation', () {
      const sampleVmess =
          'vmess://eyJ2IjoiMiIsInBzIjoiTXkgVk1lc3MgU2VydmVyIiwiYWRkIjoiMTk4LjUxLjEwMC4xIiwicG9ydCI6ODQ0MywiaWQiOiJkNjU0Y2NhNS00M2Y2LTRiODctOTA4MS1mYzUxMDkzMTRiNjQiLCJhaWQiOjAsInNjeSI6ImF1dG8iLCJuZXQiOiJ3cyIsInR5cGUiOiJub25lIiwiaG9zdCI6ImNmLm5ldG1vZC5vcGVuIiwicGF0aCI6Ii92MnJheSIsInRscyI6InRscyJ9';

      final parser = ConfigParser.parseUrl(sampleVmess);
      expect(parser, isA<VmessParser>());
      expect(parser.remark, 'My VMess Server');
      expect(parser.address, '198.51.100.1');
      expect(parser.port, 8443);
      expect(parser.protocol, 'vmess');

      // Test generating full JSON config
      final fullConfig = parser.generateFullConfig(
        routingMode: RoutingMode.systemProxy,
        socksPort: 10808,
        httpPort: 10809,
        bypassLan: true,
      );
      expect(fullConfig, contains('"tag": "socks-in"'));
      expect(fullConfig, contains('"tag": "http-in"'));
      expect(fullConfig, contains('"tag": "proxy"'));
      expect(fullConfig, contains('"protocol": "vmess"'));
      expect(fullConfig, contains('"geoip:private"'));
    });

    test('VLESS Reality URL Parser', () {
      const sampleVless =
          'vless://b66c4217-1836-419b-a01b-c7438e8cbfa2@1.1.1.1:443?type=tcp&security=reality&pbk=w69y8f31XwQ0hS3E_q8j5N7mX_2b8c9d0e1f2a3b4c5&fp=chrome&sni=cloudflare.com#US%20East%20VLESS%20Reality';

      final parser = ConfigParser.parseUrl(sampleVless);
      expect(parser, isA<VlessParser>());
      expect(parser.remark, 'US East VLESS Reality');
      expect(parser.address, '1.1.1.1');
      expect(parser.port, 443);

      final fullConfig = parser.generateFullConfig(
        routingMode: RoutingMode.tun,
      );
      expect(fullConfig, contains('"tag": "tun-in"'));
      expect(fullConfig, contains('"protocol": "tun"'));
      expect(fullConfig, contains('"protocol": "vless"'));
    });

    test('Trojan & Shadowsocks Parsers', () {
      const sampleTrojan =
          'trojan://mysecretpassword@8.8.8.8:443?security=tls&type=ws&host=dns.google&path=%2Ftrojan#TrojanServer';
      final trojanParser = ConfigParser.parseUrl(sampleTrojan);
      expect(trojanParser, isA<TrojanParser>());
      expect(trojanParser.remark, 'TrojanServer');
      expect(trojanParser.address, '8.8.8.8');

      const sampleSS = 'ss://YWVzLTI1Ni1nY206cGFzc3dvcmRAMTkyLjAuMi4xOjg0NDM=#SSServer';
      final ssParser = ConfigParser.parseUrl(sampleSS);
      expect(ssParser, isA<ShadowsocksParser>());
      expect(ssParser.remark, 'SSServer');
    });

    test('NetMod Payload Formatting & Bug Host Injection', () {
      const template =
          'CONNECT [host_port] [protocol][crlf]Host: [host][crlf]Connection: Keep-Alive[crlf][crlf]';
      final formatted = NetModPayloadInjector.formatPayload(
        rawPayload: template,
        serverAddress: 'my-v2ray-server.net',
        serverPort: 443,
        bugHost: 'cdn.whatsapp.net',
      );

      expect(formatted, contains('CONNECT cdn.whatsapp.net:443 HTTP/1.1\r\n'));
      expect(formatted, contains('Host: cdn.whatsapp.net\r\n'));

      // Test outbound injection
      final outbound = {
        'tag': 'proxy',
        'streamSettings': {
          'network': 'ws',
          'wsSettings': {'headers': <String, dynamic>{}},
          'tlsSettings': {'serverName': 'original.com'},
        }
      };

      NetModPayloadInjector.apply(
        outbound: outbound,
        payloadConfig: const NetModPayloadConfig(
          enabled: true,
          bugHost: 'cdn.whatsapp.net',
          sni: 'spoofed.sni.com',
        ),
        serverAddress: 'original.com',
        serverPort: 443,
      );

      final tls = (outbound['streamSettings'] as Map)['tlsSettings'] as Map;
      expect(tls['serverName'], 'spoofed.sni.com');

      final ws = (outbound['streamSettings'] as Map)['wsSettings'] as Map;
      expect(ws['headers']['Host'], 'cdn.whatsapp.net');
    });
  });
}
