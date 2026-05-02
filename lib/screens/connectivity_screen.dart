import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/app_models.dart';
import '../services/ble_service.dart';
import '../services/wifi_service.dart';
import '../utils/app_theme.dart';

class ConnectivityScreen extends StatefulWidget {
  const ConnectivityScreen({super.key});

  @override
  State<ConnectivityScreen> createState() => _ConnState();
}

class _ConnState extends State<ConnectivityScreen> {
  @override
  void initState() {
    super.initState();
    final conn = context.read<ConnModel>();
    context.read<BleService>().attach(conn);
    context.read<WifiService>().attach(conn);
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnModel>();

    return Scaffold(
      backgroundColor: T.bg0,
      body: Column(children: [
        // Header
        VHeader(
          title: 'CONNECTIVITY',
          sub: 'V-LINK DEVICE MANAGER',
          trailing: conn.isConnected
              ? VPill(label: 'CONNECTED', color: T.teal)
              : VPill(label: 'NO LINK', color: T.greyDim),
        ),

        // Transport toggle
        _TransportToggle(
          mode: conn.mode,
          onChange: conn.setMode,
        ),

        // Panel
        Expanded(child: conn.mode == Transport.ble
            ? const _BlePanel()
            : const _WifiPanel()),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TRANSPORT TOGGLE
// ══════════════════════════════════════════════════════════════════════════════
class _TransportToggle extends StatelessWidget {
  final Transport  mode;
  final ValueChanged<Transport> onChange;
  const _TransportToggle({required this.mode, required this.onChange});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    decoration: T.panel(),
    child: Row(children: [
      _TChip('BLUETOOTH', Icons.bluetooth,
          mode == Transport.ble,  () => onChange(Transport.ble)),
      _TChip('WI-FI UDP',  Icons.wifi,
          mode == Transport.wifi, () => onChange(Transport.wifi)),
    ]),
  );
}

class _TChip extends StatelessWidget {
  final String label; final IconData icon;
  final bool sel; final VoidCallback onTap;
  const _TChip(this.label, this.icon, this.sel, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: sel ? T.red.withOpacity(0.12) : Colors.transparent,
        border: Border(
          top: BorderSide(color: sel ? T.red : Colors.transparent, width: 2),
        ),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 15, color: sel ? T.red : T.greyDim),
        const SizedBox(width: 7),
        Text(label, style: T.raj(13, color: sel ? T.red : T.greyDim)),
      ]),
    ),
  ));
}

// ══════════════════════════════════════════════════════════════════════════════
// BLE PANEL
// ══════════════════════════════════════════════════════════════════════════════
class _BlePanel extends StatelessWidget {
  const _BlePanel();

