import 'package:flutter/material.dart';
import '../../core/engine/v2ray_engine.dart';
import '../../services/connection_service.dart';
import '../../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_button.dart';
import '../widgets/speed_meter_card.dart';
import '../widgets/ip_info_dialog.dart';

/// Main NetMod Dashboard Screen.
class DashboardScreen extends StatelessWidget {
  final ConnectionService connectionService;
  final ProfileService profileService;
  final VoidCallback onNavigateToProfiles;

  const DashboardScreen({
    super.key,
    required this.connectionService,
    required this.profileService,
    required this.onNavigateToProfiles,
  });

  void _showIpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ListenableBuilder(
        listenable: connectionService,
        builder: (ctx, _) => IpInfoDialog(
          ipInfo: connectionService.outboundIpInfo,
          isLoading: connectionService.isCheckingIp,
          onRefresh: () => connectionService.checkOutboundIp(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: connectionService,
      builder: (context, _) {
        final activeProfile = connectionService.activeProfile;
        final routingMode = connectionService.settings.routingMode;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      'NM',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('NetMod V2Ray'),
              ],
            ),
            actions: [
              // Routing Mode Badge
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      routingMode == RoutingMode.tun
                          ? Icons.vpn_lock_rounded
                          : (routingMode == RoutingMode.systemProxy
                              ? Icons.settings_ethernet_rounded
                              : Icons.lan_rounded),
                      size: 14,
                      color: AppTheme.primaryCyan,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      routingMode.displayName,
                      style: const TextStyle(
                        color: AppTheme.primaryCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Check Outbound IP',
                icon: const Icon(Icons.public_rounded, color: AppTheme.primaryCyan),
                onPressed: () {
                  connectionService.checkOutboundIp();
                  _showIpDialog(context);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Duration & Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: connectionService.isConnected
                              ? AppTheme.connectedGreen
                              : AppTheme.disconnectedGrey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        connectionService.isConnected
                            ? connectionService.durationString
                            : '00:00:00',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Big Animated Connect Button
                ConnectionButton(
                  state: connectionService.state,
                  onTap: () => connectionService.toggleConnection(),
                ),

                const SizedBox(height: 36),

                // Real-time Speed & Data Meters
                SpeedMeterCard(
                  stats: connectionService.stats,
                  isConnected: connectionService.isConnected,
                ),

                const SizedBox(height: 20),

                // Active Profile Selection Card
                InkWell(
                  onTap: onNavigateToProfiles,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryCyan.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.dns_rounded,
                              color: AppTheme.primaryCyan, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeProfile?.name ?? 'No Server Selected',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeProfile != null
                                    ? '${activeProfile.protocol.toUpperCase()} • ${activeProfile.address}:${activeProfile.port}'
                                    : 'Tap to select or import server',
                                style: const TextStyle(
                                  color: AppTheme.disconnectedGrey,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (connectionService.latencyMs != null &&
                            connectionService.latencyMs! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.connectedGreen.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppTheme.connectedGreen.withAlpha(80)),
                            ),
                            child: Text(
                              '${connectionService.latencyMs} ms',
                              style: const TextStyle(
                                color: AppTheme.connectedGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.disconnectedGrey),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Diagnostics & Tools Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => connectionService.testLatency(),
                        icon: const Icon(Icons.speed_rounded,
                            size: 16, color: AppTheme.primaryCyan),
                        label: const Text('Test Ping',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          connectionService.checkOutboundIp();
                          _showIpDialog(context);
                        },
                        icon: const Icon(Icons.location_on_rounded,
                            size: 16, color: AppTheme.connectedGreen),
                        label: const Text('Outbound IP',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
