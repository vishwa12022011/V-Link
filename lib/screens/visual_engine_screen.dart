import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';

class VisualEngineScreen extends StatelessWidget {
  const VisualEngineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VisualModel>();
    return Scaffold(
      backgroundColor: T.bg0,
      body: CustomScrollView(slivers: [
        const SliverToBoxAdapter(
            child: VHeader(
          title: 'VISUAL ENGINE',
          sub: 'INTERFACE CONFIGURATION v2.04',
        )),

        // Global appearance
        SliverToBoxAdapter(
            child: _Sec(
                'GLOBAL APPEARANCE',
                Column(children: [
                  _Slider(
                      'INTERFACE OPACITY',
                      vm.opacity,
                      '${(vm.opacity * 100).round()}%',
                      (v) => context.read<VisualModel>()
                        ..opacity = v
                        ..notifyAll()),
                  _Slider(
                      'GLOW INTENSITY',
                      vm.glowIntensity,
                      '${(vm.glowIntensity * 100).round()}%',
                      (v) => context.read<VisualModel>()
                        ..glowIntensity = v
                        ..notifyAll()),
                  _Slider(
                      'HUD SCALE',
                      (vm.hudScale - 0.5) / 1.5,
                      '${vm.hudScale.toStringAsFixed(2)}×',
                      (v) => context.read<VisualModel>()
                        ..hudScale = 0.5 + v * 1.5
                        ..notifyAll()),
                ]))),

        // Accent colours
        SliverToBoxAdapter(
            child: _Sec(
                'SYSTEM ACCENT',
                Row(
                  children: List.generate(
                      VisualModel.accents.length,
                      (i) => GestureDetector(
                            onTap: () => context.read<VisualModel>()
                              ..accentIndex = i
                              ..notifyAll(),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: VisualModel.accents[i],
                                border: Border.all(
                                  color: vm.accentIndex == i
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: vm.accentIndex == i
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                          )),
                ))),

        // Rendering FX
        SliverToBoxAdapter(
            child: _Sec(
                'RENDERING & FX',
                Column(children: [
                  _Toggle(
                      'High Fidelity Shaders',
                      'Enable real-time ripple & blur effects',
                      vm.highFidelity,
                      (v) => context.read<VisualModel>()
                        ..highFidelity = v
                        ..notifyAll()),
                  _Toggle(
                      'Brutalist Grid',
                      'Display alignment guides in editor',
                      vm.brutalistGrid,
                      (v) => context.read<VisualModel>()
                        ..brutalistGrid = v
                        ..notifyAll()),
                  _Toggle(
                      'Dynamic Scaling',
                      'Resizes buttons based on touch pressure',
                      vm.dynamicScale,
                      (v) => context.read<VisualModel>()
                        ..dynamicScale = v
                        ..notifyAll()),
                ]))),

        // Typography
        SliverToBoxAdapter(
            child: _Sec(
                'DATA TYPOGRAPHY',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _FontChip(
                          'TUNGSTEN',
                          vm.useOrbitron,
                          () => context.read<VisualModel>()
                            ..useOrbitron = true
                            ..notifyAll()),
                      const SizedBox(width: 8),
                      _FontChip(
                          'DIN NEXT',
                          !vm.useOrbitron,
                          () => context.read<VisualModel>()
                            ..useOrbitron = false
                            ..notifyAll()),
                    ]),
                    const SizedBox(height: 12),
                    Text(
                        'Typography effects readability in high-intensity combat scenarios.',
                        style: T.raj(12, color: T.grey)),
                  ],
                ))),

        // Buttons
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Row(children: [
            Expanded(
                child: GestureDetector(
              onTap: () => context.read<VisualModel>().reset(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    color: T.bg2, border: Border.all(color: T.border)),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.login, color: T.grey, size: 14),
                  const SizedBox(width: 8),
                  Text('RESET DEFAULT', style: T.raj(13, color: T.grey)),
                ]),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: T.red,
                  content: Text('Visual config applied.', style: T.raj(13)))),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: T.red,
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  Text('APPLY CHANGES', style: T.raj(14)),
                ]),
              ),
            )),
          ]),
        )),
      ]),
    );
  }
}

class _Sec extends StatelessWidget {
  final String title;
  final Widget child;
  const _Sec(this.title, this.child);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: T.mono(9, color: T.grey).copyWith(letterSpacing: 2)),
          const SizedBox(height: 12),
          Container(
              padding: const EdgeInsets.all(16),
              decoration: T.panel(),
              child: child),
        ]),
      );
}

class _Slider extends StatelessWidget {
  final String label, display;
  final double value;
  final ValueChanged<double> onChanged;
  const _Slider(this.label, this.value, this.display, this.onChanged);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: T.raj(13, color: T.grey)),
            Text(display, style: T.mono(10, color: T.red)),
          ]),
          const SizedBox(height: 6),
          Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: onChanged,
              activeColor: T.red,
              inactiveColor: T.border),
        ]),
      );
}

class _Toggle extends StatelessWidget {
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle(this.label, this.sub, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: T.bg3,
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label, style: T.raj(14, color: T.white)),
                const SizedBox(height: 2),
                Text(sub, style: T.mono(9, color: T.greyDim)),
              ])),
          Switch(
              value: value,
              onChanged: onChanged,
              activeColor: T.red,
              inactiveThumbColor: T.greyDim,
              inactiveTrackColor: T.bg0),
        ]),
      );
}

class _FontChip extends StatelessWidget {
  final String label;
  final bool sel;
  final VoidCallback onTap;
  const _FontChip(this.label, this.sel, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? T.red : T.bg3,
            border: Border.all(color: sel ? T.red : T.border),
          ),
          child:
              Text(label, style: T.raj(14, color: sel ? Colors.white : T.grey)),
        ),
      );
}

// Extension to allow chaining notifyListeners
extension _VM on VisualModel {
  void notifyAll() => notifyListeners();
}
