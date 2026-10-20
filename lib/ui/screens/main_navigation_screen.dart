import 'package:flutter/material.dart';
import '../../services/connection_service.dart';
import '../../services/log_service.dart';
import '../../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'profiles_screen.dart';
import 'payload_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

/// Main responsive navigation shell hosting all 5 core NetMod tabs.
class MainNavigationScreen extends StatefulWidget {
  final ConnectionService connectionService;
  final ProfileService profileService;
  final LogService logService;

  const MainNavigationScreen({
    super.key,
    required this.connectionService,
    required this.profileService,
    required this.logService,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        connectionService: widget.connectionService,
        profileService: widget.profileService,
        onNavigateToProfiles: () => setState(() => _currentIndex = 1),
      ),
      ProfilesScreen(
        profileService: widget.profileService,
        connectionService: widget.connectionService,
      ),
      PayloadScreen(
        connectionService: widget.connectionService,
        profileService: widget.profileService,
      ),
      LogsScreen(
        logService: widget.logService,
      ),
      SettingsScreen(
        connectionService: widget.connectionService,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 720;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: AppTheme.cardBackground,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (val) => setState(() => _currentIndex = val),
                  labelType: NavigationRailLabelType.all,
                  indicatorColor: AppTheme.primaryCyan.withAlpha(40),
                  selectedIconTheme: const IconThemeData(color: AppTheme.primaryCyan),
                  unselectedIconTheme: const IconThemeData(color: AppTheme.disconnectedGrey),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppTheme.primaryCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: AppTheme.disconnectedGrey,
                    fontSize: 12,
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCyan,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryCyan.withAlpha(100),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'NM',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.dns_outlined),
                      selectedIcon: Icon(Icons.dns_rounded),
                      label: Text('Servers'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.terminal_outlined),
                      selectedIcon: Icon(Icons.terminal_rounded),
                      label: Text('Payload'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.article_outlined),
                      selectedIcon: Icon(Icons.article_rounded),
                      label: Text('Logs'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1, color: AppTheme.cardBorder),
                Expanded(child: screens[_currentIndex]),
              ],
            ),
          );
        }

        // Mobile / Compact Bottom Bar layout
        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: NavigationBar(
            backgroundColor: AppTheme.cardBackground,
            indicatorColor: AppTheme.primaryCyan.withAlpha(40),
            selectedIndex: _currentIndex,
            onDestinationSelected: (val) => setState(() => _currentIndex = val),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primaryCyan),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.dns_outlined),
                selectedIcon: Icon(Icons.dns_rounded, color: AppTheme.primaryCyan),
                label: 'Servers',
              ),
              NavigationDestination(
                icon: Icon(Icons.terminal_outlined),
                selectedIcon: Icon(Icons.terminal_rounded, color: AppTheme.primaryCyan),
                label: 'Payload',
              ),
              NavigationDestination(
                icon: Icon(Icons.article_outlined),
                selectedIcon: Icon(Icons.article_rounded, color: AppTheme.primaryCyan),
                label: 'Logs',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded, color: AppTheme.primaryCyan),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
