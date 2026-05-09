import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../services/ble_service.dart';
import '../services/wifi_service.dart';
import '../services/hid_service.dart';
import '../services/webrtc_service.dart';
import '../utils/app_theme.dart';
import 'qr_scan_screen.dart';

// ── Which sub-panel is open ───────────────────────────────────────────────────
enum _HidMode   { none, bluetooth, wifi, usb }
enum _MirrorMode{ none, webrtc, cast }

class ConnectivityScreen extends StatefulWidget {
  const ConnectivityScreen({super.key});
  @override State<ConnectivityScreen> createState() => _ConnState();
}

class _ConnState extends State<ConnectivityScreen> {
  _HidMode    _hidMode    = _HidMode.none;
  _MirrorMode _mirrorMode = _MirrorMode.none;

  @override
  void initState() {
    super.initState();
    final conn = context.read<ConnModel>();
    context.read<BleService>().attach(conn);
    context.read<WifiService>().attach(conn);
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    final conn = context.watch<ConnModel>();
    final ble  = context.watch<BleService>();

    return Scaffold(
      backgroundColor: T.bg0,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: VHeader(
          title: 'V-LINK',
          sub: 'CONNECTIVITY',
          trailing: conn.isConnected
              ? VPill(label: 'BLE ACTIVE', color: T.teal) : null,
        )),

        // Transport toggle
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _ModeToggle(mode: conn.mode, onChange: conn.setMode),
        )),

        // BLE panel
        if (conn.mode == Transport.ble)
          SliverToBoxAdapter(child: _BlePanel(conn: conn, ble: ble)),

        // WiFi panel
        if (conn.mode == Transport.wifi)
          SliverToBoxAdapter(child: _WifiPanel()),

        // Data stream
        SliverToBoxAdapter(child: _DataStream(logs: conn.logs)),
=======
    return Scaffold(
      backgroundColor: T.bg0,
      body: CustomScrollView(slivers: [

        // Header
        SliverToBoxAdapter(child: VHeader(
          title: 'CONNECTIVITY',
          sub: 'V-LINK DEVICE MANAGER',
        )),

        // ── SECTION 1: HID ────────────────────────────────────────────────
        SliverToBoxAdapter(child: _SectionLabel(
          icon: Icons.gamepad_outlined,
          title: 'HID',
          subtitle: 'Send keyboard & mouse inputs to your PC',
        )),

        // Three HID option cards
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            _BigOptionCard(
              icon: Icons.bluetooth,
              iconColor: const Color(0xFF2196F3),
              title: 'Bluetooth',
              subtitle: 'Pair phone as BT keyboard + mouse',
              selected: _hidMode == _HidMode.bluetooth,
              onTap: () => setState(() =>
                _hidMode = _hidMode == _HidMode.bluetooth
                    ? _HidMode.none : _HidMode.bluetooth),
            ),
            if (_hidMode == _HidMode.bluetooth)
              _BluetoothHidPanel(),
            const SizedBox(height: 8),

            _BigOptionCard(
              icon: Icons.wifi,
              iconColor: const Color(0xFF4CAF50),
              title: 'Wi-Fi UDP',
              subtitle: 'Send inputs over local network',
              selected: _hidMode == _HidMode.wifi,
              onTap: () => setState(() =>
                _hidMode = _hidMode == _HidMode.wifi
                    ? _HidMode.none : _HidMode.wifi),
            ),
            if (_hidMode == _HidMode.wifi)
              _WifiHidPanel(),
            const SizedBox(height: 8),

            _BigOptionCard(
              icon: Icons.usb,
              iconColor: const Color(0xFFFF9800),
              title: 'USB HID',
              subtitle: 'Connect via USB cable as HID device',
              selected: _hidMode == _HidMode.usb,
              onTap: () => setState(() =>
                _hidMode = _hidMode == _HidMode.usb
                    ? _HidMode.none : _HidMode.usb),
            ),
            if (_hidMode == _HidMode.usb)
              _UsbHidPanel(),
          ]),
        )),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── SECTION 2: Screen Mirroring ───────────────────────────────────
        SliverToBoxAdapter(child: _SectionLabel(
          icon: Icons.cast_outlined,
          title: 'SCREEN MIRRORING',
          subtitle: 'See your PC screen on this device',
        )),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            _BigOptionCard(
              icon: Icons.wifi_tethering,
              iconColor: const Color(0xFF9C27B0),
              title: 'WebRTC',
              subtitle: 'Stream PC screen + HID via WebRTC',
              selected: _mirrorMode == _MirrorMode.webrtc,
              badge: 'HANDLES HID',
              badgeColor: T.teal,
              onTap: () => setState(() =>
                _mirrorMode = _mirrorMode == _MirrorMode.webrtc
                    ? _MirrorMode.none : _MirrorMode.webrtc),
            ),
            if (_mirrorMode == _MirrorMode.webrtc)
              _WebRtcPanel(),
            const SizedBox(height: 8),

            _BigOptionCard(
              icon: Icons.cast,
              iconColor: const Color(0xFF00BCD4),
              title: 'Receive Cast',
              subtitle: 'Mirror PC screen — HID via separate channel',
              selected: _mirrorMode == _MirrorMode.cast,
              onTap: () => setState(() =>
                _mirrorMode = _mirrorMode == _MirrorMode.cast
                    ? _MirrorMode.none : _MirrorMode.cast),
            ),
            if (_mirrorMode == _MirrorMode.cast)
              _CastPanel(),
          ]),
        )),
