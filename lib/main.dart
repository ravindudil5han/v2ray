import 'dart:io';
import 'package:flutter/material.dart';
import 'core/proxy/windows_proxy_helper.dart';
import 'services/connection_service.dart';
import 'services/log_service.dart';
import 'services/profile_service.dart';
import 'ui/screens/main_navigation_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create core services
  final logService = LogService();
  final profileService = ProfileService();
  final connectionService = ConnectionService(logService);

  // Load profiles and initialize engine
  await profileService.loadProfiles();
  await connectionService.initialize(profileService.profiles);

  runApp(NetModApp(
    logService: logService,
    profileService: profileService,
    connectionService: connectionService,
  ));
}

/// Root Application Widget.
class NetModApp extends StatefulWidget {
  final LogService logService;
  final ProfileService profileService;
  final ConnectionService connectionService;

  const NetModApp({
    super.key,
    required this.logService,
    required this.profileService,
    required this.connectionService,
  });

  @override
  State<NetModApp> createState() => _NetModAppState();
}

class _NetModAppState extends State<NetModApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Cleanup proxy on exit
    if (Platform.isWindows) {
      WindowsProxyHelper.disableProxy();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      if (Platform.isWindows) {
        WindowsProxyHelper.disableProxy();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetMod V2Ray',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MainNavigationScreen(
        connectionService: widget.connectionService,
        profileService: widget.profileService,
        logService: widget.logService,
      ),
    );
  }
}
