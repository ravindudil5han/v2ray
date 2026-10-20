import 'package:flutter/material.dart';
import '../../core/engine/v2ray_engine.dart';
import '../theme/app_theme.dart';

/// Cards displaying real-time download and upload metrics.
class SpeedMeterCard extends StatelessWidget {
  final TrafficStats stats;
  final bool isConnected;

  const SpeedMeterCard({
    super.key,
    required this.stats,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Download card
        Expanded(
          child: _buildMetricTile(
            title: 'DOWNLOAD',
            speed: isConnected
                ? TrafficStats.formatSpeed(stats.downloadSpeedBytes)
                : '0.0 KB/s',
            total: isConnected
                ? TrafficStats.formatBytes(stats.totalDownloadBytes)
                : '0 B',
            icon: Icons.arrow_downward_rounded,
            iconColor: AppTheme.primaryCyan,
          ),
        ),
        const SizedBox(width: 12),
        // Upload card
        Expanded(
          child: _buildMetricTile(
            title: 'UPLOAD',
            speed: isConnected
                ? TrafficStats.formatSpeed(stats.uploadSpeedBytes)
                : '0.0 KB/s',
            total: isConnected
                ? TrafficStats.formatBytes(stats.totalUploadBytes)
                : '0 B',
            icon: Icons.arrow_upward_rounded,
            iconColor: AppTheme.accentPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String speed,
    required String total,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.disconnectedGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            speed,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: $total',
            style: TextStyle(
              color: Colors.white.withAlpha(140),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
