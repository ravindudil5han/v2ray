import 'package:flutter/material.dart';
import '../../core/engine/v2ray_engine.dart';
import '../../services/connection_service.dart';
import '../theme/app_theme.dart';

/// Application configuration and network settings screen.
class SettingsScreen extends StatefulWidget {
  final ConnectionService connectionService;

  const SettingsScreen({super.key, required this.connectionService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _socksPortController;
  late final TextEditingController _httpPortController;

  @override
  void initState() {
    super.initState();
    final s = widget.connectionService.settings;
    _socksPortController = TextEditingController(text: s.socksPort.toString());
    _httpPortController = TextEditingController(text: s.httpPort.toString());
  }

  @override
  void dispose() {
    _socksPortController.dispose();
    _httpPortController.dispose();
    super.dispose();
  }

  void _savePorts() {
    final socks = int.tryParse(_socksPortController.text.trim()) ?? 10808;
    final http = int.tryParse(_httpPortController.text.trim()) ?? 10809;
    widget.connectionService.updatePorts(socksPort: socks, httpPort: http);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Port configuration updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.connectionService,
      builder: (context, _) {
        final settings = widget.connectionService.settings;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Routing Mode Section
              _buildSectionHeader('DEVICE NETWORK ROUTING MODE'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildRoutingOption(
                      title: 'System Proxy Mode (Recommended)',
                      subtitle:
                          'Sets Windows system proxy. All browsers & system apps route automatically.',
                      mode: RoutingMode.systemProxy,
                      current: settings.routingMode,
                      icon: Icons.settings_ethernet_rounded,
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    _buildRoutingOption(
                      title: 'TUN Mode (Full VPN)',
                      subtitle:
                          'Captures 100% of network traffic (TCP, UDP, games, DNS) via Wintun adapter.',
                      mode: RoutingMode.tun,
                      current: settings.routingMode,
                      icon: Icons.vpn_lock_rounded,
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    _buildRoutingOption(
                      title: 'Proxy Only (Manual)',
                      subtitle:
                          'Starts local SOCKS & HTTP ports without changing system proxy settings.',
                      mode: RoutingMode.proxyOnly,
                      current: settings.routingMode,
                      icon: Icons.lan_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Network Routing Rules
              _buildSectionHeader('ROUTING RULES'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeTrackColor: AppTheme.primaryCyan,
                      title: const Text(
                        'Bypass LAN & Local Traffic',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Direct routing for private IPs (192.168.*, 10.*, 172.16.*, localhost)',
                        style: TextStyle(color: AppTheme.disconnectedGrey, fontSize: 12),
                      ),
                      value: settings.bypassLan,
                      onChanged: (val) =>
                          widget.connectionService.updateBypassLan(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Inbound Local Ports
              _buildSectionHeader('LOCAL PROXY PORTS'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _socksPortController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'SOCKS5 Port',
                              prefixIcon: Icon(Icons.hub_rounded,
                                  color: AppTheme.disconnectedGrey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _httpPortController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'HTTP Proxy Port',
                              prefixIcon: Icon(Icons.http_rounded,
                                  color: AppTheme.disconnectedGrey),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryCyan),
                          foregroundColor: AppTheme.primaryCyan,
                        ),
                        onPressed: _savePorts,
                        child: const Text('Apply Ports'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Core & System Info
              _buildSectionHeader('ENGINE & CORE INFORMATION'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Client Version:', value: 'NetMod V2Ray 1.0.0'),
                    SizedBox(height: 8),
                    _InfoRow(
                        label: 'Core Engine:',
                        value: 'Xray 26.3.27 (Official Go amd64)'),
                    SizedBox(height: 8),
                    _InfoRow(label: 'TUN Driver:', value: 'Wintun v0.14.1 (Ready)'),
                    SizedBox(height: 8),
                    _InfoRow(
                        label: 'Protocols:',
                        value: 'VMess, VLESS, Trojan, Shadowsocks, SOCKS5'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.disconnectedGrey,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildRoutingOption({
    required String title,
    required String subtitle,
    required RoutingMode mode,
    required RoutingMode current,
    required IconData icon,
  }) {
    final isSelected = mode == current;
    return InkWell(
      onTap: () => widget.connectionService.updateRoutingMode(mode),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryCyan.withAlpha(30)
                    : Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryCyan : AppTheme.disconnectedGrey,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryCyan : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.disconnectedGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
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
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryCyan,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
