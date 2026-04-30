import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/app_models.dart';
import '../services/ble_service.dart';
import '../services/wifi_service.dart';
import '../utils/app_theme.dart';

class ConnectivityScreen extends StatefulWidget {
  const ConnectivityScreen({super.key});
  @override State<ConnectivityScreen> createState() => _ConnState();
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

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ]),
    );
  }
}

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
    ]),
  );
}

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

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: context.read<WifiService>().ip);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
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
        ),
      ),
    ]),
  );
}
