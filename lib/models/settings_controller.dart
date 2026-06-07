// models/settings_controller.dart
//
// All user preferences in one place.
//
// Appearance:
//   theme      — White / Black / Sepia (each bundles background + text colour)
//   fontFamily — system font family name
//
// Other:
//   targetWpm  — WPM target for mascot FSM bands
//   focusMode  — hides toolbar/status bar and enters OS fullscreen

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Theme presets
// ---------------------------------------------------------------------------
//
// Each preset carries:
//   background — the editor / window background colour
//   text       — the main prose colour (high contrast on background)
//   chrome     — the colour for the status bar / toolbar overlay
//
// The markdown highlighter reads the text colour's luminance and
// automatically picks a matching syntax-colour palette.

class EditorThemePreset {
  final String label;
  final Color  background;
  final Color  text;
  final Color  chrome;        // status bar / toolbar background tint
  final Color  chromeText;    // labels inside the chrome
  const EditorThemePreset({
    required this.label,
    required this.background,
    required this.text,
    required this.chrome,
    required this.chromeText,
  });
}

const List<EditorThemePreset> kEditorThemes = [
  // Dark — the original night-writing theme.
  EditorThemePreset(
    label:       'Dark',
    background:  Color(0xFF1A1A2E),
    text:        Color(0xFFE2E2E2),
    chrome:      Color(0xFF12122A),
    chromeText:  Color(0xAAE2E2E2),
  ),
  // White — clean paper look; dark ink text for readability.
  EditorThemePreset(
    label:       'White',
    background:  Color(0xFFFFFFFF),
    text:        Color(0xFF1C1C1C),
    chrome:      Color(0xFFEEEEEE),
    chromeText:  Color(0xFF555555),
  ),
  // Sepia — warm parchment; dark brown ink.
  EditorThemePreset(
    label:       'Sepia',
    background:  Color(0xFFF5ECD7),
    text:        Color(0xFF2C1A0E),
    chrome:      Color(0xFFE8D9BE),
    chromeText:  Color(0xFF6B4C30),
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

  // ---- Appearance ----

  EditorThemePreset _theme = kEditorThemes.first;
  EditorThemePreset get theme => _theme;

  Color get backgroundColor => _theme.background;
  Color get textColor        => _theme.text;
  Color get chromeColor      => _theme.chrome;
  Color get chromeTextColor  => _theme.chromeText;

  void setTheme(EditorThemePreset preset) {
    if (_theme == preset) return;
    _theme = preset;
    notifyListeners();
  }

  // ---- Font family ----

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
}
