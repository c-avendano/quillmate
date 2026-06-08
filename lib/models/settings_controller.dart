// models/settings_controller.dart
//
// Single source of truth for all user preferences.
//
// Theme: three presets (Light / Sepia / Dark), each bundling
//   background, canvas, text, chrome, chromeText, border, primary colours.
// Font: system font family name.
// Focus mode: hides chrome, enters OS fullscreen.
// Custom mascot: optional file path to a user-supplied sprite sheet.

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Theme presets
// ---------------------------------------------------------------------------

class EditorThemePreset {
  final String label;
  final Color  background;
  final Color  canvas;
  final Color  text;
  final Color  chrome;
  final Color  chromeText;
  final Color  border;
  final Color  primary;

  const EditorThemePreset({
    required this.label,
    required this.background,
    required this.canvas,
    required this.text,
    required this.chrome,
    required this.chromeText,
    required this.border,
    required this.primary,
  });
}

const List<EditorThemePreset> kEditorThemes = [
  EditorThemePreset(
    label:       'Light',
    background:  Color(0xFFFCF9F8),
    canvas:      Color(0xFFFFFFFF),
    text:        Color(0xFF1B1C1C),
    chrome:      Color(0xFFF6F3F2),
    chromeText:  Color(0xFF3D4947),
    border:      Color(0xFFBCC9C6),
    primary:     Color(0xFF006A62),
  ),
  EditorThemePreset(
    label:       'Sepia',
    background:  Color(0xFFF0E8D8),
    canvas:      Color(0xFFFAF3E4),
    text:        Color(0xFF2C1A0E),
    chrome:      Color(0xFFE8D9BE),
    chromeText:  Color(0xFF6B4C30),
    border:      Color(0xFFD4C4A0),
    primary:     Color(0xFF5D4037),
  ),
  EditorThemePreset(
    label:       'Dark',
    background:  Color(0xFF111827),
    canvas:      Color(0xFF1E2433),
    text:        Color(0xFFE2E2E2),
    chrome:      Color(0xFF0D1117),
    chromeText:  Color(0xFF9CA3AF),
    border:      Color(0xFF2D3748),
    primary:     Color(0xFF5FDACC),
  ),
];

// ---------------------------------------------------------------------------
// WPM constants
// ---------------------------------------------------------------------------

const int kDefaultTargetWpm = 40;
const int kMinTargetWpm     = 20;
const int kMaxTargetWpm     = 120;

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class SettingsController extends ChangeNotifier {

  // ---- Theme ----

  EditorThemePreset _theme = kEditorThemes.first;
  EditorThemePreset get theme => _theme;

  Color get backgroundColor => _theme.background;
  Color get canvasColor      => _theme.canvas;
  Color get textColor        => _theme.text;
  Color get chromeColor      => _theme.chrome;
  Color get chromeTextColor  => _theme.chromeText;
  Color get borderColor      => _theme.border;
  Color get primaryColor     => _theme.primary;

  void setTheme(EditorThemePreset preset) {
    if (_theme == preset) return;
    _theme = preset;
    notifyListeners();
  }

  // ---- Font ----

  String _fontFamily = 'sans-serif';
  String get fontFamily => _fontFamily;

  void setFontFamily(String family) {
    if (_fontFamily == family) return;
    _fontFamily = family;
    notifyListeners();
  }

  // ---- Target WPM ----

  int _targetWpm = kDefaultTargetWpm;
  int get targetWpm => _targetWpm;

  void setTargetWpm(int wpm) {
    final v = wpm.clamp(kMinTargetWpm, kMaxTargetWpm);
    if (v == _targetWpm) return;
    _targetWpm = v;
    notifyListeners();
  }

  // ---- Focus mode ----

  bool _focusMode = false;
  bool get focusMode => _focusMode;

  void toggleFocusMode() {
    _focusMode = !_focusMode;
    notifyListeners();
  }

  void setFocusMode(bool value) {
    if (_focusMode == value) return;
    _focusMode = value;
    notifyListeners();
  }

  // ---- Custom mascot ----
  //
  // When set, MascotWidget loads this file path instead of bundled assets.
  // The file must be a horizontal-strip PNG sprite sheet.

  String? _customMascotPath;
  String? get customMascotPath => _customMascotPath;

  int    _customFrameCount  = 4;
  double _customFrameWidth  = 80;
  double _customFrameHeight = 80;

  int    get customFrameCount  => _customFrameCount;
  double get customFrameWidth  => _customFrameWidth;
  double get customFrameHeight => _customFrameHeight;

  void setCustomMascot({
    required String path,
    int    frameCount  = 4,
    double frameWidth  = 80,
    double frameHeight = 80,
  }) {
    _customMascotPath  = path;
    _customFrameCount  = frameCount;
    _customFrameWidth  = frameWidth;
    _customFrameHeight = frameHeight;
    notifyListeners();
  }

  void clearCustomMascot() {
    _customMascotPath = null;
    notifyListeners();
  }
}