  @override
  Widget build(BuildContext context) {
    final ble  = context.watch<BleService>();
    final conn = context.watch<ConnModel>();

    return Column(children: [
      // Scan button row
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AVAILABLE DEVICES', style: T.raj(15)),
              Text(
                ble.scanning
                    ? 'Started scanning…'
                    : conn.isConnected
                        ? 'Connected to ${conn.deviceName}'
                        : 'Press SCAN to discover nearby devices',
                style: T.mono(9, color: ble.scanning ? T.teal : T.greyDim),
              ),
            ],
          )),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: ble.scanning
                ? () => context.read<BleService>().stopScan()
                : () => context.read<BleService>().startScan(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: ble.scanning ? T.bg3 : T.red,
                border: Border.all(color: ble.scanning ? T.border : T.red),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(ble.scanning ? Icons.stop : Icons.radar,
                    color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text(ble.scanning ? 'STOP' : 'SCAN',
                    style: T.raj(13, color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ),

      // Scanning animation
      if (ble.scanning)
        LinearProgressIndicator(
          backgroundColor: T.border,
          valueColor: const AlwaysStoppedAnimation(T.teal),
          minHeight: 2,
        ),

      // Device list
      Expanded(child: ble.discovered.isEmpty && !conn.isConnected
          ? _EmptyState(scanning: ble.scanning)
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Connected device (always shown if connected)
                if (conn.isConnected)
                  _DeviceTile(
                    name:     conn.deviceName ?? 'V-LINK DEVICE',
                    sub:      'Connected',
                    subColor: T.teal,
                    rssi:     null,
                    isConnected: true,
                    onTap:    () => context.read<BleService>().disconnect(),
                    actionLabel: 'DISCONNECT',
                    actionColor: T.greyDim,
                  ),

                // Discovered devices — ALL of them, no filtering
                ...ble.discovered.map((r) {
                  final name = r.device.platformName.isNotEmpty
                      ? r.device.platformName
                      : r.device.remoteId.str;
                  final alreadyConn = conn.isConnected &&
                      conn.deviceName == r.device.platformName;
                  if (alreadyConn) return const SizedBox.shrink();
                  return _DeviceTile(
                    name:        name,
                    sub:         _deviceType(r.device.platformName),
                    subColor:    T.greyDim,
                    rssi:        r.rssi,
                    isConnected: false,
                    actionLabel: 'PAIR',
                    actionColor: T.red,
                    onTap: () =>
                        context.read<BleService>().connect(r.device),
                  );
                }),
              ],
            )),
    ]);
  }

  String _deviceType(String name) {
    final n = name.toLowerCase();
    if (n.contains('esp'))     return 'ESP32 Controller';
    if (n.contains('iphone') || n.contains('ipad')) return 'Apple Device';
    if (n.contains('android') || n.contains('pixel') ||
        n.contains('samsung') || n.contains('xiaomi')) return 'Android Device';
    if (n.contains('mac') || n.contains('windows') ||
        n.contains('linux')) return 'Computer';
    return 'Bluetooth Device';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WI-FI PANEL  —  UDP broadcast discovery
// ══════════════════════════════════════════════════════════════════════════════
class _WifiPanel extends StatelessWidget {
  const _WifiPanel();

  @override
  Widget build(BuildContext context) {
    final wifi = context.watch<WifiService>();
    final conn = context.watch<ConnModel>();

    return Column(children: [
      // Scan row
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LOCAL NETWORK DEVICES', style: T.raj(15)),
              Text(
                wifi.discovering
                    ? 'Started scanning…'
                    : conn.isConnected
                        ? 'Connected to ${conn.deviceName}'
                        : 'Press SCAN to find UDP devices',
                style: T.mono(9,
                    color: wifi.discovering ? T.teal : T.greyDim),
              ),
            ],
          )),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: wifi.discovering
                ? () => context.read<WifiService>().stopDiscovery()
                : () => context.read<WifiService>().startDiscovery(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: wifi.discovering ? T.bg3 : T.red,
                border:
                    Border.all(color: wifi.discovering ? T.border : T.red),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(wifi.discovering ? Icons.stop : Icons.wifi_find,
                    color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text(wifi.discovering ? 'STOP' : 'SCAN',
                    style: T.raj(13, color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ),

      if (wifi.discovering)
        LinearProgressIndicator(
          backgroundColor: T.border,
          valueColor: const AlwaysStoppedAnimation(T.teal),
          minHeight: 2,
        ),

      // Manual IP fallback
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          const Icon(Icons.edit_outlined, color: T.greyDim, size: 14),
          const SizedBox(width: 6),
          Text('Or enter IP manually:', style: T.mono(9, color: T.greyDim)),
          const SizedBox(width: 10),
          Expanded(child: _IpField(
            initial: wifi.ip,
            onChanged: (v) => context.read<WifiService>().setIp(v),
          )),
        ]),
      ),

      // Device list
      Expanded(child: wifi.discoveredHosts.isEmpty && !conn.isConnected
          ? _EmptyState(scanning: wifi.discovering)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                if (conn.isConnected && conn.mode == Transport.wifi)
                  _DeviceTile(
                    name:        conn.deviceName ?? wifi.ip,
                    sub:         'Connected via UDP :4242',
                    subColor:    T.teal,
                    rssi:        null,
                    isConnected: true,
                    actionLabel: 'DISCONNECT',
                    actionColor: T.greyDim,
                    onTap: () => context.read<WifiService>().disconnect(),
                  ),
                ...wifi.discoveredHosts.map((host) {
                  final alreadyConn =
                      conn.isConnected && conn.deviceName == host;
                  if (alreadyConn) return const SizedBox.shrink();
                  return _DeviceTile(
                    name:        host,
                    sub:         'UDP :4242',
                    subColor:    T.greyDim,
                    rssi:        null,
                    isConnected: false,
                    actionLabel: 'CONNECT',
                    actionColor: T.red,
                    onTap: () {
                      context.read<WifiService>().setIp(host);
                      context.read<WifiService>().connect();
                    },
                  );
                }),
              ],
            )),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════════════
