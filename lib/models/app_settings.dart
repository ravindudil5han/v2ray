import '../core/engine/v2ray_engine.dart';

/// Application configuration and preferences.
class AppSettings {
  final RoutingMode routingMode;
  final int socksPort;
  final int httpPort;
  final bool bypassLan;
  final String primaryDns;
  final String secondaryDns;
  final bool autoConnect;
  final String? activeProfileId;

  const AppSettings({
    this.routingMode = RoutingMode.systemProxy,
    this.socksPort = 10808,
    this.httpPort = 10809,
    this.bypassLan = true,
    this.primaryDns = '1.1.1.1',
    this.secondaryDns = '8.8.8.8',
    this.autoConnect = false,
    this.activeProfileId,
  });

  Map<String, dynamic> toJson() => {
        'routingMode': routingMode.index,
        'socksPort': socksPort,
        'httpPort': httpPort,
        'bypassLan': bypassLan,
        'primaryDns': primaryDns,
        'secondaryDns': secondaryDns,
        'autoConnect': autoConnect,
        'activeProfileId': activeProfileId,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        routingMode: RoutingMode.values[
            (json['routingMode'] as int?)?.clamp(0, RoutingMode.values.length - 1) ??
                0],
        socksPort: json['socksPort'] as int? ?? 10808,
        httpPort: json['httpPort'] as int? ?? 10809,
        bypassLan: json['bypassLan'] as bool? ?? true,
        primaryDns: json['primaryDns'] as String? ?? '1.1.1.1',
        secondaryDns: json['secondaryDns'] as String? ?? '8.8.8.8',
        autoConnect: json['autoConnect'] as bool? ?? false,
        activeProfileId: json['activeProfileId'] as String?,
      );

  AppSettings copyWith({
    RoutingMode? routingMode,
    int? socksPort,
    int? httpPort,
    bool? bypassLan,
    String? primaryDns,
    String? secondaryDns,
    bool? autoConnect,
    String? activeProfileId,
  }) {
    return AppSettings(
      routingMode: routingMode ?? this.routingMode,
      socksPort: socksPort ?? this.socksPort,
      httpPort: httpPort ?? this.httpPort,
      bypassLan: bypassLan ?? this.bypassLan,
      primaryDns: primaryDns ?? this.primaryDns,
      secondaryDns: secondaryDns ?? this.secondaryDns,
      autoConnect: autoConnect ?? this.autoConnect,
      activeProfileId: activeProfileId ?? this.activeProfileId,
    );
  }
}