>>>>>>> Stashed changes

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ]),
    );
  }
}

<<<<<<< Updated upstream
// ── Mode toggle ───────────────────────────────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  final Transport mode;
  final ValueChanged<Transport> onChange;
  const _ModeToggle({required this.mode, required this.onChange});

  @override
  Widget build(BuildContext context) => Container(
    decoration: T.panel(),
    child: Row(children: [
      _Chip('BLUETOOTH', Icons.bluetooth, mode == Transport.ble,  () => onChange(Transport.ble)),
      _Chip('WI-FI UDP',  Icons.wifi,     mode == Transport.wifi, () => onChange(Transport.wifi)),
=======
// ══════════════════════════════════════════════════════════════════════════════
// SECTION LABEL
// ══════════════════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _SectionLabel({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: T.red.withOpacity(0.12),
          border: Border.all(color: T.red.withOpacity(0.4)),
        ),
        child: Icon(icon, color: T.red, size: 18),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,    style: T.orb(15, color: T.white)),
        Text(subtitle, style: T.mono(9, color: T.grey)),
      ]),
>>>>>>> Stashed changes
    ]),
  );
}

<<<<<<< Updated upstream
class _Chip extends StatelessWidget {
  final String label; final IconData icon;
  final bool sel; final VoidCallback onTap;
  const _Chip(this.label, this.icon, this.sel, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: sel ? T.red.withOpacity(0.12) : Colors.transparent,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 15, color: sel ? T.red : T.greyDim),
        const SizedBox(width: 7),
        Text(label, style: T.raj(13, color: sel ? T.red : T.greyDim)),
      ]),
    ),
  ));
}

// ── BLE panel ─────────────────────────────────────────────────────────────────
class _BlePanel extends StatelessWidget {
  final ConnModel conn; final BleService ble;
  const _BlePanel({required this.conn, required this.ble});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SCANNING FOR NODES', style: T.raj(15)),
            Text('Searching for ESP32 HID Clients…', style: T.mono(9, color: T.greyDim)),
          ])),
          GestureDetector(
            onTap: () => context.read<BleService>().startScan(),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: T.bg2, border: Border.all(color: T.border),
                  shape: BoxShape.circle),
              child: const Icon(Icons.radar, color: T.grey, size: 18),
            ),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('AVAILABLE DEVICES', style: T.mono(8, color: T.greyDim)),
      ),
      const SizedBox(height: 8),
      if (conn.isConnected)
        _DevTile(
          name: conn.deviceName ?? 'V-LINK_DEVICE',
          sub: '● CONNECTED', subColor: T.teal,
          actionLabel: 'DISCONNECT',
          onAction: () => context.read<BleService>().disconnect(),
        ),
      ...ble.discovered
          .where((r) => r.device.platformName.isNotEmpty)
          .map((r) => _DevTile(
        name: r.device.platformName,
        sub: 'ESP32 HID', subColor: T.greyDim,
        actionLabel: 'PAIR',
        onAction: () => context.read<BleService>().connect(r.device),
      )),
      if (!conn.isConnected && ble.discovered.isEmpty)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('No devices found. Tap the radar to scan.',
              style: T.mono(9, color: T.greyDim)),
        ),
    ],
  );
}

