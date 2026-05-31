import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Fixed: Removed unused import 'package:flutter_blue_plus/flutter_blue_plus.dart'; to fix the warning on Line 3
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vlink/models/app_models.dart';
import 'package:vlink/services/ble_service.dart';
import 'package:vlink/services/wifi_service.dart';
import 'package:vlink/services/hid_service.dart';
import 'package:vlink/services/webrtc_service.dart';
import 'package:vlink/utils/app_theme.dart';
import 'package:vlink/widgets/v_header.dart';
import 'qr_scan_screen.dart';

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
    return Scaffold(
      backgroundColor: T.bg0,
      body: CustomScrollView(slivers: [

        SliverToBoxAdapter(child: VHeader(
          title: 'CONNECTIVITY',
          sub: 'V-LINK DEVICE MANAGER',
        )),

        SliverToBoxAdapter(child: _SectionLabel(
          icon: Icons.gamepad_outlined,
          title: 'HID',
          subtitle: 'Send keyboard & mouse inputs to your PC',
        )),

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
              const _BluetoothHidPanel(),
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

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ]),
    );
  }
}

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
          // Fixed: Swapped .withOpacity with .withValues to satisfy modern analyzer guidelines
          color: T.red.withValues(alpha: 0.12),
          border: Border.all(color: T.red.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: T.red, size: 18),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,    style: T.orb(15, color: T.white)),
        Text(subtitle, style: T.mono(9, color: T.grey)),
      ]),
    ]),
  );
}

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
          // Fixed: Swapped .withOpacity with .withValues
          color: selected ? iconColor.withValues(alpha: 0.10) : T.bg1,
          border: Border.all(
            color: selected ? iconColor : T.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              // Fixed: Swapped .withOpacity with .withValues
              color: iconColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: selected ? 0.8 : 0.4),
                width: selected ? 2 : 1.2,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(title, style: T.raj(16, color: selected ? T.white : T.white)),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    // Fixed: Swapped .withOpacity with .withValues
                    color: (badgeColor ?? T.teal).withValues(alpha: 0.20),
                    child: Text(badge!, style: T.mono(8, color: badgeColor ?? T.teal)),
                  ),
                ],
              ]),
              const SizedBox(height: 3),
              Text(subtitle, style: T.mono(9, color: T.grey)),
            ],
          )),
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

class _BluetoothHidPanel extends StatelessWidget {
  const _BluetoothHidPanel();

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final conn = context.watch<ConnModel>();
    final hid = context.watch<HidService>();

    final isAdvertising = hid.btHidStatus == 'Advertising...';
    final isConnectedToHost = hid.btHidActive && !isAdvertising;

    return _SubPanel(children: [
      _InfoRow(
        label: 'PHONE AS BT HID DEVICE',
        sub: isConnectedToHost ? 'Connected' : hid.btHidStatus,
        statusColor: hid.btHidActive ? T.teal : T.greyDim,
        action: isConnectedToHost || isAdvertising
            ? null
            : _ActionBtn('ADVERTISE', T.red, () {
                context.read<HidService>().startBluetoothHid();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Phone is advertising for 300 seconds...', style: T.mono(10)),
                  backgroundColor: T.bg3,
                  duration: const Duration(seconds: 4),
                ));
              }),
      ),
      if (isConnectedToHost || isAdvertising)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: _ActionBtn('STOP', T.grey, () => context.read<HidService>().stopBluetoothHid()),
        ),

      const Divider(color: T.border, height: 24, thickness: 1),

      Text('OR CONNECT TO ESP32 VIA BLE', style: T.mono(8, color: T.greyDim).copyWith(letterSpacing: 2)),
      const SizedBox(height: 12),

      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AVAILABLE DEVICES', style: T.raj(14)),
          Text(ble.scanning ? 'Searching for devices…' : 'Press SCAN to search',
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
      const SizedBox(height: 12),

      if (conn.isConnected && conn.mode == Transport.ble)
        _DeviceTile(
          name: conn.deviceName ?? 'DEVICE', sub: '● CONNECTED', subColor: T.teal,
          actionLabel: 'DISCONNECT', isConnected: true,
          onTap: () => context.read<BleService>().disconnect(),
        ),

      if (ble.pairedDevices.isNotEmpty)
        ...ble.pairedDevices.map((d) {
           final name = d.platformName.isNotEmpty ? d.platformName : d.remoteId.toString();
           if (conn.isConnected && conn.mode == Transport.ble && name == conn.deviceName) return const SizedBox.shrink();
           return _DeviceTile(
              name: name,
              sub: 'Paired Device', subColor: T.grey,
              actionLabel: 'CONNECT', isConnected: false,
              onTap: () => context.read<BleService>().connect(d),
           );
        }),

      if (ble.discovered.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text('New devices', style: T.mono(10, color: T.greyDim)),
        ),
      ...ble.discovered.map((r) {
        final name = r.device.platformName.isNotEmpty ? r.device.platformName : r.device.remoteId.toString();
        return _DeviceTile(
          name: name, sub: 'Available to pair', subColor: T.greyDim,
          actionLabel: 'PAIR', isConnected: false, rssi: r.rssi,
          onTap: () => context.read<BleService>().connect(r.device),
        );
      }),

      if (ble.discovered.isEmpty && ble.pairedDevices.isEmpty && !conn.isConnected)
        Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('No devices found. Press SCAN.',
              style: T.mono(9, color: T.greyDim)),
        )),
    ]);
  }
}

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
          onTap: conn.isConnected && conn.mode == Transport.wifi
              ? () => context.read<WifiService>().disconnect()
              : () => context.read<WifiService>().connect(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: conn.isConnected && conn.mode == Transport.wifi ? T.bg3 : T.red,
            child: Text(conn.isConnected && conn.mode == Transport.wifi ? 'DISCONNECT' : 'CONNECT', style: T.raj(13)),
          ),
        ),
      ]),
    ]);
  }
}

