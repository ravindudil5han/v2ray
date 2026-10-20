import 'package:flutter/material.dart';
import '../../core/payload/netmod_payload.dart';
import '../../services/connection_service.dart';
import '../../services/profile_service.dart';
import '../theme/app_theme.dart';

/// NetMod HTTP Payload Generator & Bug Host / SNI Injector Screen.
class PayloadScreen extends StatefulWidget {
  final ConnectionService connectionService;
  final ProfileService profileService;

  const PayloadScreen({
    super.key,
    required this.connectionService,
    required this.profileService,
  });

  @override
  State<PayloadScreen> createState() => _PayloadScreenState();
}

class _PayloadScreenState extends State<PayloadScreen> {
  late bool _enabled;
  late String _method;
  late final TextEditingController _payloadController;
  late final TextEditingController _bugHostController;
  late final TextEditingController _sniController;

  @override
  void initState() {
    super.initState();
    final p = widget.connectionService.activeProfile?.netModPayload ??
        const NetModPayloadConfig();
    _enabled = p.enabled;
    _method = p.requestMethod;
    _payloadController = TextEditingController(
      text: p.payloadText.isNotEmpty
          ? p.payloadText
          : NetModPayloadInjector.defaultConnectPayload,
    );
    _bugHostController = TextEditingController(text: p.bugHost);
    _sniController = TextEditingController(text: p.sni);
  }

  @override
  void dispose() {
    _payloadController.dispose();
    _bugHostController.dispose();
    _sniController.dispose();
    super.dispose();
  }

  void _insertTag(String tag) {
    final text = _payloadController.text;
    final selection = _payloadController.selection;
    final newText = text.replaceRange(
      selection.start >= 0 ? selection.start : text.length,
      selection.end >= 0 ? selection.end : text.length,
      tag,
    );
    _payloadController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (selection.start >= 0 ? selection.start : text.length) +
            tag.length,
      ),
    );
    setState(() {});
  }

  void _applyPreset(String preset) {
    if (preset == 'connect') {
      _payloadController.text = NetModPayloadInjector.defaultConnectPayload;
      _method = 'CONNECT';
    } else if (preset == 'http') {
      _payloadController.text = NetModPayloadInjector.defaultHttpPayload;
      _method = 'GET';
    } else if (preset == 'front_inject') {
      _payloadController.text =
          'GET / HTTP/1.1[crlf]Host: [host][crlf]X-Online-Host: [host][crlf]Connection: Upgrade[crlf][crlf]CONNECT [host_port] HTTP/1.1[crlf][crlf]';
      _method = 'GET';
    }
    setState(() {});
  }

  void _savePayload() async {
    final active = widget.connectionService.activeProfile;
    if (active == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active profile selected')),
      );
      return;
    }

    final newConfig = NetModPayloadConfig(
      enabled: _enabled,
      requestMethod: _method,
      payloadText: _payloadController.text.trim(),
      bugHost: _bugHostController.text.trim(),
      sni: _sniController.text.trim(),
    );

    final updated = active.copyWith(netModPayload: newConfig);
    await widget.profileService.updateProfile(updated);
    widget.connectionService.setActiveProfile(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NetMod Payload saved to active profile!'),
          backgroundColor: AppTheme.connectedGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = widget.connectionService.activeProfile;
    final serverAddress = activeProfile?.address ?? 'example.com';
    final serverPort = activeProfile?.port ?? 443;

    final formattedPreview = NetModPayloadInjector.formatPayload(
      rawPayload: _payloadController.text,
      serverAddress: serverAddress,
      serverPort: serverPort,
      bugHost: _bugHostController.text.trim(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('NetMod Payload Injector'),
        actions: [
          IconButton(
            tooltip: 'Save Payload',
            icon: const Icon(Icons.save_rounded, color: AppTheme.primaryCyan),
            onPressed: _savePayload,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Enable switch card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _enabled ? AppTheme.primaryCyan : AppTheme.cardBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enable Custom Payload & Bug Host',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _enabled
                            ? 'Injects custom headers & SNI spoofing into tunnel'
                            : 'Standard V2Ray protocol headers only',
                        style: const TextStyle(
                          color: AppTheme.disconnectedGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enabled,
                  activeTrackColor: AppTheme.primaryCyan,
                  onChanged: (val) => setState(() => _enabled = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Bug Host & SNI Inputs
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bugHostController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Bug Host (ISP Host)',
                    hintText: 'e.g. cdn.whatsapp.net',
                    prefixIcon: Icon(Icons.bug_report_rounded,
                        color: AppTheme.warningAmber),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _sniController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'TLS SNI Override',
                    hintText: 'e.g. zoom.us',
                    prefixIcon: Icon(Icons.security_rounded,
                        color: AppTheme.accentPurple),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Presets selector
          Row(
            children: [
              const Text(
                'PRESETS:',
                style: TextStyle(
                  color: AppTheme.disconnectedGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('CONNECT'),
                    onPressed: () => _applyPreset('connect'),
                    backgroundColor: AppTheme.cardBackground,
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  ActionChip(
                    label: const Text('HTTP Upgrade'),
                    onPressed: () => _applyPreset('http'),
                    backgroundColor: AppTheme.cardBackground,
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  ActionChip(
                    label: const Text('Front Inject'),
                    onPressed: () => _applyPreset('front_inject'),
                    backgroundColor: AppTheme.cardBackground,
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tag chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildTagChip('[host_port]'),
              _buildTagChip('[host]'),
              _buildTagChip('[port]'),
              _buildTagChip('[protocol]'),
              _buildTagChip('[crlf]'),
              _buildTagChip('[ua]'),
            ],
          ),

          const SizedBox(height: 16),

          // Payload Text Editor
          TextField(
            controller: _payloadController,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: AppTheme.primaryCyan,
            ),
            decoration: const InputDecoration(
              labelText: 'HTTP Payload Pattern',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 20),

          // Live Preview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.terminal_rounded, size: 16, color: AppTheme.connectedGreen),
                    SizedBox(width: 8),
                    Text(
                      'HEADER PREVIEW (What gets sent to server/ISP)',
                      style: TextStyle(
                        color: AppTheme.connectedGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.cardBorder, height: 20),
                Text(
                  formattedPreview,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _savePayload,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text(
              'Save Payload to Server',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return InkWell(
      onTap: () => _insertTag(tag),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            color: AppTheme.primaryCyan,
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