class _DevTile extends StatelessWidget {
  final String name, sub, actionLabel;
  final Color subColor;
  final VoidCallback onAction;
  const _DevTile({required this.name, required this.sub, required this.subColor,
    required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: T.panel(active: actionLabel == 'DISCONNECT'),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: actionLabel == 'DISCONNECT' ? T.red.withOpacity(0.15) : T.bg3,
            border: Border.all(color: T.border)),
        child: Icon(Icons.settings_input_antenna,
            color: actionLabel == 'DISCONNECT' ? T.red : T.greyDim, size: 17),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name.length > 14 ? '${name.substring(0,14)}…' : name, style: T.raj(14)),
        Text(sub, style: T.mono(9, color: subColor)),
      ])),
      GestureDetector(
        onTap: onAction,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: actionLabel == 'DISCONNECT' ? T.bg3 : T.red,
            border: Border.all(color: actionLabel == 'DISCONNECT' ? T.border : T.red),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(actionLabel == 'DISCONNECT' ? Icons.logout : Icons.login,
                color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(actionLabel, style: T.mono(9, color: Colors.white)),
          ]),
        ),
      ),
    ]),
  );
}

// ── WiFi panel ────────────────────────────────────────────────────────────────
class _WifiPanel extends StatefulWidget {
  @override State<_WifiPanel> createState() => _WifiPanelState();
}

class _WifiPanelState extends State<_WifiPanel> {
  late TextEditingController _ctrl;
=======
// ══════════════════════════════════════════════════════════════════════════════
// BIG OPTION CARD
// ══════════════════════════════════════════════════════════════════════════════
class _BigOptionCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title, subtitle;
  final bool     selected;
  final String?  badge;
  final Color?   badgeColor;
  final VoidCallback onTap;

