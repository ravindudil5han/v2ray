# NetMod V2Ray Client (Windows & Android)

A modern, high-performance V2Ray and Xray VPN client inspired by **NetMod Syna**, built with **Flutter**, **Dart FFI**, and the official **Xray-Core** with native **Wintun** TUN support.

---

## ⚡ Features

### 1. Dual Device Traffic Routing Modes
* **Windows System Proxy Mode (Zero-Elevation)**:
  * Automatically sets Windows Internet Settings (`HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings`).
  * Direct invocation of WinINet's `InternetSetOption` (`INTERNET_OPTION_SETTINGS_CHANGED` and `INTERNET_OPTION_REFRESH`) via `dart:ffi`.
  * Instantly routes browsers (Chrome, Edge, Firefox), command-line tools, and system applications without requiring system reboots or admin privileges.
  * Clean auto-restoration on disconnect or application exit.
* **TUN Mode (Full Device Routing)**:
  * Uses the high-performance **Wintun** virtual network adapter driver (`wintun.dll`).
  * Creates a layer-3 TUN adapter with automatic default route metrics (`0.0.0.0/0`), capturing 100% of device network traffic (TCP, UDP, DNS, gaming, and non-proxy-aware apps).
* **Proxy-Only / Manual Mode**:
  * Starts local SOCKS5 (`127.0.0.1:10808`) and HTTP (`127.0.0.1:10809`) inbounds for manual client configuration or hotspot proxy sharing.

### 2. Multi-Protocol Support
* **VMess**: Supports standard `vmess://` base64 JSON links, WebSocket, TCP, gRPC, TLS, and CDN paths.
* **VLESS**: Supports `vless://` with XTLS, Vision, Reality (`pbk`, `sid`, `spx`), gRPC, and WebSocket.
* **Trojan**: Supports `trojan://` links with TLS and WebSocket.
* **Shadowsocks**: Supports SIP002 `ss://` with modern AEAD ciphers (`aes-256-gcm`, `chacha20-poly1305`).
* **SOCKS5**: Supports `socks://` inbounds and outbounds.

### 3. NetMod Custom Payload & Bug Host Injector
NetMod's signature feature for bypassing strict ISP firewalls and DPI:
* **Custom HTTP Payload**:
  * Supports replacement tags: `[host_port]`, `[host]`, `[port]`, `[protocol]`, `[crlf]`, `[lf]`, `[cr]`, `[ua]`.
  * Pre-configured templates: **CONNECT**, **WebSocket Upgrade**, **Front Inject**, **Back Inject**.
* **Bug Host & SNI Spoofing**:
  * Injects zero-rated ISP domains directly into the TLS SNI and HTTP/WebSocket `Host` header.
  * Live syntax preview shows the exact HTTP headers dispatched to the ISP/CDN edge.

### 4. Real-Time Telemetry & Diagnostics
* **Live Speedometer**: Real-time Download and Upload gauges (KB/s, MB/s) and session transfer totals.
* **Connection Duration Timer**: Displays elapsed uptime.
* **Latency Tester**: Sub-millisecond ping tests directly through the active proxy tunnel.
* **Outbound IP Verification**: Queries public IP, country, and ISP details to visually confirm that network traffic is routed through the proxy.
* **Live Core Log Terminal**: Color-coded streaming terminal capturing real-time stdout/stderr from Xray-core with auto-scroll and keyword filtering.

---

## 🛠️ Architecture

```
lib/
├── main.dart                          # App lifecycle, Windows WinINet auto-cleanup
├── core/
│   ├── engine/
│   │   ├── v2ray_engine.dart          # Engine interface & telemetry models
│   │   ├── windows_v2ray_engine.dart  # Xray process manager & Windows routing
│   │   ├── windows_binary_manager.dart# Xray & Wintun binary resolver
│   │   └── android_v2ray_engine.dart  # Android VpnService channel wrapper
│   ├── proxy/
│   │   └── windows_proxy_helper.dart  # Registry & WinINet InternetSetOption FFI
│   ├── protocol/
│   │   ├── v2ray_url_base.dart        # Xray JSON configuration builder
│   │   ├── vmess_parser.dart          # VMess share link parser
│   │   ├── vless_parser.dart          # VLESS Reality parser
│   │   ├── trojan_parser.dart         # Trojan parser
│   │   ├── shadowsocks_parser.dart    # Shadowsocks SIP002 parser
│   │   ├── socks_parser.dart          # SOCKS5 parser
│   │   └── config_parser.dart         # Master URL & subscription decoder
│   └── payload/
│       └── netmod_payload.dart        # NetMod payload formatter & Bug Host injector
├── models/
│   ├── server_profile.dart            # Server profile definition
│   ├── app_settings.dart              # Settings & port definitions
│   └── v2ray_log.dart                 # Log entry model
├── services/
│   ├── connection_service.dart        # Connection orchestrator & IP checker
│   ├── profile_service.dart           # Persistent profile storage & pinging
│   ├── log_service.dart               # Log buffer & filter
│   └── subscription_service.dart      # HTTP/HTTPS subscription downloader
└── ui/
    ├── theme/
    │   └── app_theme.dart             # NetMod dark cyberpunk / tech theme
    ├── screens/
    │   ├── main_navigation_screen.dart # Responsive navigation shell
    │   ├── dashboard_screen.dart       # Status, glow button, speed cards
    │   ├── profiles_screen.dart        # Server list & clipboard importer
    │   ├── profile_edit_screen.dart    # Profile editor
    │   ├── payload_screen.dart         # NetMod payload generator & tester
    │   ├── logs_screen.dart            # Live log terminal
    │   └── settings_screen.dart        # Routing mode & ports config
    └── widgets/
        ├── connection_button.dart      # Pulsing glowing status button
        ├── speed_meter_card.dart       # Download/upload speed meters
        ├── server_card.dart            # Profile card with latency pill
        └── ip_info_dialog.dart         # Outbound IP verification dialog
```

---

## 🚀 Running and Building

### Prerequisites
* Flutter 3.19+ (Tested on Flutter 3.47.0)
* Dart 3.3+ (Tested on Dart 3.13.0)
* Visual Studio Community 2022 (with Desktop development with C++)
* Windows 10/11 x64

### Running on Windows
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run automated tests
flutter test

# 3. Launch application
flutter run -d windows
```

### Building Windows Release Binary
```bash
flutter build windows --release
```
The compiled standalone executable and bundled assets are generated in `build/windows/x64/runner/Release/`.

### Building for Android
```bash
flutter build apk --release
```
