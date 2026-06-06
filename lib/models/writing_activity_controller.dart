// models/writing_activity_controller.dart
//
// WritingActivityController is the only class that drives MascotState.
// The mascot, editor, and status bar read from it but never write to it.
//
// ── How WPM is measured ──────────────────────────────────────────────────────
//
// We maintain a queue of keypress timestamps for the past 60 seconds.
// On every tick we compute:
//
//   characters_in_window = _recentPresses.length
//   wpm = (characters_in_window / 5) / (window_seconds / 60)
//       = characters_in_window / 5 * 60 / window_seconds
//
// The "÷ 5" is the standard prose approximation: one word ≈ 5 characters.
// The window shrinks naturally at the start of a session (we don't pad it),
// so WPM estimates are slightly lower for the first minute — this is fine
// for a writing companion; exact accuracy matters less than responsiveness.
//
// ── How WPM maps to MascotState ──────────────────────────────────────────────
//
//   currentWpm <  50% of targetWpm  → typingSlow
//   currentWpm in [50%, 100%)       → typingMedium
//   currentWpm >= 100% of targetWpm → typingFast
//
// Example with targetWpm = 40:
//   wpm  0–19  → typingSlow    (below 50% = below 20 wpm)
//   wpm 20–39  → typingMedium  (50%–99%)
//   wpm 40+    → typingFast    (at or above target)
//
// ── Public surface ───────────────────────────────────────────────────────────
//
//   mascotState          – current FSM state
//   currentWpm           – live WPM for display in status bar
//   encouragementMessage – non-empty only in MascotState.encouraging
//   keyCount             – total keypresses this session
//   recordKeyPress()     – called by WritingArea on every character change

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

import 'mascot_state.dart';
import 'settings_controller.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Rolling window used for WPM calculation (milliseconds).
/// 60 s gives stable readings; lower values react faster but fluctuate more.
const int kWpmWindowMs = 60000;

/// Seconds of silence before switching to [MascotState.encouraging].
const int kIdleSecondsBeforeEncouraging = 10;

/// Standard characters-per-word approximation used across the industry.
const double kCharsPerWord = 5.0;

// ---------------------------------------------------------------------------
// Encouraging messages
// ---------------------------------------------------------------------------