  const _BigOptionCard({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.selected, required this.onTap,
    this.badge, this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? iconColor.withOpacity(0.10) : T.bg1,
          border: Border.all(
            color: selected ? iconColor : T.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          // Big logo icon
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withOpacity(selected ? 0.8 : 0.4),
                width: selected ? 2 : 1.2,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(title, style: T.raj(16, color: selected ? T.white : T.white)),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: (badgeColor ?? T.teal).withOpacity(0.20),
                    child: Text(badge!, style: T.mono(8, color: badgeColor ?? T.teal)),
                  ),
                ],
              ]),
              const SizedBox(height: 3),
              Text(subtitle, style: T.mono(9, color: T.grey)),
            ],
          )),
          // Arrow indicator
          Icon(
            selected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: selected ? iconColor : T.greyDim,
            size: 20,
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BLUETOOTH HID PANEL
// ══════════════════════════════════════════════════════════════════════════════
class _BluetoothHidPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ble  = context.watch<BleService>();
    final conn = context.watch<ConnModel>();
    final hid  = context.watch<HidService>();

    return _SubPanel(children: [
      // Phone-as-HID toggle
      _InfoRow(
        label: 'PHONE AS BT HID DEVICE',
        sub: hid.btHidStatus,
        statusColor: hid.btHidActive ? T.teal : T.greyDim,
        action: hid.btHidActive
            ? _ActionBtn('STOP',       T.grey,  () => context.read<HidService>().stopBluetoothHid())
            : _ActionBtn('ADVERTISE',  T.red,   () => context.read<HidService>().startBluetoothHid()),
      ),

      const Divider(color: T.border, height: 20),
      Text('OR CONNECT TO ESP32 VIA BLE', style: T.mono(8, color: T.greyDim).copyWith(letterSpacing: 2)),
      const SizedBox(height: 10),

      // BLE scan row
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AVAILABLE DEVICES', style: T.raj(14)),
          Text(ble.scanning ? 'Started scanning…' : 'Press SCAN to search',
              style: T.mono(9, color: ble.scanning ? T.teal : T.greyDim)),
        ])),
        GestureDetector(
          onTap: ble.scanning
              ? () => context.read<BleService>().stopScan()
              : () => context.read<BleService>().startScan(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: ble.scanning ? T.bg3 : T.red,
            child: Text(ble.scanning ? 'STOP' : 'SCAN', style: T.raj(13)),
          ),
        ),
      ]),
      if (ble.scanning)
        const Padding(padding: EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(backgroundColor: T.border,
                valueColor: AlwaysStoppedAnimation(T.teal), minHeight: 2)),
      const SizedBox(height: 8),

      if (conn.isConnected)
        _DeviceTile(
          name: conn.deviceName ?? 'DEVICE', sub: '● CONNECTED', subColor: T.teal,
          actionLabel: 'DISCONNECT', isConnected: true,
          onTap: () => context.read<BleService>().disconnect(),
        ),
      ...ble.discovered.map((r) {
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName : r.device.remoteId.str;
        return _DeviceTile(
          name: name, sub: 'BLE Device', subColor: T.greyDim,
          actionLabel: 'PAIR', isConnected: false, rssi: r.rssi,
          onTap: () => context.read<BleService>().connect(r.device),
        );
      }),
      if (ble.discovered.isEmpty && !conn.isConnected)
        Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('No devices found. Press SCAN.',
              style: T.mono(9, color: T.greyDim)),
        )),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIFI HID PANEL
// ══════════════════════════════════════════════════════════════════════════════
class _WifiHidPanel extends StatefulWidget {
  @override State<_WifiHidPanel> createState() => _WifiHidPanelState();
}

class _WifiHidPanelState extends State<_WifiHidPanel> {
  late TextEditingController _ipCtrl;

  @override
  void initState() {
    super.initState();
    _ipCtrl = TextEditingController(text: context.read<WifiService>().ip);
  }
  @override void dispose() { _ipCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final wifi = context.watch<WifiService>();
    final conn = context.watch<ConnModel>();

    return _SubPanel(children: [
      // Scan row
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('LOCAL NETWORK DEVICES', style: T.raj(14)),
          Text(wifi.discovering ? 'Started scanning…' : 'Scanning for UDP devices',
              style: T.mono(9, color: wifi.discovering ? T.teal : T.greyDim)),
        ])),
        GestureDetector(
          onTap: wifi.discovering
              ? () => context.read<WifiService>().stopDiscovery()
              : () => context.read<WifiService>().startDiscovery(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: wifi.discovering ? T.bg3 : T.red,
            child: Text(wifi.discovering ? 'STOP' : 'SCAN', style: T.raj(13)),
          ),
        ),
      ]),
      if (wifi.discovering)
        const Padding(padding: EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(backgroundColor: T.border,
                valueColor: AlwaysStoppedAnimation(T.teal), minHeight: 2)),
      const SizedBox(height: 8),

      // Discovered devices
      if (conn.isConnected && conn.mode == Transport.wifi)
        _DeviceTile(
          name: conn.deviceName ?? wifi.ip, sub: 'UDP :4242', subColor: T.teal,
          actionLabel: 'DISCONNECT', isConnected: true,
          onTap: () => context.read<WifiService>().disconnect(),
        ),
      ...wifi.discoveredHosts.map((h) => _DeviceTile(
        name: h, sub: 'UDP :4242', subColor: T.greyDim,
        actionLabel: 'CONNECT', isConnected: false,
        onTap: () { context.read<WifiService>().setIp(h); context.read<WifiService>().connect(); },
      )),
      if (wifi.discoveredHosts.isEmpty && !(conn.isConnected && conn.mode == Transport.wifi))
        Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('No devices found. Press SCAN.', style: T.mono(9, color: T.greyDim)),
        )),

      const Divider(color: T.border, height: 20),
      Text('MANUAL IP', style: T.mono(8, color: T.greyDim).copyWith(letterSpacing: 2)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: Container(
          height: 36,
          decoration: BoxDecoration(color: T.bg2, border: Border.all(color: T.border)),
          child: TextField(
            controller: _ipCtrl,
            style: T.mono(12, color: T.white),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: InputBorder.none,
              hintText: '192.168.1.100',
              hintStyle: TextStyle(fontFamily:'ShareTechMono', fontSize:11, color:Color(0xFF3D5166)),
            ),
            onChanged: (v) => context.read<WifiService>().setIp(v),
          ),
        )),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: wifi.connected
              ? () => context.read<WifiService>().disconnect()
              : () => context.read<WifiService>().connect(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: wifi.connected ? T.bg3 : T.red,
            child: Text(wifi.connected ? 'DISCONNECT' : 'CONNECT', style: T.raj(13)),
          ),
        ),
      ]),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// USB HID PANEL
