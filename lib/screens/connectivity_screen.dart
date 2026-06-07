import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';
import '../services/ble_service.dart';
import '../services/hid_service.dart';
import '../services/webrtc_service.dart';
import '../services/wifi_service.dart';
import '../utils/app_theme.dart';
import 'qr_scan_screen.dart';

// ── Which sub-panel is open ───────────────────────────────────────────────────
enum _HidMode { none, bluetooth, wifi, usb }

enum _MirrorMode { none, webrtc, cast }

const int _kAdvertiseDuration = 300;

// ══════════════════════════════════════════════════════════════════════════════
// ROOT SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class ConnectivityScreen extends StatefulWidget {
  const ConnectivityScreen({super.key});
  @override
  State<ConnectivityScreen> createState() => _ConnState();
}

class _ConnState extends State<ConnectivityScreen> {
  _HidMode _hidMode = _HidMode.none;
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
        SliverToBoxAdapter(
            child: VHeader(title: 'CONNECTIVITY', sub: 'V-LINK DEVICE MANAGER')),

        // ── SECTION 1: HID ────────────────────────────────────────────────
        SliverToBoxAdapter(
            child: _SectionLabel(
          icon: Icons.gamepad_outlined,
          title: 'HID',
          subtitle: 'Send keyboard & mouse inputs to your PC',
        )),

        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            _BigOptionCard(
              icon: Icons.bluetooth,
              iconColor: const Color(0xFF2196F3),
              title: 'Bluetooth',
              subtitle: 'Pair phone as BT keyboard + mouse',
              selected: _hidMode == _HidMode.bluetooth,
              onTap: () => setState(() => _hidMode =
                  _hidMode == _HidMode.bluetooth
                      ? _HidMode.none
                      : _HidMode.bluetooth),
            ),
            if (_hidMode == _HidMode.bluetooth) const _BluetoothTabPanel(),

            const SizedBox(height: 8),
            _BigOptionCard(
              icon: Icons.wifi,
              iconColor: const Color(0xFF4CAF50),
              title: 'Wi-Fi UDP',
              subtitle: 'Send inputs over local network',
              selected: _hidMode == _HidMode.wifi,
              onTap: () => setState(() => _hidMode =
                  _hidMode == _HidMode.wifi ? _HidMode.none : _HidMode.wifi),
            ),
            if (_hidMode == _HidMode.wifi) _WifiHidPanel(),

            const SizedBox(height: 8),
            _BigOptionCard(
              icon: Icons.usb,
              iconColor: const Color(0xFFFF9800),
              title: 'USB HID',
              subtitle: 'Connect via USB cable as HID device',
              selected: _hidMode == _HidMode.usb,
              onTap: () => setState(() => _hidMode =
                  _hidMode == _HidMode.usb ? _HidMode.none : _HidMode.usb),
            ),
            if (_hidMode == _HidMode.usb) _UsbHidPanel(),
          ]),
        )),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── SECTION 2: Screen Mirroring ───────────────────────────────────
        SliverToBoxAdapter(
            child: _SectionLabel(
          icon: Icons.cast_outlined,
          title: 'SCREEN MIRRORING',
          subtitle: 'See your PC screen on this device',
        )),

        SliverToBoxAdapter(
            child: Padding(
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
              onTap: () => setState(() => _mirrorMode =
                  _mirrorMode == _MirrorMode.webrtc
                      ? _MirrorMode.none
                      : _MirrorMode.webrtc),
            ),
            if (_mirrorMode == _MirrorMode.webrtc) _WebRtcPanel(),

            const SizedBox(height: 8),
            _BigOptionCard(
              icon: Icons.cast,
              iconColor: const Color(0xFF00BCD4),
              title: 'Receive Cast',
              subtitle: 'Mirror PC screen — HID via separate channel',
              selected: _mirrorMode == _MirrorMode.cast,
              onTap: () => setState(() => _mirrorMode =
                  _mirrorMode == _MirrorMode.cast
                      ? _MirrorMode.none
                      : _MirrorMode.cast),
            ),
            if (_mirrorMode == _MirrorMode.cast) _CastPanel(),
          ]),
        )),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BLUETOOTH TAB PANEL
