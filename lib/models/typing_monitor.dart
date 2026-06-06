// models/typing_monitor.dart
//
// TypingMonitor is the single source of truth for writing activity.
// It is a plain Dart class (a ChangeNotifier) — no widget dependencies.
//
// Responsibilities:
//   • Accept key-press notifications from the editor
//   • Run a countdown timer to detect idle periods
//   • Cycle through encouraging messages
//   • Expose a MascotState that widgets listen to

import 'dart:async';
import 'package:flutter/foundation.dart';

import 'mascot_state.dart';

// ---------------------------------------------------------------------------
// Encouraging messages — extend this list freely.
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

class TypingMonitor extends ChangeNotifier {
  // -----------------------------------------------------------------
  // Configuration
  // -----------------------------------------------------------------

  /// Seconds of silence before switching to [MascotMood.encouraging].
  static const int encourageAfterSeconds = 10;

  /// Seconds of encouraging state before returning to [MascotMood.idle]
  /// (when the user still hasn't typed).
  static const int idleAfterEncouragingSeconds = 30;

  // -----------------------------------------------------------------
  // Internal state
  // -----------------------------------------------------------------

  MascotState _state = const MascotState.initial();

  /// Fires every second to count down toward idle/encouraging transitions.
  Timer? _idleTimer;

  /// Seconds since the last key-press.
  int _secondsIdle = 0;

  int _encouragementIndex = 0;

  // -----------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------

  MascotState get state => _state;

  /// Call this whenever the user presses a key in the writing area.
  void onKeyPress() {
    _secondsIdle = 0;
    final newKeyCount = _state.keyCount + 1;

    _state = _state.copyWith(
      mood: MascotMood.typing,
      encouragementMessage: '',
      keyCount: newKeyCount,
    );

    // (Re)start the idle countdown.
    _startIdleTimer();

    notifyListeners();
  }

  // -----------------------------------------------------------------
  // Timer management
  // -----------------------------------------------------------------

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer _) {
    _secondsIdle++;

    if (_secondsIdle >= encourageAfterSeconds &&
        _state.mood != MascotMood.encouraging) {
      // Transition to encouraging state.
      _encouragementIndex =
          (_encouragementIndex + 1) % _encouragements.length;
      _state = _state.copyWith(
        mood: MascotMood.encouraging,
        encouragementMessage: _encouragements[_encouragementIndex],
      );
      notifyListeners();
    }
    // Optional: return to idle after a longer silence.
    // (Currently we stay in encouraging until the user types again.)
  }

  // -----------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }
}