class _DeviceTile extends StatelessWidget {
  final String     name, sub, actionLabel;
  final Color      subColor, actionColor;
  final int?       rssi;
  final bool       isConnected;
  final VoidCallback onTap;

  const _DeviceTile({
    required this.name, required this.sub,
    required this.subColor, required this.actionColor,
    required this.isConnected, required this.actionLabel,
    required this.onTap, this.rssi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: T.panel(active: isConnected),
      child: Row(children: [
        // Device icon
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isConnected ? T.red.withOpacity(0.15) : T.bg3,
            border: Border.all(color: isConnected ? T.red : T.border),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isConnected ? Icons.link : Icons.bluetooth,
            color: isConnected ? T.red : T.greyDim,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),

        // Name + sub
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.length > 20 ? '${name.substring(0, 20)}…' : name,
              style: T.raj(14),
            ),
            Row(children: [
              if (isConnected)
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: T.teal),
                ),
              Text(sub, style: T.mono(9, color: subColor)),
              if (rssi != null) ...[
                const SizedBox(width: 8),
                Icon(_rssiIcon(rssi!), color: T.greyDim, size: 12),
                const SizedBox(width: 2),
                Text('${rssi} dBm',
                    style: T.mono(8, color: T.greyDim)),
              ],
            ]),
          ],
        )),

        // Action button
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isConnected ? T.bg3 : actionColor,
              border: Border.all(
                  color: isConnected ? T.border : actionColor),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                isConnected ? Icons.link_off : Icons.login,
                color: Colors.white, size: 13,
              ),
              const SizedBox(width: 5),
              Text(actionLabel,
                  style: T.mono(9, color: Colors.white)),
            ]),
          ),
        ),
      ]),
    );
  }

  IconData _rssiIcon(int rssi) {
    if (rssi > -60) return Icons.signal_wifi_4_bar;
    if (rssi > -75) return Icons.network_wifi_3_bar;
    if (rssi > -85) return Icons.network_wifi_2_bar;
    return Icons.network_wifi_1_bar;
  }
}

class _EmptyState extends StatelessWidget {
  final bool scanning;
  const _EmptyState({required this.scanning});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.bluetooth_searching,
          color: T.greyDim, size: 52),
      const SizedBox(height: 16),
      Text(
        scanning ? 'Scanning for devices…' : 'No devices found',
        style: T.raj(16, color: T.grey),
      ),
      const SizedBox(height: 6),
      Text(
        scanning
            ? 'Keep this screen open'
            : 'Press SCAN to search',
        style: T.mono(10, color: T.greyDim),
      ),
    ]),
  );
}

class _IpField extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onChanged;
  const _IpField({required this.initial, required this.onChanged});

  @override
  State<_IpField> createState() => _IpFieldState();
}

class _IpFieldState extends State<_IpField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    decoration: BoxDecoration(
        color: T.bg2, border: Border.all(color: T.border)),
    child: TextField(
      controller: _ctrl,
      style: T.mono(11, color: T.white),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: InputBorder.none,
        hintText: '192.168.4.1',
        hintStyle: TextStyle(
            fontFamily: 'ShareTechMono', fontSize: 11,
            color: Color(0xFF3D5166)),
      ),
      onChanged: widget.onChanged,
    ),
  );
}