// ══════════════════════════════════════════════════════════════════════════════
class _BluetoothTabPanel extends StatefulWidget {
  const _BluetoothTabPanel();
  @override
  State<_BluetoothTabPanel> createState() => _BluetoothTabPanelState();
}

class _BluetoothTabPanelState extends State<_BluetoothTabPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SubPanel(children: [
      Container(
        decoration: BoxDecoration(
          color: T.bg3,
          border: Border.all(color: T.border),
        ),
        child: TabBar(
          controller: _tab,
          indicatorColor: const Color(0xFF2196F3),
          indicatorWeight: 2,
          labelColor: Colors.white,
          unselectedLabelColor: T.greyDim,
          labelStyle: T.mono(10),
          unselectedLabelStyle: T.mono(10),
          tabs: const [
            Tab(text: 'PAIR PHONE AS HID'),
            Tab(text: 'CONNECT SERIAL'),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Height adapts per tab to avoid layout jumps
      SizedBox(
        height: _tab.index == 0 ? 320 : 420,
        child: TabBarView(
          controller: _tab,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _HidPeripheralTab(),
            _SerialCentralTab(),
          ],
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — HID PERIPHERAL
// All advertising calls go through HidService → MethodChannel → native Kotlin.
// ══════════════════════════════════════════════════════════════════════════════
class _HidPeripheralTab extends StatefulWidget {
  const _HidPeripheralTab();
  @override
  State<_HidPeripheralTab> createState() => _HidPeripheralTabState();
}

class _HidPeripheralTabState extends State<_HidPeripheralTab>
    with TickerProviderStateMixin {
  // UI-only state
  bool _advertising = false;
  int _secondsLeft = _kAdvertiseDuration;
  Timer? _timer;

  // Radar sweep animation
  late AnimationController _radarCtrl;
  late Animation<double> _radarAnim;

  // Pulse ring animation
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _radarAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _radarCtrl, curve: Curves.linear),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _radarCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Permissions (Android API 34) ──────────────────────────────────────────
  Future<bool> _checkPermissions() async {
    final statuses = await [
      Permission.bluetoothAdvertise, // BLUETOOTH_ADVERTISE  (API 31+)
      Permission.bluetoothConnect,   // BLUETOOTH_CONNECT    (API 31+)
      Permission.bluetoothScan,      // BLUETOOTH_SCAN       (API 31+)
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  // ── Start ─────────────────────────────────────────────────────────────────
  Future<void> _startAdvertising() async {
    final ok = await _checkPermissions();
    if (!ok) {
      _toast('Bluetooth permissions required');
      return;
    }

    // Mutual exclusion: stop scan if active
    if (context.mounted) {
      final ble = context.read<BleService>();
      if (ble.scanning) ble.stopScan();
    }

    // 1. Delegate to the new HidService method
    await context.read<HidService>().startBluetoothHid();
    
    // 2. Start local UI timers
    setState(() => _secondsLeft = _kAdvertiseDuration);
    _radarCtrl.repeat();
    _pulseCtrl.repeat();
    _toast('Advertising phone for $_kAdvertiseDuration seconds');

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _stopAdvertising();
    });
  }

  // ── Stop ──────────────────────────────────────────────────────────────────
  Future<void> _stopAdvertising() async {
    _timer?.cancel();
    
    // Delegate to the new HidService method
    await context.read<HidService>().stopBluetoothHid();

    if (!mounted) return;
    setState(() => _secondsLeft = _kAdvertiseDuration);
    _radarCtrl.stop();
    _pulseCtrl..stop()..reset();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: T.mono(11, color: Colors.white)),
      backgroundColor: T.bg3,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(),
    ));
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

@override
Widget build(BuildContext context) {
  // Listen to the service state
  final hid = context.watch<HidService>();
  
  // Use hid.isAdvertising instead of your local _advertising variable
  final bool isAdvertising = hid.isAdvertising; 

  return Column(children: [
    // ... radar widget uses isAdvertising ...
    
    GestureDetector(
      onTap: isAdvertising ? _stopAdvertising : _startAdvertising,
      // ... button visual logic ...
    ),
  ]);
}

      // ── Countdown / ready label ──────────────────────────────────────
      if (_advertising) ...[
        Text(_fmt(_secondsLeft),
            style: T.mono(22, color: const Color(0xFF2196F3))),
        const SizedBox(height: 4),
        Text('seconds remaining', style: T.mono(9, color: T.greyDim)),
        const SizedBox(height: 14),
        Container(
          height: 2,
          color: T.bg3,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _secondsLeft / _kAdvertiseDuration,
            child: Container(color: const Color(0xFF2196F3)),
          ),
        ),
        const SizedBox(height: 14),

        // Native-reported connection status
        Text(hid.btHidStatus.toUpperCase(),
            style: T.mono(9,
                color: hid.btHidActive
                    ? T.teal
                    : const Color(0xFF2196F3))),
        const SizedBox(height: 10),
      ] else ...[
        Text('READY TO ADVERTISE', style: T.mono(10, color: T.greyDim)),
        const SizedBox(height: 14),
      ],

      // ── Big advertise / stop button ──────────────────────────────────
      GestureDetector(
        onTap: _advertising ? _stopAdvertising : _startAdvertising,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _advertising ? T.bg3 : const Color(0xFF2196F3),
            border: Border.all(
                color: _advertising ? T.border : const Color(0xFF2196F3)),
          ),
          child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                _advertising ? Icons.stop : Icons.bluetooth_searching,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _advertising ? 'STOP ADVERTISING' : 'ADVERTISE AS HID',
                style: T.raj(15, color: Colors.white),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// RADAR PAINTERS
// ══════════════════════════════════════════════════════════════════════════════
class _RadarWidget extends StatelessWidget {
  final Animation<double> radarAnim;
  final Animation<double> pulseAnim;
  const _RadarWidget({required this.radarAnim, required this.pulseAnim});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([radarAnim, pulseAnim]),
        builder: (_, __) => CustomPaint(
          size: const Size(140, 140),
          painter: _RadarPainter(radarAnim.value, pulseAnim.value),
        ),
      );
}

class _RadarPainter extends CustomPainter {
  final double angle;
  final double pulse;
  const _RadarPainter(this.angle, this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Rings
    final ringPaint = Paint()
      ..color = const Color(0xFF2196F3).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(Offset(cx, cy), r * i / 3, ringPaint);
    }

    // Crosshairs
    final linePaint = Paint()
      ..color = const Color(0xFF2196F3).withOpacity(0.15)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), linePaint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), linePaint);

    // Sweep sector
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - 1.2,
        endAngle: angle,
        colors: [
          Colors.transparent,
          const Color(0xFF2196F3).withOpacity(0.55),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..style = PaintingStyle.fill;
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        angle - 1.2,
        1.2,
        true,
        sweepPaint);

    // Leading edge line
    final edgePaint = Paint()
      ..color = const Color(0xFF2196F3).withOpacity(0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, cy),
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)), edgePaint);

    // Pulse ring
    if (pulse > 0) {
      canvas.drawCircle(
        Offset(cx, cy),
        r * pulse,
        Paint()
          ..color = const Color(0xFF2196F3).withOpacity((1 - pulse) * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Centre dot
    canvas.drawCircle(
        Offset(cx, cy), 4, Paint()..color = const Color(0xFF2196F3));
  }

  @override
  bool shouldRepaint(_RadarPainter old) => true;
}

class _IdleRadarWidget extends StatelessWidget {
  const _IdleRadarWidget();
  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(120, 120),
        painter: _IdleRadarPainter(),
      );
}

