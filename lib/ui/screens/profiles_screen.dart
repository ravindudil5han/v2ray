import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/server_profile.dart';
import '../../services/connection_service.dart';
import '../../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/server_card.dart';
import 'profile_edit_screen.dart';

/// Server profile management screen.
class ProfilesScreen extends StatefulWidget {
  final ProfileService profileService;
  final ConnectionService connectionService;

  const ProfilesScreen({
    super.key,
    required this.profileService,
    required this.connectionService,
  });

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _importFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')),
        );
      }
      return;
    }

    final count = await widget.profileService.importFromText(text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Successfully imported $count server(s)!'
                : 'Could not parse any valid V2Ray/Xray URLs.',
          ),
          backgroundColor: count > 0 ? AppTheme.connectedGreen : AppTheme.errorRed,
        ),
      );
    }
  }

  void _showImportDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: const Text('Import Server / Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a vmess://, vless://, trojan://, ss:// link or subscription URL:',
              style: TextStyle(color: AppTheme.disconnectedGrey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'vmess://... or http://subscription...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.disconnectedGrey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final raw = textController.text.trim();
              if (raw.isNotEmpty) {
                Navigator.of(ctx).pop();
                final count = await widget.profileService.importFromText(raw);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        count > 0
                            ? 'Imported $count server(s)!'
                            : 'Failed to parse configuration.',
                      ),
                      backgroundColor:
                          count > 0 ? AppTheme.connectedGreen : AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(
          onSave: (newProfile) => widget.profileService.addProfile(newProfile),
        ),
      ),
    );
  }

  void _navigateToEdit(ServerProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(
          existingProfile: profile,
          onSave: (updated) => widget.profileService.updateProfile(updated),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.profileService,
      builder: (context, _) {
        final allProfiles = widget.profileService.profiles;
        final filteredProfiles = _searchQuery.isEmpty
            ? allProfiles
            : allProfiles.where((p) {
                return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    p.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    p.protocol.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Servers & Profiles'),
            actions: [
              IconButton(
                tooltip: 'Ping All Servers',
                icon: const Icon(Icons.bolt_rounded, color: AppTheme.warningAmber),
                onPressed: () => widget.profileService.testAllPings(),
              ),
              IconButton(
                tooltip: 'Import from Clipboard',
                icon: const Icon(Icons.paste_rounded, color: AppTheme.primaryCyan),
                onPressed: _importFromClipboard,
              ),
              IconButton(
                tooltip: 'Add / Import Server',
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                onPressed: _showImportDialog,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryCyan,
            foregroundColor: Colors.black87,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Server', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _navigateToCreate,
          ),
          body: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search servers by name, IP, protocol...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.disconnectedGrey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // Server List
              Expanded(
                child: filteredProfiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.dns_rounded,
                                size: 56, color: AppTheme.disconnectedGrey),
                            const SizedBox(height: 16),
                            const Text(
                              'No servers found',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Import a V2Ray link or tap New Server below.',
                              style: TextStyle(
                                  color: AppTheme.disconnectedGrey, fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.primaryCyan),
                              ),
                              onPressed: _importFromClipboard,
                              icon: const Icon(Icons.paste_rounded,
                                  color: AppTheme.primaryCyan),
                              label: const Text('Paste from Clipboard',
                                  style: TextStyle(color: AppTheme.primaryCyan)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        itemCount: filteredProfiles.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final profile = filteredProfiles[index];
                          final isSelected =
                              widget.connectionService.activeProfile?.id ==
                                  profile.id;

                          return ServerCard(
                            profile: profile,
                            isSelected: isSelected,
                            onSelect: () {
                              widget.connectionService.setActiveProfile(profile);
                            },
                            onEdit: () => _navigateToEdit(profile),
                            onDelete: () {
                              widget.profileService.deleteProfile(profile.id);
                            },
                            onPing: () {
                              widget.profileService.testProfilePing(profile);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
