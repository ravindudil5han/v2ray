import 'dart:convert';
import '../engine/v2ray_engine.dart';
import '../payload/netmod_payload.dart';

/// Base class for parsing V2Ray proxy URLs and generating full Xray-core JSON configurations.
abstract class V2RayUrlBase {
  final String url;
  V2RayUrlBase({required this.url});

  String get address => '';
  int get port => 443;
  String get remark => 'Server';
  String get protocol => 'vmess';

  Map<String, dynamic> streamSettings = {'network': 'tcp'};

  /// Primary outbound proxy config.
  Map<String, dynamic> get proxyOutbound;

  /// Populates standard transport settings (ws, tcp, grpc, h2, quic, etc.)
  String populateTransportSettings({
    String? transport,
    String? headerType,
    String? host,
    String? path,
    String? seed,
    String? serviceName,
    String? mode,
  }) {
    String sni = '';
    final net = (transport ?? 'tcp').toLowerCase();
    streamSettings['network'] = net;

    if (net == 'tcp') {
      streamSettings['tcpSettings'] = {
        'header': {'type': headerType ?? 'none'}
      };
      if (headerType == 'http' && (host != null || path != null)) {
        streamSettings['tcpSettings']['header']['request'] = {
          'version': '1.1',
          'method': 'GET',
          'path': path != null ? path.split(',') : ['/'],
          'headers': {
            'Host': host != null ? host.split(',') : [''],
            'User-Agent': [
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            ],
            'Connection': ['keep-alive'],
          }
        };
        sni = host ?? '';
      }
    } else if (net == 'ws') {
      streamSettings['wsSettings'] = {
        'path': path ?? '/',
        'headers': {'Host': host ?? ''}
      };
      sni = host ?? '';
    } else if (net == 'grpc') {
      streamSettings['grpcSettings'] = {
        'serviceName': serviceName ?? path ?? '',
        'multiMode': mode == 'multi',
      };
      sni = host ?? '';
    } else if (net == 'h2' || net == 'http') {
      streamSettings['network'] = 'h2';
      streamSettings['httpSettings'] = {
        'host': host != null ? host.split(',') : [''],
        'path': path ?? '/',
      };
      sni = host ?? '';
    }
    return sni;
  }

  /// Populates TLS and Reality settings.
  void populateTlsSettings({
    String? streamSecurity,
    String? sni,
    String? fingerprint,
    String? alpns,
    String? publicKey,
    String? shortId,
    String? spiderX,
    String? verifyPeerCertByName,
    String? pinnedPeerCertSha256,
  }) {
    final sec = (streamSecurity ?? '').toLowerCase();
    final effectiveSni = (sni != null && sni.isNotEmpty) ? sni : address;

    // Automatically resolve verifyPeerCertByName:
    // If explicitly provided via link (vcn), use it.
    // Otherwise, if SNI differs from server address and address is a hostname (not an IP),
    // verify the server's certificate against address so spoofed SNI / Bug Host handshakes succeed.
    final isAddressIp = RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(address);
    final effectiveVcn = (verifyPeerCertByName != null && verifyPeerCertByName.isNotEmpty)
        ? verifyPeerCertByName
        : ((effectiveSni != address && !isAddressIp && address.isNotEmpty)
            ? address
            : null);

    if (sec == 'tls') {
      streamSettings['security'] = 'tls';
      streamSettings['tlsSettings'] = {
        'serverName': effectiveSni,
        if (effectiveVcn != null && effectiveVcn.isNotEmpty)
          'verifyPeerCertByName': effectiveVcn,
        if (pinnedPeerCertSha256 != null && pinnedPeerCertSha256.isNotEmpty)
          'pinnedPeerCertSha256': pinnedPeerCertSha256,
        'fingerprint': (fingerprint != null && fingerprint.isNotEmpty)
            ? fingerprint
            : 'chrome',
        if (alpns != null && alpns.isNotEmpty)
          'alpn': alpns.contains(',') ? alpns.split(',') : [alpns],
      };
    } else if (sec == 'reality') {
      streamSettings['security'] = 'reality';
      streamSettings['realitySettings'] = {
        'show': false,
        'serverName': effectiveSni,
        'fingerprint': (fingerprint != null && fingerprint.isNotEmpty)
            ? fingerprint
            : 'chrome',
        'publicKey': publicKey ?? '',
        'shortId': shortId ?? '',
        'spiderX': spiderX ?? '/',
      };
    } else {
      streamSettings['security'] = 'none';
    }
  }