class _IdleRadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final paint = Paint()
      ..color = const Color(0xFF1c2a38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(Offset(cx, cy), r * i / 3, paint);
    }
    final lp = Paint()
      ..color = const Color(0xFF1c2a38)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), lp);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), lp);
    canvas.drawCircle(
        Offset(cx, cy), 4, Paint()..color = const Color(0xFF3d5166));
  }

  @override
  bool shouldRepaint(_IdleRadarPainter old) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — SERIAL CENTRAL
// All scan / connect calls go through BleService.
// ══════════════════════════════════════════════════════════════════════════════
class _SerialCentralTab extends StatefulWidget {
  const _SerialCentralTab();
  @override
  State<_SerialCentralTab> createState() => _SerialCentralTabState();
}

class _SerialCentralTabState extends State<_SerialCentralTab>
    with SingleTickerProviderStateMixin {
  final List<ScanResult> _discovered = [];
  final Set<String> _pairedIds = {};
  StreamSubscription<List<ScanResult>>? _scanSub;
  bool _scanning = false;

  // Shimmer animation for the loading bar
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _shimmerAnim = Tween<double>(begin: -0.4, end: 1.4).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
    _loadPairedDevices();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _scanSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _loadPairedDevices() async {
    final bonded = await FlutterBluePlus.bondedDevices;
    if (mounted) {
      setState(() => _pairedIds.addAll(bonded.map((d) => d.remoteId.str)));
    }
  }

  Future<bool> _checkPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  Future<void> _startScan() async {
    final ok = await _checkPermissions();
    if (!ok) return;

    _discovered.clear();
    setState(() => _scanning = true);
    _shimmerCtrl.repeat();

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        for (final r in results) {
          final idx = _discovered
              .indexWhere((d) => d.device.remoteId == r.device.remoteId);
          if (idx >= 0) {
            _discovered[idx] = r;
          } else {
            _discovered.add(r);
          }
        }
      });
    });

    FlutterBluePlus.isScanning.listen((active) {
      if (!active && mounted && _scanning) _stopScan();
    });
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _shimmerCtrl
      ..stop()
      ..reset();
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Connected to ${device.platformName}',
              style: T.mono(11, color: Colors.white)),
          backgroundColor: T.bg3,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Connection failed: $e',
              style: T.mono(11, color: Colors.white)),
          backgroundColor: T.bg3,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paired = _discovered
        .where((r) => _pairedIds.contains(r.device.remoteId.str))
        .toList();
    final available = _discovered
        .where((r) => !_pairedIds.contains(r.device.remoteId.str))
        .toList();

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          "Connecting to available Bluetooth devices' serial.",
          style: T.mono(10, color: T.grey),
        ),
        const SizedBox(height: 12),

        // ── Scan row ──────────────────────────────────────────────────
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text('AVAILABLE DEVICES', style: T.raj(14)),
            Text(
              _scanning ? 'Started scanning…' : 'Press SCAN to search',
              style: T.mono(9,
                  color: _scanning
                      ? const Color(0xFF2196F3)
                      : T.greyDim),
            ),
          ])),
          GestureDetector(
            onTap: _scanning ? _stopScan : _startScan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _scanning ? T.bg3 : T.red,
              child:
                  Text(_scanning ? 'STOP' : 'SCAN', style: T.raj(13)),
            ),
          ),
        ]),

        // ── Shimmer loading bar ───────────────────────────────────────
        const SizedBox(height: 6),
        SizedBox(
          height: 2,
          child: _scanning
              ? AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (_, __) {
                    final v = _shimmerAnim.value;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: const [
                            Color(0xFF1c2a38),
                            Color(0xFF2196F3),
                            Color(0xFF1c2a38),
                          ],
                          stops: [
                            (v - 0.4).clamp(0.0, 1.0),
                            v.clamp(0.0, 1.0),
                            (v + 0.4).clamp(0.0, 1.0),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : Container(color: T.border),
        ),
        const SizedBox(height: 10),

        // ── Paired devices (blue theme) ───────────────────────────────
        if (paired.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('PAIRED DEVICES',
                style: T.mono(8, color: const Color(0xFF2196F3))
                    .copyWith(letterSpacing: 2)),
          ),
          ...paired.map((r) => _SerialDeviceTile(
                result: r,
                isPaired: true,
                onAction: () => _connect(r.device),
              )),
          const SizedBox(height: 10),
        ],

        // ── Available / not paired (red theme) ───────────────────────
        if (available.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('NEARBY DEVICES',
                style:
                    T.mono(8, color: T.red).copyWith(letterSpacing: 2)),
          ),
          ...available.map((r) => _SerialDeviceTile(
                result: r,
                isPaired: false,
                onAction: () => _connect(r.device),
              )),
        ],

        if (_discovered.isEmpty && !_scanning)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text('No devices found. Press SCAN.',
                  style: T.mono(9, color: T.greyDim)),
            ),
          ),
      ]),
    );
  }
}