// ══════════════════════════════════════════════════════════════════════════════
class _UsbHidPanel extends StatefulWidget {
  @override State<_UsbHidPanel> createState() => _UsbHidPanelState();
}

class _UsbHidPanelState extends State<_UsbHidPanel> {
  bool _checking = false;
  bool _usbDetected = false;

  @override
  Widget build(BuildContext context) {
    final hid = context.watch<HidService>();

    return _SubPanel(children: [
      // Phone-to-laptop icon
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.phone_android, color: T.grey, size: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(children: [
            Container(width: 40, height: 3, color: T.border),
            const SizedBox(height: 3),
            Text('USB', style: T.mono(8, color: T.greyDim)),
            const SizedBox(height: 3),
            Container(width: 40, height: 3, color: T.border),
          ]),
        ),
        const Icon(Icons.laptop, color: T.grey, size: 32),
      ]),
      const SizedBox(height: 14),

      _InfoRow(
        label: 'USB HID STATUS',
        sub: hid.usbHidStatus,
        statusColor: hid.usbHidActive ? T.teal : T.greyDim,
        action: null,
      ),
      const SizedBox(height: 10),

      // Detect USB
      GestureDetector(
        onTap: () async {
          setState(() => _checking = true);
          final detected = await context.read<HidService>().checkUsbConnected();
          setState(() { _checking = false; _usbDetected = detected; });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: T.bg3, border: Border.all(color: T.border)),
          child: Center(child: _checking
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: T.teal))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search, color: T.grey, size: 15),
                  const SizedBox(width: 6),
                  Text('DETECT USB CONNECTION', style: T.raj(13, color: T.grey)),
                ])),
        ),
      ),

      if (_usbDetected || hid.usbHidActive) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: T.teal.withOpacity(0.08),
            border: Border.all(color: T.teal.withOpacity(0.4)),
          ),
          child: Row(children: [
            Icon(Icons.check_circle, color: T.teal, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('USB device detected. Ready to connect as HID.',
                style: T.mono(9, color: T.teal))),
          ]),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: hid.usbHidActive
              ? () => context.read<HidService>().stopUsbHid()
              : () => context.read<HidService>().startUsbHid(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: hid.usbHidActive ? T.bg3 : T.red,
            child: Center(child: Text(
              hid.usbHidActive ? 'STOP USB HID' : 'START USB HID',
              style: T.raj(14))),
          ),
        ),
      ],

      if (!_usbDetected && !hid.usbHidActive)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text('Plug your phone into the PC via USB cable, then press Detect.',
              style: T.mono(9, color: T.greyDim), textAlign: TextAlign.center),
        ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WEBRTC PANEL
