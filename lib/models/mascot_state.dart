// models/mascot_state.dart
//
// Pure data layer — no Flutter imports, easy to unit-test.
//
// MascotMood drives both the animation speed and the visual appearance.
// Adding a new mood (e.g. "Celebrating") means adding one enum value and
// handling it in mascot_widget.dart and mascot_painter.dart.

/// The four moods the mascot can express.
enum MascotMood {
  /// User has not typed recently and has not been idle long enough
  /// to trigger an encouraging message.
  idle,

  /// User is actively typing at a comfortable pace. Animations run faster.
  typing,

  /// User has been idle for [TypingMonitor.encourageAfterSeconds] seconds.
  /// A motivational bubble is shown above the mascot.
  encouraging,

  /// User is typing very fast (≥ [TypingMonitor.franticThreshold] keypresses
  /// in a 10-second rolling window). Mascot turns red and vibrates.
  frantic,
}

/// Immutable snapshot of mascot state passed down the widget tree.
class MascotState {
  final MascotMood mood;

  /// The message shown in the bubble when mood == encouraging.
  /// Empty string when no bubble should be visible.
  final String encouragementMessage;

  /// Total key-presses recorded in this session (displayed in the status bar).
  final int keyCount;

  const MascotState({
    required this.mood,
    required this.encouragementMessage,
    required this.keyCount,
  });

  /// Convenience constructor for the initial state.
  const MascotState.initial()
      : mood = MascotMood.idle,
        encouragementMessage = '',
        keyCount = 0;

  MascotState copyWith({
    MascotMood? mood,
    String? encouragementMessage,
    int? keyCount,
  }) {
    return MascotState(
      mood: mood ?? this.mood,
      encouragementMessage: encouragementMessage ?? this.encouragementMessage,
      keyCount: keyCount ?? this.keyCount,
    );
  }
}
