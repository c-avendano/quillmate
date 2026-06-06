// widgets/writing_screen.dart
//
// WritingScreen is the single screen of the application.
//
// Layout:
//   ┌──────────────────────────────────────────────────────┐
//   │  [status bar: word count / key count / mood]         │
//   ├──────────────────────────────────────────────────────┤
//   │                                                      │
//   │              WritingArea (fills screen)              │
//   │                                                      │
//   └──────────────────────────────────────────────────────┘
//   + MascotWidget floating overlay (draggable, anywhere)
//
// State management: plain setState() + ChangeNotifier.
// WritingScreen owns the TypingMonitor and listens to it.
// When state changes, only the mascot overlay and status bar rebuild —
// the WritingArea is never rebuilt (its subtree is stable).

import 'package:flutter/material.dart';

import '../models/mascot_state.dart';
import '../models/typing_monitor.dart';
import 'mascot_widget.dart';
import 'writing_area.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  final TypingMonitor _monitor = TypingMonitor();

  // Initial mascot position (top-center-ish, adjusts after first layout).
  Offset _mascotPosition = const Offset(60, 60);
  bool _positionInitialized = false;

  @override
  void initState() {
    super.initState();
    _monitor.addListener(_onMonitorChanged);
  }

  void _onMonitorChanged() {
    // Rebuild only when the mascot state changes.
    setState(() {});
  }

  @override
  void dispose() {
    _monitor.removeListener(_onMonitorChanged);
    _monitor.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Centre the mascot horizontally after first layout.
    if (!_positionInitialized && size.width > 0) {
      _mascotPosition = Offset(size.width / 2 - kMascotSize / 2, 30);
      _positionInitialized = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // ---- Main editor layout ----
          Column(
            children: [
              _StatusBar(state: _monitor.state),
              const Divider(height: 1, color: Color(0x22FFFFFF)),
              Expanded(
                child: WritingArea(onKeyPress: _monitor.onKeyPress),
              ),
            ],
          ),

          // ---- Draggable mascot overlay ----
          Positioned(
            left: _mascotPosition.dx,
            top: _mascotPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  // Clamp so the mascot can't be dragged off-screen.
                  _mascotPosition = Offset(
                    (_mascotPosition.dx + details.delta.dx)
                        .clamp(0, size.width - kMascotSize),
                    (_mascotPosition.dy + details.delta.dy)
                        .clamp(0, size.height - kMascotSize - 60),
                  );
                });
              },
              child: MascotWidget(state: _monitor.state),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status bar
// ---------------------------------------------------------------------------

class _StatusBar extends StatelessWidget {
  final MascotState state;

  const _StatusBar({required this.state});

  String get _moodLabel => switch (state.mood) {
        MascotMood.idle        => 'Idle',
        MascotMood.typing      => 'Writing ✍️',
        MascotMood.encouraging => 'Encouraging 💛',
        MascotMood.frantic     => 'Frantic 🔥',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF12122A),
      child: Row(
        children: [
          // App name
          const Text(
            'QuillMate',
            style: TextStyle(
              color: Color(0xFF7EC8E3),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          // Key count
          Text(
            'Keys: ${state.keyCount}',
            style: const TextStyle(color: Color(0x88E2E2E2), fontSize: 11),
          ),
          const SizedBox(width: 20),
          // Mood indicator
          Text(
            _moodLabel,
            style: const TextStyle(color: Color(0x88E2E2E2), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
