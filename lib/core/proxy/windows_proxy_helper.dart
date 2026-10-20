import 'dart:ffi';
import 'dart:io';

typedef _InternetSetOptionNative = Int32 Function(
  IntPtr hInternet,
  Uint32 dwOption,
  Pointer<Void> lpBuffer,
  Uint32 dwBufferLength,
);
typedef _InternetSetOptionDart = int Function(
  int hInternet,
  int dwOption,
  Pointer<Void> lpBuffer,
  int dwBufferLength,
);

/// Helper for configuring and refreshing Windows System Proxy settings.
class WindowsProxyHelper {
  static const int _internetOptionSettingsChanged = 39;
  static const int _internetOptionRefresh = 37;

  static const String _defaultOverride =
      '<local>;localhost;127.*;10.*;172.16.*;172.17.*;172.18.*;172.19.*;'
      '172.20.*;172.21.*;172.22.*;172.23.*;172.24.*;172.25.*;172.26.*;'
      '172.27.*;172.28.*;172.29.*;172.30.*;172.31.*;192.168.*';

  static _InternetSetOptionDart? _internetSetOption;
  static bool _wininetInitialized = false;

  static void _initWinInet() {
    if (_wininetInitialized) return;
    try {
      if (Platform.isWindows) {
        final wininet = DynamicLibrary.open('wininet.dll');
        _internetSetOption = wininet.lookupFunction<
          _InternetSetOptionNative,
          _InternetSetOptionDart
        >('InternetSetOptionW');
      }
    } catch (e) {
      // Fallback: wininet may already be loaded or unavailable
    }
    _wininetInitialized = true;
  }

  /// Refreshes WinINet settings so running applications (browsers, services)
  /// immediately pick up the new proxy configuration without restarting.
  static void refreshWinInet() {
    if (!Platform.isWindows) return;
    _initWinInet();
    try {
      if (_internetSetOption != null) {
        _internetSetOption!(0, _internetOptionSettingsChanged, nullptr, 0);
        _internetSetOption!(0, _internetOptionRefresh, nullptr, 0);
      }
    } catch (_) {}
  }

  /// Sets the Windows system proxy to [host]:[port].
  static Future<bool> enableProxy({
    required String host,
    required int port,
    String? overrideList,
  }) async {
    if (!Platform.isWindows) return false;
    try {
      final proxyServer = '$host:$port';
      final override = overrideList ?? _defaultOverride;

      // Update registry for Current User
      await Process.run('reg', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f',
      ]);

      await Process.run('reg', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'ProxyServer',
        '/t',
        'REG_SZ',
        '/d',
        proxyServer,
        '/f',
      ]);

      await Process.run('reg', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'ProxyOverride',
        '/t',
        'REG_SZ',
        '/d',
        override,
        '/f',
      ]);

      // Notify WinINet
      refreshWinInet();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Disables the Windows system proxy.
  static Future<bool> disableProxy() async {
    if (!Platform.isWindows) return false;
    try {
      await Process.run('reg', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f',
      ]);

      // Notify WinINet
      refreshWinInet();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks if Windows system proxy is currently enabled.
  static Future<bool> isProxyEnabled() async {
    if (!Platform.isWindows) return false;
    try {
      final res = await Process.run('reg', [
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'ProxyEnable',
      ]);
      if (res.exitCode == 0 && res.stdout.toString().contains('0x1')) {
        return true;
      }
    } catch (_) {}
    return false;
  }
}
