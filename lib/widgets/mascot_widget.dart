// widgets/mascot_widget.dart
//
// MascotWidget is a pure display component.
// It receives a MascotState and an optional message string.
// It knows nothing about keyboard events, timers, or the controller.
//
// Rendering strategy:
//   1. Look up the SpriteAnimationConfig for the current MascotState.
//   2. Pass it to SpriteAnimationWidget, which loads the sheet and animates.
//   3. While the image is loading (or if the asset is missing), show the
//      MascotPainter placeholder so the mascot is always visible.
//
// The fallback is permanent until a real asset is placed at the expected path.
// No code changes are needed when assets are added — Flutter's image cache
// picks them up on the next cold start.

import 'package:flutter/material.dart';

import '../models/mascot_state.dart';
import '../sprites/sprite_animation_config.dart';
import 'mascot_painter.dart';
import 'sprite_animation_widget.dart';

/// Rendered size of the mascot on screen.
const double kMascotSize = 80.0;
const Size kMascotDisplaySize = Size(kMascotSize, kMascotSize);

class MascotWidget extends StatelessWidget {
  final MascotState state;

  /// Message shown in the speech bubble above the mascot.
  /// Empty string = no bubble.
  final String message;

  const MascotWidget({
    super.key,
    required this.state,
    this.message = '',
  });

  Color get _bubbleColor => switch (state) {
        MascotState.typingFast  => const Color(0xFFE53935),
        MascotState.encouraging => const Color(0xFFFF9800),
        _                       => Colors.transparent,
      };

  @override
  Widget build(BuildContext context) {
    final config = kMascotAnimations[state]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speech bubble — fades in/out when message changes.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: message.isNotEmpty
              ? _Bubble(
                  key: ValueKey(message),
                  message: message,
                  color: _bubbleColor,
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 4),

        // Sprite animation with a placeholder painted underneath.
        // The Stack lets the placeholder show through until the image loads.
        SizedBox(
          width: kMascotSize,
          height: kMascotSize,
          child: Stack(
            children: [
              // Layer 1: CustomPainter placeholder (always present, renders
              // instantly). Covered by the sprite once the image is ready.
              _PlaceholderMascot(state: state),

              // Layer 2: Sprite animation (transparent until image loads).
              SpriteAnimationWidget(
                // Key forces a clean rebuild when the state changes so the
                // Ticker resets its elapsed time — prevents a stale frame
                // from a previous clip showing for one tick.
                key: ValueKey(state),
                config: config,
                displaySize: kMascotDisplaySize,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder — wraps the existing CustomPainter so it animates on its own
// ---------------------------------------------------------------------------

class _PlaceholderMascot extends StatefulWidget {
  final MascotState state;
  const _PlaceholderMascot({required this.state});

  @override
  State<_PlaceholderMascot> createState() => _PlaceholderMascotState();
}

class _PlaceholderMascotState extends State<_PlaceholderMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const Map<MascotState, Duration> _durations = {
    MascotState.idle:        Duration(milliseconds: 2800),
    MascotState.typingSlow:  Duration(milliseconds: 900),
    MascotState.typingMedium: Duration(milliseconds: 550),
    MascotState.typingFast:  Duration(milliseconds: 300),
    MascotState.encouraging: Duration(milliseconds: 1600),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durations[widget.state]!,
    )..repeat();
  }

  @override
  void didUpdateWidget(_PlaceholderMascot old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _controller.duration = _durations[widget.state];
      if (!_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: MascotPainter(
          animationValue: _controller.value,
          state: widget.state,
        ),
        size: kMascotDisplaySize,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Speech bubble
// ---------------------------------------------------------------------------

class _Bubble extends StatelessWidget {
  final String message;
  final Color color;

  const _Bubble({super.key, required this.message, required this.color});

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