class _UsbHidPanel extends StatefulWidget {
  @override State<_UsbHidPanel> createState() => _UsbHidPanelState();
}

class _UsbHidPanelState extends State<_UsbHidPanel> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<HidService>().checkUsbPrerequisites());
  }

  Future<void> _detectHost() async {
    setState(() => _checking = true);
    await context.read<HidService>().detectUsbHost();
    if (mounted) {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hid = context.watch<HidService>();
    final pcName = hid.usbHostName;
    final prerequisitesMet = hid.usbDebuggingEnabled && hid.usbConnected;

    return _SubPanel(children: [
      _PrerequisiteRow(label: 'USB Debugging Enabled', met: hid.usbDebuggingEnabled),
      const SizedBox(height: 8),
      _PrerequisiteRow(label: 'USB Cable Connected', met: hid.usbConnected),
      const SizedBox(height: 14),
      const Divider(color: T.border, height: 1, thickness: 1),
      const SizedBox(height: 14),

      if (!hid.usbHidActive) ...[
        GestureDetector(
          onTap: prerequisitesMet ? _detectHost : null,
          child: Opacity(
            opacity: prerequisitesMet ? 1.0 : 0.4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: T.bg3, border: Border.all(color: T.border)),
              child: Center(child: _checking
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: T.teal))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.search, size: 15, color: prerequisitesMet ? T.grey : T.greyDim),
                      const SizedBox(width: 6),
                      Text('DETECT USB CONNECTION',
                          style: T.raj(13, color: prerequisitesMet ? T.grey : T.greyDim)),
                    ])),
            ),
          ),
        ),

        if (pcName != null) ...[
          const SizedBox(height: 10),
          _DeviceTile(
            icon: Icons.desktop_windows,
            name: pcName,
            sub: 'ADB Host PC detected',
            subColor: T.teal,
            actionLabel: 'CONNECT',
            isConnected: false,
            onTap: () => context.read<HidService>().startUsbHid(),
          ),
        ],

        if (pcName == null && !_checking)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Enable the options above, then press Detect.',
                style: T.mono(9, color: T.greyDim), textAlign: TextAlign.center),
          ),
      ] else ...[
        _DeviceTile(
          icon: Icons.desktop_windows,
          name: pcName ?? 'Unknown PC',
          sub: '● CONNECTED',
          subColor: T.teal,
          actionLabel: 'DISCONNECT',
          isConnected: true,
          onTap: () => context.read<HidService>().stopUsbHid(),
        ),
      ],
    ]);
  }
}

class _PrerequisiteRow extends StatelessWidget {
  final String label;
  final bool met;

  const _PrerequisiteRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(
        met ? Icons.check_box : Icons.check_box_outline_blank,
        color: met ? T.teal : T.greyDim,
        size: 20,
      ),
      const SizedBox(width: 10),
      Text(label, style: T.raj(14, color: met ? T.white : T.greyDim)),
    ]);
  }
}


class _WebRtcPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final webrtc = context.watch<WebRtcService>();

    return _SubPanel(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Fixed: Swapped .withOpacity with .withValues
          color: const Color(0xFF9C27B0).withValues(alpha: 0.08),
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

      Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: webrtc.isConnected ? Colors.green : T.greyDim,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            webrtc.isConnected ? 'Connected' : 'Not connected',
            style: T.mono(10, color: webrtc.isConnected ? T.teal : T.greyDim),
          ),
        ],
      ),
      const SizedBox(height: 14),

      if (!webrtc.isConnected) ...[
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
        Center(child: Text('Run the V-Link WebRTC to get the QR code.',
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

class _CastPanel extends StatefulWidget {
  @override State<_CastPanel> createState() => _CastPanelState();
}

class _CastPanelState extends State<_CastPanel> {
  bool _dontShow  = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      setState(() => _dismissed = p.getBool('cast_msg_dismissed') ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SubPanel(children: [
      if (!_dismissed) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // Fixed: Swapped .withOpacity with .withValues
            color: const Color(0xFF00BCD4).withValues(alpha: 0.08),
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
        // Fixed: Swapped .withOpacity with .withValues
        color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
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

class _InfoRow extends StatelessWidget {
  final String label, sub;
  final Color  statusColor;
  final Widget? action;
  const _InfoRow({required this.label, required this.sub,
      required this.statusColor, this.action});
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
          // Fixed: Swapped .withOpacity with .withValues
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
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
  final IconData? icon;

  const _DeviceTile({required this.name, required this.sub,
      required this.subColor, required this.actionLabel,
      required this.isConnected, required this.onTap, this.rssi, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: T.panel(active: isConnected),
    child: Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          // Fixed: Swapped .withOpacity with .withValues
          color: isConnected ? T.red.withValues(alpha: 0.12) : T.bg3,
          shape: BoxShape.circle,
          border: Border.all(color: isConnected ? T.red : T.border),
        ),
        child: Icon(icon ?? Icons.bluetooth, color: isConnected ? T.red : T.greyDim, size: 16),
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
        ),
      ),
    ]),
  );
}