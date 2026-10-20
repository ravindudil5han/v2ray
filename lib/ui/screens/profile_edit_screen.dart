import 'package:flutter/material.dart';
import '../../models/server_profile.dart';
import '../theme/app_theme.dart';

/// Form screen to create or edit a server profile.
class ProfileEditScreen extends StatefulWidget {
  final ServerProfile? existingProfile;
  final Function(ServerProfile) onSave;

  const ProfileEditScreen({
    super.key,
    this.existingProfile,
    required this.onSave,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _protocol;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _portController;
  late final TextEditingController _uuidController;
  late final TextEditingController _sniController;
  late final TextEditingController _pathController;
  String _transport = 'ws';
  String _security = 'tls';

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _protocol = p?.protocol ?? 'vmess';
    _nameController = TextEditingController(text: p?.name ?? 'My Server');
    _addressController = TextEditingController(text: p?.address ?? '');
    _portController = TextEditingController(text: (p?.port ?? 443).toString());
    _uuidController = TextEditingController();
    _sniController = TextEditingController();
    _pathController = TextEditingController(text: '/');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _portController.dispose();
    _uuidController.dispose();
    _sniController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final port = int.tryParse(_portController.text.trim()) ?? 443;
    final address = _addressController.text.trim();
    final name = _nameController.text.trim();
    final uuid = _uuidController.text.trim().isNotEmpty
        ? _uuidController.text.trim()
        : '00000000-0000-0000-0000-000000000000';
    final sni = _sniController.text.trim();
    final path = _pathController.text.trim();

    String generatedUrl = widget.existingProfile?.rawUrl ?? '';

    // Generate link if needed
    if (_protocol == 'vless') {
      generatedUrl =
          'vless://$uuid@$address:$port?type=$_transport&security=$_security&sni=$sni&path=$path#$name';
    } else if (_protocol == 'trojan') {
      generatedUrl =
          'trojan://$uuid@$address:$port?type=$_transport&security=$_security&sni=$sni&path=$path#$name';
    } else if (_protocol == 'socks') {
      generatedUrl = 'socks://$address:$port#$name';
    }

    final result = ServerProfile(
      id: widget.existingProfile?.id,
      name: name,
      protocol: _protocol,
      address: address,
      port: port,
      rawUrl: generatedUrl.isNotEmpty
          ? generatedUrl
          : (widget.existingProfile?.rawUrl ?? 'vless://$uuid@$address:$port#$name'),
      netModPayload: widget.existingProfile?.netModPayload,
    );

    widget.onSave(result);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProfile != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Profile' : 'New Server Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppTheme.primaryCyan),
            onPressed: _submit,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Protocol Selector
            const Text(
              'PROTOCOL',
              style: TextStyle(
                color: AppTheme.disconnectedGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _protocol,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardBackground,
                  items: const [
                    DropdownMenuItem(value: 'vmess', child: Text('VMess')),
                    DropdownMenuItem(value: 'vless', child: Text('VLESS')),
                    DropdownMenuItem(value: 'trojan', child: Text('Trojan')),
                    DropdownMenuItem(value: 'shadowsocks', child: Text('Shadowsocks')),
                    DropdownMenuItem(value: 'socks', child: Text('SOCKS5')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _protocol = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Profile Remark / Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Server Name / Remark',
                prefixIcon: Icon(Icons.label_outline_rounded,
                    color: AppTheme.disconnectedGrey),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a name' : null,
            ),

            const SizedBox(height: 16),

            // Server Address & Port
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Server Address / Host',
                      prefixIcon: Icon(Icons.dns_outlined,
                          color: AppTheme.disconnectedGrey),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter server host'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      prefixIcon: Icon(Icons.numbers_rounded,
                          color: AppTheme.disconnectedGrey),
                    ),
                    validator: (v) =>
                        v == null || int.tryParse(v) == null ? 'Valid port' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // UUID / Password
            TextFormField(
              controller: _uuidController,
              decoration: InputDecoration(
                labelText: _protocol == 'trojan' ? 'Password' : 'User UUID / ID',
                prefixIcon: const Icon(Icons.key_rounded,
                    color: AppTheme.disconnectedGrey),
              ),
            ),

            const SizedBox(height: 20),

            // Transport & Security
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TRANSPORT',
                        style: TextStyle(
                          color: AppTheme.disconnectedGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _transport,
                            isExpanded: true,
                            dropdownColor: AppTheme.cardBackground,
                            items: const [
                              DropdownMenuItem(value: 'ws', child: Text('WebSocket (ws)')),
                              DropdownMenuItem(value: 'tcp', child: Text('TCP')),
                              DropdownMenuItem(value: 'grpc', child: Text('gRPC')),
                              DropdownMenuItem(value: 'h2', child: Text('HTTP/2')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _transport = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SECURITY',
                        style: TextStyle(
                          color: AppTheme.disconnectedGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _security,
                            isExpanded: true,
                            dropdownColor: AppTheme.cardBackground,
                            items: const [
                              DropdownMenuItem(value: 'tls', child: Text('TLS')),
                              DropdownMenuItem(value: 'reality', child: Text('Reality')),
                              DropdownMenuItem(value: 'none', child: Text('None')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _security = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // SNI / Bug Host
            TextFormField(
              controller: _sniController,
              decoration: const InputDecoration(
                labelText: 'SNI / ServerName',
                hintText: 'e.g. cloudflare.com or your host',
                prefixIcon: Icon(Icons.shield_outlined,
                    color: AppTheme.disconnectedGrey),
              ),
            ),

            const SizedBox(height: 16),

            // WebSocket Path
            TextFormField(
              controller: _pathController,
              decoration: const InputDecoration(
                labelText: 'Path',
                hintText: 'e.g. / or /v2ray',
                prefixIcon: Icon(Icons.alt_route_rounded,
                    color: AppTheme.disconnectedGrey),
              ),
            ),

            const SizedBox(height: 32),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _submit,
              child: Text(
                isEditing ? 'Save Profile' : 'Create Profile',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