// ── Serial device tile ────────────────────────────────────────────────────────
class _SerialDeviceTile extends StatelessWidget {
  final ScanResult result;
  final bool isPaired;
  final VoidCallback onAction;
  const _SerialDeviceTile(
      {required this.result,
      required this.isPaired,
      required this.onAction});

  @override
  Widget build(BuildContext context) {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : result.device.remoteId.str;
    final accent =
        isPaired ? const Color(0xFF2196F3) : T.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        border: Border.all(color: accent.withOpacity(0.45)),
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withOpacity(0.7)),
          ),
          child: Icon(Icons.bluetooth, color: accent, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text(name.length > 22 ? '${name.substring(0, 22)}…' : name,
              style: T.raj(13)),
          Row(children: [
            Text(isPaired ? 'PAIRED  ' : 'AVAILABLE  ',
                style: T.mono(8, color: accent)),
            Text('${result.rssi} dBm',
                style: T.mono(8, color: T.greyDim)),
          ]),
        ])),
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: accent,
            child: Text(
              isPaired ? 'CONNECT' : 'PAIR & CONNECT',
              style: T.mono(9, color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION LABEL
// ══════════════════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _SectionLabel(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: T.red.withOpacity(0.12),
              border: Border.all(color: T.red.withOpacity(0.4)),
            ),
            child: Icon(icon, color: T.red, size: 18),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: T.orb(15, color: T.white)),
            Text(subtitle, style: T.mono(9, color: T.grey)),
          ]),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// BIG OPTION CARD
