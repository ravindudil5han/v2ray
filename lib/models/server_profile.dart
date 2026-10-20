import 'package:uuid/uuid.dart';
import '../core/payload/netmod_payload.dart';
import '../core/protocol/config_parser.dart';

/// Represents a configured V2Ray proxy server profile.
class ServerProfile {
  final String id;
  final String name;
  final String protocol;
  final String address;
  final int port;
  final String rawUrl;
  final String? customConfigJson;
  final int? pingMs;
  final DateTime? lastUsed;
  final NetModPayloadConfig netModPayload;

  ServerProfile({
    String? id,
    required this.name,
    required this.protocol,
    required this.address,
    required this.port,
    required this.rawUrl,
    this.customConfigJson,
    this.pingMs,
    this.lastUsed,
    NetModPayloadConfig? netModPayload,
  })  : id = id ?? const Uuid().v4(),
        netModPayload = netModPayload ?? const NetModPayloadConfig();

  factory ServerProfile.fromUrl(String url, {String? customName}) {
    final parsed = ConfigParser.parseUrl(url);
    return ServerProfile(
      name: customName ?? parsed.remark,
      protocol: parsed.protocol,
      address: parsed.address,
      port: parsed.port,
      rawUrl: url,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'protocol': protocol,
        'address': address,
        'port': port,
        'rawUrl': rawUrl,
        'customConfigJson': customConfigJson,
        'pingMs': pingMs,
        'lastUsed': lastUsed?.toIso8601String(),
        'netModPayload': netModPayload.toJson(),
      };

  factory ServerProfile.fromJson(Map<String, dynamic> json) => ServerProfile(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Server',
        protocol: json['protocol'] as String? ?? 'vmess',
        address: json['address'] as String? ?? '',
        port: json['port'] as int? ?? 443,
        rawUrl: json['rawUrl'] as String? ?? '',
        customConfigJson: json['customConfigJson'] as String?,
        pingMs: json['pingMs'] as int?,
        lastUsed: json['lastUsed'] != null
            ? DateTime.tryParse(json['lastUsed'] as String)
            : null,
        netModPayload: json['netModPayload'] != null
            ? NetModPayloadConfig.fromJson(
                json['netModPayload'] as Map<String, dynamic>)
            : const NetModPayloadConfig(),
      );

  ServerProfile copyWith({
    String? name,
    String? protocol,
    String? address,
    int? port,
    String? rawUrl,
    String? customConfigJson,
    int? pingMs,
    DateTime? lastUsed,
    NetModPayloadConfig? netModPayload,
  }) {
    return ServerProfile(
      id: id,
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      address: address ?? this.address,
      port: port ?? this.port,
      rawUrl: rawUrl ?? this.rawUrl,
      customConfigJson: customConfigJson ?? this.customConfigJson,
      pingMs: pingMs ?? this.pingMs,
      lastUsed: lastUsed ?? this.lastUsed,
      netModPayload: netModPayload ?? this.netModPayload,
    );
  }
}
