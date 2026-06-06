// models/settings_controller.dart
//
// All user preferences in one place.
//
// Appearance:
//   theme      — one of three presets (White, Black, Sepia)
//                each preset carries a background colour and a text colour
//                so the editor is always readable without extra logic
//   fontFamily — any font installed on the system
//
// Other settings:
//   targetWpm  — WPM target for the mascot FSM
//   focusMode  — hides chrome and centres the editor column

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Theme presets
// ---------------------------------------------------------------------------
//
// A preset bundles background + text colour so callers never have to
// derive one from the other. Add new presets here; nothing else changes.

class EditorThemePreset {
  final String label;
  final Color  background;
  final Color  text;
  const EditorThemePreset({
    required this.label,
    required this.background,
    required this.text,
  });
}

const List<EditorThemePreset> kEditorThemes = [
  EditorThemePreset(
    label:      'Black',
    background: Color(0xFF1A1A2E),
    text:       Color(0xFFE2E2E2),
  ),
  EditorThemePreset(
    label:      'White',
    background: Color(0xFFF5F5F5),
    text:       Color(0xFF1A1A1A),
  ),
  EditorThemePreset(
    label:      'Sepia',
    background: Color(0xFFF4ECD8),
    text:       Color(0xFF3B2F2F),
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

  // Convenience getters so widgets don't need to know about the preset struct.
  Color get backgroundColor => _theme.background;
  Color get textColor        => _theme.text;

  void setTheme(EditorThemePreset preset) {
    if (_theme == preset) return;
    _theme = preset;
    notifyListeners();
  }

  // ---- Font family ----
  //
  // Stores whatever string the user picks from the dropdown.
  // An empty string means "use the platform default" — Flutter resolves
  // 'sans-serif' and 'serif' generics automatically, so they are safe fallbacks.

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
