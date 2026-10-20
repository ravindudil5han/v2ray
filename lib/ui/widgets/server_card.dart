import 'package:flutter/material.dart';
import '../../models/server_profile.dart';
import '../theme/app_theme.dart';

/// List card representing an individual server profile with latency pill.
class ServerCard extends StatelessWidget {
  final ServerProfile profile;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPing;

  const ServerCard({
    super.key,
    required this.profile,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onPing,
  });

  Color _getProtocolColor() {
    switch (profile.protocol.toLowerCase()) {
      case 'vmess':
        return AppTheme.primaryCyan;
      case 'vless':
        return AppTheme.accentPurple;
      case 'trojan':
        return AppTheme.warningAmber;
      case 'shadowsocks':
      case 'ss':
        return AppTheme.connectedGreen;
      default:
        return AppTheme.disconnectedGrey;
    }
  }

  Widget _buildPingBadge() {
    if (profile.pingMs == null) {
      return GestureDetector(
        onTap: onPing,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.speed_rounded, size: 12, color: AppTheme.disconnectedGrey),
              SizedBox(width: 4),
              Text(
                'Ping',
                style: TextStyle(
                  color: AppTheme.disconnectedGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (profile.pingMs! < 0) {
      return GestureDetector(
        onTap: onPing,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withAlpha(25),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.errorRed.withAlpha(80)),
          ),
          child: const Text(
            'Timeout',
            style: TextStyle(
              color: AppTheme.errorRed,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    Color badgeColor = AppTheme.connectedGreen;
    if (profile.pingMs! > 250) {
      badgeColor = AppTheme.errorRed;
    } else if (profile.pingMs! > 120) {
      badgeColor = AppTheme.warningAmber;
    }

    return GestureDetector(
      onTap: onPing,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withAlpha(25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: badgeColor.withAlpha(80)),
        ),
        child: Text(
          '${profile.pingMs} ms',
          style: TextStyle(
            color: badgeColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final protoColor = _getProtocolColor();

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryCyan.withAlpha(15)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryCyan : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryCyan : AppTheme.disconnectedGrey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryCyan,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Protocol tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: protoColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: protoColor.withAlpha(80)),
                        ),
                        child: Text(
                          profile.protocol.toUpperCase(),
                          style: TextStyle(
                            color: protoColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          profile.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${profile.address}:${profile.port}',
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
            const SizedBox(width: 10),
            _buildPingBadge(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.disconnectedGrey, size: 20),
              color: AppTheme.cardBackground,
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryCyan),
                      SizedBox(width: 10),
                      Text('Edit Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