// ══════════════════════════════════════════════════════════════════════════════
class _BigOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool selected;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _BigOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? iconColor.withOpacity(0.10) : T.bg1,
            border: Border.all(
                color: selected ? iconColor : T.border,
                width: selected ? 1.5 : 1),
          ),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.14),
                shape: BoxShape.circle,
                border: Border.all(
                    color: iconColor.withOpacity(selected ? 0.8 : 0.4),
                    width: selected ? 2 : 1.2),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(title, style: T.raj(16, color: T.white)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      color: (badgeColor ?? T.teal).withOpacity(0.20),
                      child: Text(badge!,
                          style: T.mono(8, color: badgeColor ?? T.teal)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(subtitle, style: T.mono(9, color: T.grey)),
              ],
            )),
            Icon(
              selected
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: selected ? iconColor : T.greyDim,
              size: 20,
            ),
          ]),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// WIFI HID PANEL
// ══════════════════════════════════════════════════════════════════════════════
class _WifiHidPanel extends StatefulWidget {
  @override
  State<_WifiHidPanel> createState() => _WifiHidPanelState();
}

class _WifiHidPanelState extends State<_WifiHidPanel> {
  late TextEditingController _ipCtrl;

  @override
  void initState() {
    super.initState();
    _ipCtrl = TextEditingController(text: context.read<WifiService>().ip);
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wifi = context.watch<WifiService>();
    final conn = context.watch<ConnModel>();

    return _SubPanel(children: [
      Row(children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text('LOCAL NETWORK DEVICES', style: T.raj(14)),
          Text(
              wifi.discovering
                  ? 'Started scanning…'
                  : 'Scanning for UDP devices',
              style: T.mono(9,
                  color: wifi.discovering ? T.teal : T.greyDim)),
        ])),
        GestureDetector(
          onTap: wifi.discovering
              ? () => context.read<WifiService>().stopDiscovery()
              : () => context.read<WifiService>().startDiscovery(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: wifi.discovering ? T.bg3 : T.red,
            child: Text(wifi.discovering ? 'STOP' : 'SCAN',
                style: T.raj(13)),
          ),
        ),
      ]),
      if (wifi.discovering)
        const Padding(
            padding: EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(
                backgroundColor: T.border,
                valueColor: AlwaysStoppedAnimation(T.teal),
                minHeight: 2)),
      const SizedBox(height: 8),
      if (conn.isConnected && conn.mode == Transport.wifi)
        _DeviceTile(
          name: conn.deviceName ?? wifi.ip,
          sub: 'UDP :4242',
          subColor: T.teal,
          actionLabel: 'DISCONNECT',
          isConnected: true,
          onTap: () => context.read<WifiService>().disconnect(),
        ),
      ...wifi.discoveredHosts.map((h) => _DeviceTile(
            name: h,
            sub: 'UDP :4242',
            subColor: T.greyDim,
            actionLabel: 'CONNECT',
            isConnected: false,
            onTap: () {
              context.read<WifiService>().setIp(h);
              context.read<WifiService>().connect();
            },
          )),
      if (wifi.discoveredHosts.isEmpty &&
          !(conn.isConnected && conn.mode == Transport.wifi))
        Center(
            child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('No devices found. Press SCAN.',
              style: T.mono(9, color: T.greyDim)),
        )),
      const Divider(color: T.border, height: 20),
      Text('MANUAL IP',
          style: T.mono(8, color: T.greyDim).copyWith(letterSpacing: 2)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
            child: Container(
          height: 36,
          decoration: BoxDecoration(
              color: T.bg2, border: Border.all(color: T.border)),
          child: TextField(
            controller: _ipCtrl,
            style: T.mono(12, color: T.white),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: InputBorder.none,
              hintText: '192.168.1.100',
              hintStyle: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 11,
                  color: Color(0xFF3D5166)),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: wifi.connected ? T.bg3 : T.red,
            child: Text(wifi.connected ? 'DISCONNECT' : 'CONNECT',
                style: T.raj(13)),
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
  @override
  State<_UsbHidPanel> createState() => _UsbHidPanelState();
}

class _UsbHidPanelState extends State<_UsbHidPanel> {
  bool _checking = false;
  bool _usbDetected = false;

  @override
  Widget build(BuildContext context) {
    final hid = context.watch<HidService>();

    return _SubPanel(children: [
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
      GestureDetector(
        onTap: () async {
          setState(() => _checking = true);
          final detected =
              await context.read<HidService>().checkUsbConnected();
          setState(() {
            _checking = false;
            _usbDetected = detected;
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: T.bg3, border: Border.all(color: T.border)),
          child: Center(
              child: _checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: T.teal))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.search, color: T.grey, size: 15),
                      const SizedBox(width: 6),
                      Text('DETECT USB CONNECTION',
                          style: T.raj(13, color: T.grey)),
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
            Expanded(
                child: Text(
                    'USB device detected. Ready to connect as HID.',
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
            child: Center(
                child: Text(
                    hid.usbHidActive ? 'STOP USB HID' : 'START USB HID',
                    style: T.raj(14))),
          ),
        ),
      ],
      if (!_usbDetected && !hid.usbHidActive)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
              'Plug your phone into the PC via USB cable, then press Detect.',
              style: T.mono(9, color: T.greyDim),
              textAlign: TextAlign.center),
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
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF9C27B0).withOpacity(0.08),
          border: const Border(
              left: BorderSide(color: Color(0xFF9C27B0), width: 3)),
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
          style: T.mono(10,
              color: webrtc.isConnected ? T.teal : T.greyDim)),
      const SizedBox(height: 14),
      if (!webrtc.isConnected) ...[
        GestureDetector(
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QrScanScreen())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: T.red,
            child:
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.qr_code_scanner,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('SCAN QR CODE FROM PC', style: T.raj(14)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Center(
            child: Text(
                'Run pc_server/server.js on your PC to get a QR code.',
                style: T.mono(9, color: T.greyDim),
                textAlign: TextAlign.center)),
      ] else ...[
        GestureDetector(
          onTap: () => context.read<WebRtcService>().disconnect(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: T.bg3, border: Border.all(color: T.border)),
            child: Center(
                child:
                    Text('DISCONNECT', style: T.raj(14, color: T.grey))),
          ),
        ),
      ],
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CAST PANEL
// ══════════════════════════════════════════════════════════════════════════════
class _CastPanel extends StatefulWidget {
  @override
  State<_CastPanel> createState() => _CastPanelState();
}

class _CastPanelState extends State<_CastPanel> {
  bool _dontShow = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance()
        .then((p) => setState(() => _dismissed = p.getBool('cast_msg_dismissed') ?? false));
  }

  @override
  Widget build(BuildContext context) {
    return _SubPanel(children: [
      if (!_dismissed) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withOpacity(0.08),
            border: const Border(
                left: BorderSide(color: Color(0xFF00BCD4), width: 3)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
              'Receiving cast from your PC or laptop will mirror the screen '
              'onto your mobile device. HID input can still be sent in parallel '
              'using Bluetooth, USB HID, or UDP packets.',
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
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _dontShow ? T.red : Colors.transparent,
                    border: Border.all(
                        color: _dontShow ? T.red : T.grey),
                  ),
                  child: _dontShow
                      ? const Icon(Icons.check,
                          size: 12, color: Colors.white)
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
        decoration:
            BoxDecoration(color: T.bg3, border: Border.all(color: T.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CHOOSE HID CHANNEL',
              style: T.mono(9, color: T.greyDim).copyWith(letterSpacing: 2)),
          const SizedBox(height: 8),
          Row(children: [
            _HidChip(icon: Icons.bluetooth, label: 'Bluetooth'),
            const SizedBox(width: 8),
            _HidChip(icon: Icons.usb, label: 'USB HID'),
            const SizedBox(width: 8),
            _HidChip(icon: Icons.wifi, label: 'UDP'),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: const Color(0xFF00BCD4).withOpacity(0.15),
        child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cast, color: Color(0xFF00BCD4), size: 18),
          const SizedBox(width: 8),
          Text('START RECEIVING CAST',
              style: T.raj(14, color: const Color(0xFF00BCD4))),
        ])),
      ),
    ]);
  }
}

