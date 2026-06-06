// widgets/mascot_widget.dart
//
// MascotWidget is the visible companion character.
//
// Responsibilities:
//   • Wrap MascotPainter in an AnimationController that drives the
//     animation speed based on current mood.
//   • Show/hide an encouraging message bubble.
//   • Handle drag so the user can reposition it anywhere on screen.
//
// The widget is fully self-contained: it only needs a MascotState
// passed from above. No global state or providers required.

import 'package:flutter/material.dart';

import '../models/mascot_state.dart';
import 'mascot_painter.dart';

/// Size of the mascot canvas.
const double kMascotSize = 80.0;

class MascotWidget extends StatefulWidget {
  final MascotState state;

  const MascotWidget({super.key, required this.state});

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // -----------------------------------------------------------------
  // Animation speed per mood
  // -----------------------------------------------------------------
  static const Map<MascotMood, Duration> _durations = {
    MascotMood.idle:        Duration(milliseconds: 2800),
    MascotMood.typing:      Duration(milliseconds: 700),
    MascotMood.encouraging: Duration(milliseconds: 1600),
    MascotMood.frantic:     Duration(milliseconds: 300),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durations[widget.state.mood]!,
    )..repeat();
  }

  @override
  void didUpdateWidget(MascotWidget old) {
    super.didUpdateWidget(old);
    if (old.state.mood != widget.state.mood) {
      // Smoothly transition animation speed on mood change.
      _controller.duration = _durations[widget.state.mood];
      // Keep the animation running without a visible jump.
      if (!_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Encouragement bubble (encouraging) or slow-down nudge (frantic).
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: widget.state.mood == MascotMood.encouraging
              ? _EncouragementBubble(
                  key: ValueKey(widget.state.encouragementMessage),
                  message: widget.state.encouragementMessage,
                  color: const Color(0xFFFF9800),
                )
              : widget.state.mood == MascotMood.frantic
                  ? const _EncouragementBubble(
                      key: ValueKey('frantic'),
                      message: 'Slow down! 😅',
                      color: Color(0xFFE53935),
                    )
                  : const SizedBox.shrink(),
        ),
        const SizedBox(height: 4),

        // The mascot itself.
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: MascotPainter(
                animationValue: _controller.value,
                mood: widget.state.mood,
              ),
              size: const Size(kMascotSize, kMascotSize),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Encouragement speech bubble
// ---------------------------------------------------------------------------

class _EncouragementBubble extends StatelessWidget {
  final String message;
  final Color color;

  const _EncouragementBubble({super.key, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