// ══════════════════════════════════════════════════════════════════════════════
class _WebRtcPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final webrtc = context.watch<WebRtcService>();

    return _SubPanel(children: [
      // Info banner
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF9C27B0).withOpacity(0.08),
          border: Border(left: BorderSide(color: const Color(0xFF9C27B0), width: 3)),
        ),
        child: Text(
          'Using WebRTC will itself handle HID communication.\n'
          'Your PC screen will stream to this device and all inputs '
          'will be sent back via the WebRTC DataChannel.',
          style: T.mono(9, color: T.grey),
        ),
      ),
      const SizedBox(height: 14),

      Text('STATUS: ${webrtc.statusText}',
          style: T.mono(10, color: webrtc.isConnected ? T.teal : T.greyDim)),
      const SizedBox(height: 14),

      if (!webrtc.isConnected) ...[
        // Scan QR button
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QrScanScreen())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: T.red,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('SCAN QR CODE FROM PC', style: T.raj(14)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text('Run pc_server/server.js on your PC to get a QR code.',
            style: T.mono(9, color: T.greyDim), textAlign: TextAlign.center)),
      ] else ...[
        GestureDetector(
          onTap: () => context.read<WebRtcService>().disconnect(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: T.bg3, border: Border.all(color: T.border)),
            child: Center(child: Text('DISCONNECT', style: T.raj(14, color: T.grey))),
          ),
        ),
      ],
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// RECEIVE CAST PANEL
// ══════════════════════════════════════════════════════════════════════════════
class _CastPanel extends StatefulWidget {
  @override State<_CastPanel> createState() => _CastPanelState();
}

class _CastPanelState extends State<_CastPanel> {
  bool _dontShow  = false;
  bool _dismissed = false;
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream
    _ctrl = TextEditingController(text: context.read<WifiService>().ip);
=======
    SharedPreferences.getInstance().then((p) {
      setState(() => _dismissed = p.getBool('cast_msg_dismissed') ?? false);
    });
>>>>>>> Stashed changes
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    final wifi = context.watch<WifiService>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ESP32 IP ADDRESS', style: T.mono(9, color: T.greyDim)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: T.bg2, border: Border.all(color: T.red)),
          child: TextField(
            controller: _ctrl,
            style: T.raj(15),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(12), border: InputBorder.none,
            ),
            onChanged: (v) => context.read<WifiService>().setIp(v),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: wifi.connected
              ? () => context.read<WifiService>().disconnect()
              : () => context.read<WifiService>().connect(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: wifi.connected ? T.bg3 : T.red,
            child: Center(child: Text(wifi.connected ? 'DISCONNECT' : 'CONNECT',
                style: T.raj(14))),
          ),
        ),
      ]),
    );
  }
}

// ── Data stream ───────────────────────────────────────────────────────────────
class _DataStream extends StatelessWidget {
  final List<String> logs;
  const _DataStream({required this.logs});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    decoration: T.panel(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('RAW DATA STREAM', style: T.mono(9, color: T.grey)),
          const Icon(Icons.terminal, color: T.teal, size: 14),
        ]),
      ),
      const Divider(color: T.border, height: 1),
      SizedBox(
        height: 120,
        child: logs.isEmpty
            ? Center(child: Text('Awaiting data…', style: T.mono(9, color: T.greyDim)))
            : ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: logs.take(20).length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(logs[i], style: T.mono(9, color: T.grey)),
          ),