class _HidChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HidChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration:
            BoxDecoration(color: T.bg2, border: Border.all(color: T.border)),
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
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(2)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════════════
class _InfoRow extends StatelessWidget {
  final String label, sub;
  final Color statusColor;
  final Widget? action;
  const _InfoRow(
      {required this.label,
      required this.sub,
      required this.statusColor,
      required this.action});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: statusColor)),
        const SizedBox(width: 8),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text(label, style: T.raj(13)),
          Text(sub, style: T.mono(9, color: statusColor)),
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
  final Color subColor;
  final bool isConnected;
  final int? rssi;
  final VoidCallback onTap;

  const _DeviceTile(
      {required this.name,
      required this.sub,
      required this.subColor,
      required this.actionLabel,
      required this.isConnected,
      required this.onTap,
      this.rssi});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: T.panel(active: isConnected),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isConnected ? T.red.withOpacity(0.12) : T.bg3,
              shape: BoxShape.circle,
              border:
                  Border.all(color: isConnected ? T.red : T.border),
            ),
            child: Icon(Icons.bluetooth,
                color: isConnected ? T.red : T.greyDim, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(
                name.length > 20
                    ? '${name.substring(0, 20)}…'
                    : name,
                style: T.raj(13)),
            Row(children: [
              if (isConnected)
                Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: T.teal)),
              Text(sub, style: T.mono(8, color: subColor)),
              if (rssi != null) ...[
                const SizedBox(width: 6),
                Text('$rssi dBm',
                    style: T.mono(8, color: T.greyDim)),
              ],
            ]),
          ])),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              color: isConnected ? T.bg3 : T.red,
              child: Text(actionLabel,
                  style: T.mono(9, color: Colors.white)),
            ),
          ),
        ]),
      );
}