const List<String> _encouragements = [
  'Keep going! ✨',
  'You\'re doing great!',
  'Every word counts!',
  'Flow state unlocked 🔓',
  'The story writes itself!',
  'Brilliant thoughts ahead!',
  'Almost there — push on!',
  'Words are magic 🪄',
];

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class WritingActivityController extends ChangeNotifier {
  /// [settings] is injected so this controller never owns or creates it.
  /// WritingScreen creates both and passes settings in here.
  WritingActivityController({required SettingsController settings})
      : _settings = settings {
    // Re-evaluate mascot state whenever the target WPM changes, so the
    // mascot reacts immediately without waiting for the next keypress.
    _settings.addListener(_onSettingsChanged);
  }

  final SettingsController _settings;

  // ---- Public read-only state ----

  MascotState get mascotState => _mascotState;
  int get keyCount => _keyCount;
  int get currentWpm => _currentWpm;
  String get encouragementMessage => _encouragementMessage;

  // ---- Private FSM state ----

  MascotState _mascotState = MascotState.idle;
  int _keyCount = 0;
  int _currentWpm = 0;
  String _encouragementMessage = '';
  int _secondsIdle = 0;
  int _encouragementIndex = 0;

  /// Timestamps (ms since epoch) of keypresses within the rolling window.
  final Queue<int> _recentPresses = Queue();

  Timer? _ticker;

  // ---- Public API ----

  /// Called by WritingArea on every character insertion or deletion.
  void recordKeyPress() {
    _secondsIdle = 0;
    _keyCount++;

    final now = DateTime.now().millisecondsSinceEpoch;
    _recentPresses.addLast(now);
    _pruneWindow(now);

    _currentWpm = _calculateWpm(now);
    _transition(_wpmToState(_currentWpm), message: '');
    _ensureTickerRunning();
  }

  // ---- WPM calculation ────────────────────────────────────────────────────
  //
  // Example: 150 characters typed in 60 s
  //   wpm = (150 / 5) / (60000 / 60000) = 30 / 1.0 = 30 wpm
  //
  // Example: 90 characters typed in 30 s (early in a session)
  //   windowSecs = 30
  //   wpm = (90 / 5) / (30 / 60) = 18 / 0.5 = 36 wpm
  //
  // The window never exceeds kWpmWindowMs, so wpm is always
  // relative to the actual elapsed time, not a fixed 60 s assumption.

  int _calculateWpm(int nowMs) {
    if (_recentPresses.isEmpty) return 0;

    // Age of the oldest keypress still in the window.
    final windowMs = (nowMs - _recentPresses.first).clamp(1, kWpmWindowMs);
    final windowMinutes = windowMs / 60000.0;
    final words = _recentPresses.length / kCharsPerWord;
    return (words / windowMinutes).round();
  }

  // ---- WPM → MascotState mapping ─────────────────────────────────────────
  //
  // Thresholds are percentages of the user's target WPM.
  //
  //   Band         Range              Example at 40 wpm target
  //   ─────────────────────────────────────────────────────────
  //   typingSlow   < 50% of target    0–19 wpm
  //   typingMedium 50%–99% of target  20–39 wpm
  //   typingFast   ≥ 100% of target   40+ wpm
  //
  // To change the band boundaries, edit only this method.

  MascotState _wpmToState(int wpm) {
    final target = _settings.targetWpm;
    if (wpm >= target)           return MascotState.typingFast;
    if (wpm >= target * 0.5)     return MascotState.typingMedium;
    return MascotState.typingSlow;
  }

  // ---- Settings change ────────────────────────────────────────────────────

  void _onSettingsChanged() {
    // Target WPM changed — re-map the current speed to a (possibly new) state.
    if (_mascotState == MascotState.idle ||
        _mascotState == MascotState.encouraging) return;

    final newState = _wpmToState(_currentWpm);
    _transition(newState, message: '');
  }

  // ---- FSM transition ─────────────────────────────────────────────────────

  void _transition(MascotState next, {required String message}) {
    if (_mascotState == next && _encouragementMessage == message) return;
    _mascotState = next;
    _encouragementMessage = message;
    notifyListeners();
  }

  // ---- Ticker ─────────────────────────────────────────────────────────────

  void _ensureTickerRunning() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer _) {
    _secondsIdle++;
    final now = DateTime.now().millisecondsSinceEpoch;
    _pruneWindow(now);

    // Recompute WPM every second so the status bar stays current even when
    // the user pauses — keypresses from 61 s ago age out and WPM drops.
    _currentWpm = _calculateWpm(now);

    switch (_mascotState) {
      case MascotState.typingFast:
      case MascotState.typingMedium:
      case MascotState.typingSlow:
        final reeval = _wpmToState(_currentWpm);
        if (_secondsIdle >= kIdleSecondsBeforeEncouraging) {
          _encouragementIndex =
              (_encouragementIndex + 1) % _encouragements.length;
          _transition(
            MascotState.encouraging,
            message: _encouragements[_encouragementIndex],
          );
        } else if (reeval != _mascotState) {
          _transition(reeval, message: '');
        } else {
          // WPM changed even if state didn't — update the status bar.
          notifyListeners();
        }

      case MascotState.encouraging:
        break; // stays until the user types again

      case MascotState.idle:
        break;
    }
  }

  // ---- Helpers ────────────────────────────────────────────────────────────

  void _pruneWindow(int nowMs) {
    while (_recentPresses.isNotEmpty &&
        _recentPresses.first < nowMs - kWpmWindowMs) {
      _recentPresses.removeFirst();
    }
  }

  // ---- Lifecycle ──────────────────────────────────────────────────────────

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _ticker?.cancel();
    super.dispose();
  }
}
