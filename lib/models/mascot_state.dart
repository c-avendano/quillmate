// models/mascot_state.dart
//
// FSM states for the mascot. Every visual and animation decision derives
// from this single value — nothing else leaks into the display layer.
//
// State transition diagram:
//
//   ┌──────────────────────────────────────────────────────────────┐
//   │                                                              │
//   │  [idle] ───── keypress ────────────────► [typingSlow]        │
//   │     ▲                                        │               │
//   │     │                              speed ≥ 50% target        │
//   │     │                                        │               │
//   │  10 s idle                          ◄────────┴──► [typingMedium]
//   │     │                                        │               │
//   │     │                              speed ≥ 100% target       │
//   │     │                                        │               │
//   │  [encouraging] ◄── 10 s idle ───────────► [typingFast]       │
//   │        └──────────── keypress ──────────► [typingSlow]        │
//   │                                                              │
//   └──────────────────────────────────────────────────────────────┘
//
// Speed bands (relative to user's target WPM):
//   < 50%          → typingSlow
//   50% – <100%    → typingMedium
//   ≥ 100%         → typingFast

enum MascotState {
  /// No recent typing activity.
  idle,

  /// Typing below 50% of target WPM.
  typingSlow,

  /// Typing between 50% and 100% of target WPM.
  typingMedium,

  /// Typing at or above target WPM.
  typingFast,

  /// Silent for 10 s after typing — mascot shows an encouraging message.
  encouraging,
}