  /// Generates the complete Xray-core JSON config.
  String generateFullConfig({
    required RoutingMode routingMode,
    int socksPort = 10808,
    int httpPort = 10809,
    bool bypassLan = true,
    NetModPayloadConfig? netModPayload,
  }) {
    // Apply NetMod Payload injection if provided
    final outbound = Map<String, dynamic>.from(proxyOutbound);
    if (netModPayload != null && netModPayload.enabled) {
      NetModPayloadInjector.apply(
        outbound: outbound,
        payloadConfig: netModPayload,
        serverAddress: address,
        serverPort: port,
      );
    }

    final inbounds = <Map<String, dynamic>>[];

    // SOCKS5 inbound
    inbounds.add({
      'tag': 'socks-in',
      'port': socksPort,
      'listen': '127.0.0.1',
      'protocol': 'socks',
      'settings': {
        'auth': 'noauth',
        'udp': true,
      },
      'sniffing': {
        'enabled': true,
        'destOverride': ['http', 'tls', 'quic'],
      }
    });

    // HTTP inbound
    inbounds.add({
      'tag': 'http-in',
      'port': httpPort,
      'listen': '127.0.0.1',
      'protocol': 'http',
      'settings': {
        'allowTransparent': false,
      }
    });

    // If TUN mode is requested, add native Wintun inbound
    if (routingMode == RoutingMode.tun) {
      inbounds.add({
        'tag': 'tun-in',
        'port': 0,
        'protocol': 'tun',
        'settings': {
          'name': 'wintun',
          'desc': 'NetMod V2Ray Wintun',
          'mtu': 1500,
          'gateway': ['172.19.0.1'],
          'dns': ['1.1.1.1', '8.8.8.8'],
          'autoSystemRoutingTable': ['0.0.0.0/0'],
          'autoOutboundsInterface': 'auto',
        },
        'sniffing': {
          'enabled': true,
          'destOverride': ['http', 'tls', 'quic'],
        }
      });
    }

    // Outbounds
    final outbounds = <Map<String, dynamic>>[
      outbound,
      {
        'tag': 'direct',
        'protocol': 'freedom',
        'settings': {
          'domainStrategy': 'UseIP',
        }
      },
      {
        'tag': 'block',
        'protocol': 'blackhole',
        'settings': {
          'response': {'type': 'none'}
        }
      }
    ];

    // Routing rules
    final rules = <Map<String, dynamic>>[];

    if (bypassLan) {
      rules.add({
        'type': 'field',
        'outboundTag': 'direct',
        'ip': [
          'geoip:private',
          '127.0.0.0/8',
          '10.0.0.0/8',
          '172.16.0.0/12',
          '192.168.0.0/16',
        ]
      });
      rules.add({
        'type': 'field',
        'outboundTag': 'direct',
        'domain': [
          'domain:local',
          'domain:localhost',
        ]
      });
    }

    // Default proxy rule for all remaining traffic
    rules.add({
      'type': 'field',
      'outboundTag': 'proxy',
      'network': 'tcp,udp',
    });

    final config = {
      'log': {
        'loglevel': 'info',
        'dnsLog': false,
      },
      'dns': {
        'servers': [
          '1.1.1.1',
          '8.8.8.8',
          'localhost',
        ]
      },
      'inbounds': inbounds,
      'outbounds': outbounds,
      'routing': {
        'domainStrategy': 'AsIs',
        'rules': rules,
      }
    };

    return const JsonEncoder.withIndent('  ').convert(config);
  }
}