=======
    return _SubPanel(children: [
      // Info message (dismissable)
      if (!_dismissed) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withOpacity(0.08),
            border: Border(left: BorderSide(color: const Color(0xFF00BCD4), width: 3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Receiving cast from your PC or laptop will mirror the screen '
              'onto your mobile device. HID input can still be sent in parallel '
              'using Bluetooth, USB HID, or UDP packets. Choose one of these '
              'channels to control your PC while receiving the cast.',
              style: T.mono(9, color: T.grey),
            ),
            const SizedBox(height: 10),
            // Don't show again checkbox
            GestureDetector(
              onTap: () async {
                setState(() => _dontShow = !_dontShow);
                if (_dontShow) {
                  final p = await SharedPreferences.getInstance();
                  await p.setBool('cast_msg_dismissed', true);
                  setState(() => _dismissed = true);
                }
              },
              child: Row(children: [
                Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: _dontShow ? T.red : Colors.transparent,
                    border: Border.all(color: _dontShow ? T.red : T.grey),
                  ),
                  child: _dontShow
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                Text("Don't show this message again",
                    style: T.mono(9, color: T.grey)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
      ],

      // HID channel selection reminder
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: T.bg3, border: Border.all(color: T.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CHOOSE HID CHANNEL', style: T.mono(9, color: T.greyDim).copyWith(letterSpacing:2)),
          const SizedBox(height: 8),
          Row(children: [
            _HidChip(icon: Icons.bluetooth, label: 'Bluetooth'),
            const SizedBox(width: 8),
            _HidChip(icon: Icons.usb,       label: 'USB HID'),
            const SizedBox(width: 8),
            _HidChip(icon: Icons.wifi,      label: 'UDP'),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: const Color(0xFF00BCD4).withOpacity(0.15),
        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cast, color: Color(0xFF00BCD4), size: 18),
          const SizedBox(width: 8),
          Text('START RECEIVING CAST', style: T.raj(14, color: const Color(0xFF00BCD4))),
        ])),
      ),
    ]);
  }
}

class _HidChip extends StatelessWidget {
  final IconData icon; final String label;
  const _HidChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: T.bg2, border: Border.all(color: T.border)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: T.grey, size: 13),
      const SizedBox(width: 5),
      Text(label, style: T.mono(9, color: T.grey)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED SUB-PANEL WRAPPER
// ══════════════════════════════════════════════════════════════════════════════
class _SubPanel extends StatelessWidget {
  final List<Widget> children;
  const _SubPanel({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 1),
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
    decoration: BoxDecoration(
      color: T.bg2,
      border: Border.all(color: T.border),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════════════
class _InfoRow extends StatelessWidget {
  final String label, sub;
  final Color  statusColor;
  final Widget? action;
  const _InfoRow({required this.label, required this.sub,
      required this.statusColor, required this.action});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 6, height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
    const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: T.raj(13)),
      Text(sub,   style: T.mono(9, color: statusColor)),
    ])),
    if (action != null) action!,
  ]);
}

Widget _ActionBtn(String label, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(label, style: T.mono(9, color: color)),
      ),
    );

class _DeviceTile extends StatelessWidget {
  final String name, sub, actionLabel;
  final Color  subColor;
  final bool   isConnected;
  final int?   rssi;
  final VoidCallback onTap;

  const _DeviceTile({required this.name, required this.sub,
      required this.subColor, required this.actionLabel,
      required this.isConnected, required this.onTap, this.rssi});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: T.panel(active: isConnected),
    child: Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: isConnected ? T.red.withOpacity(0.12) : T.bg3,
          shape: BoxShape.circle,
          border: Border.all(color: isConnected ? T.red : T.border),
        ),
        child: Icon(Icons.bluetooth, color: isConnected ? T.red : T.greyDim, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name.length > 20 ? '${name.substring(0,20)}…' : name, style: T.raj(13)),
        Row(children: [
          if (isConnected) Container(width:5,height:5,
              margin:const EdgeInsets.only(right:5),
              decoration:BoxDecoration(shape:BoxShape.circle,color:T.teal)),
          Text(sub, style: T.mono(8, color: subColor)),
          if (rssi != null) ...[
            const SizedBox(width: 6),
            Text('$rssi dBm', style: T.mono(8, color: T.greyDim)),
          ],
        ]),
      ])),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: isConnected ? T.bg3 : T.red,
          child: Text(actionLabel, style: T.mono(9, color: Colors.white)),
>>>>>>> Stashed changes
        ),
      ),
    ]),
  );
}
