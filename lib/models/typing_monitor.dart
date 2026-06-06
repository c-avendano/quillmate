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
import 'dart:collection';
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

  /// Rolling window size in milliseconds for speed measurement.
  static const int speedWindowMs = 10000;

  /// Keypresses within [speedWindowMs] that trigger [MascotMood.frantic].
  /// 15 keys / 10 s ≈ 90 WPM — comfortable fast typing sits below this. This value was 15 before, titan changed it
  static const int franticThreshold = 30;

  // -----------------------------------------------------------------
  // Internal state
  // -----------------------------------------------------------------

  MascotState _state = const MascotState.initial();

  /// Fires every second to count down toward idle/encouraging transitions.
  Timer? _idleTimer;

  /// Seconds since the last key-press.
  int _secondsIdle = 0;

  int _encouragementIndex = 0;

  /// Timestamps (ms since epoch) of recent keypresses within the rolling window.
  /// Using a Queue so we can efficiently drop old entries from the front.
  final Queue<int> _recentPresses = Queue();

  // -----------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------

  MascotState get state => _state;

  /// Call this whenever the user presses a key in the writing area.
  void onKeyPress() {
    _secondsIdle = 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Record this keypress and drop anything outside the rolling window.
    _recentPresses.addLast(now);
    while (_recentPresses.first < now - speedWindowMs) {
      _recentPresses.removeFirst();
    }

    final newKeyCount = _state.keyCount + 1;
    final isFrantic = _recentPresses.length >= franticThreshold;

    _state = _state.copyWith(
      mood: isFrantic ? MascotMood.frantic : MascotMood.typing,
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

    // Re-evaluate frantic state as the window slides (keypresses age out).
    if (_state.mood == MascotMood.frantic || _state.mood == MascotMood.typing) {
      final now = DateTime.now().millisecondsSinceEpoch;
      while (_recentPresses.isNotEmpty &&
          _recentPresses.first < now - speedWindowMs) {
        _recentPresses.removeFirst();
      }
      final stillFrantic = _recentPresses.length >= franticThreshold;
      if (_state.mood == MascotMood.frantic && !stillFrantic) {
        _state = _state.copyWith(mood: MascotMood.typing);
        notifyListeners();
      }
    }

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
