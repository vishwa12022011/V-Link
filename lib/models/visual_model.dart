import 'package:flutter/material.dart';

class VisualModel extends ChangeNotifier {
  double _opacity = 0.85;
  double _glowIntensity = 0.5;
  double _hudScale = 1.0;
  int _accentIndex = 0;
  bool _highFidelity = true;
  bool _brutalistGrid = false;
  bool _dynamicScale = true;
  bool _useOrbitron = true;

  // Getters
  double get opacity => _opacity;
  double get glowIntensity => _glowIntensity;
  double get hudScale => _hudScale;
  int get accentIndex => _accentIndex;
  bool get highFidelity => _highFidelity;
  bool get brutalistGrid => _brutalistGrid;
  bool get dynamicScale => _dynamicScale;
  bool get useOrbitron => _useOrbitron;

  // Setters (These automatically handle notifying the UI safely)
  set opacity(double value) {
    if (_opacity != value) {
      _opacity = value;
      notifyListeners();
    }
  }

  set glowIntensity(double value) {
    if (_glowIntensity != value) {
      _glowIntensity = value;
      notifyListeners();
    }
  }

  set hudScale(double value) {
    if (_hudScale != value) {
      _hudScale = value;
      notifyListeners();
    }
  }

  set accentIndex(int value) {
    if (_accentIndex != value) {
      _accentIndex = value;
      notifyListeners();
    }
  }

  set highFidelity(bool value) {
    if (_highFidelity != value) {
      _highFidelity = value;
      notifyListeners();
    }
  }

  set brutalistGrid(bool value) {
    if (_brutalistGrid != value) {
      _brutalistGrid = value;
      notifyListeners();
    }
  }

  set dynamicScale(bool value) {
    if (_dynamicScale != value) {
      _dynamicScale = value;
      notifyListeners();
    }
  }

  set useOrbitron(bool value) {
    if (_useOrbitron != value) {
      _useOrbitron = value;
      notifyListeners();
    }
  }

  static final List<Color> accents = [
    const Color(0xFFFF4655),
    const Color(0xFF00E6C3),
    const Color(0xFFF2C94C),
    const Color(0xFF9B51E0),
    const Color(0xFF2D9CDB),
    const Color(0xFF27AE60),
  ];

  void reset() {
    _opacity = 0.85;
    _glowIntensity = 0.5;
    _hudScale = 1.0;
    _accentIndex = 0;
    _highFidelity = true;
    _brutalistGrid = false;
    _dynamicScale = true;
    _useOrbitron = true;
    notifyListeners();
  }
}