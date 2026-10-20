import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modal dialog showing verified public outbound IP details to prove traffic routing.
class IpInfoDialog extends StatelessWidget {
  final Map<String, dynamic>? ipInfo;
  final bool isLoading;
  final VoidCallback onRefresh;

  const IpInfoDialog({
    super.key,
    required this.ipInfo,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.public_rounded, color: AppTheme.primaryCyan, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Outbound Network IP',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: isLoading
          ? const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryCyan),
              ),
            )
          : (ipInfo == null)
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.disconnectedGrey),
                    SizedBox(height: 12),
                    Text(
                      'No IP information available.\nMake sure you are connected.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.disconnectedGrey),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.connectedGreen.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.connectedGreen.withAlpha(60)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: AppTheme.connectedGreen, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Device traffic routed through V2Ray',
                              style: TextStyle(
                                color: AppTheme.connectedGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRow('Public IP:', ipInfo!['query']?.toString() ?? 'Unknown'),
                    const SizedBox(height: 8),
                    _buildRow('Country:', '${ipInfo!['country'] ?? ''} (${ipInfo!['countryCode'] ?? ''})'),
                    const SizedBox(height: 8),
                    _buildRow('City / Region:', '${ipInfo!['city'] ?? ''}, ${ipInfo!['regionName'] ?? ''}'),
                    const SizedBox(height: 8),
                    _buildRow('ISP / ASN:', ipInfo!['isp']?.toString() ?? 'Unknown'),
                  ],
                ),
      actions: [
        TextButton(
          onPressed: onRefresh,
          child: const Text('Refresh', style: TextStyle(color: AppTheme.primaryCyan)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryCyan,
            foregroundColor: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.disconnectedGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
