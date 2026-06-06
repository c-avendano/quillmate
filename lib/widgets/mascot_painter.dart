// widgets/mascot_painter.dart
//
// MascotPainter renders the mascot using Flutter's Canvas API.
// It is intentionally self-contained so it can be replaced by a
// sprite-sheet animation later with zero changes to the parent widget.
//
// HOW TO SWAP IN A SPRITE SHEET:
//   1. Remove MascotPainter entirely.
//   2. In mascot_widget.dart, replace the CustomPaint widget with an
//      Image.asset() wrapped in an AnimatedSwitcher or use the
//      `sprite` package to drive frame indices from the same
//      `animationValue` and `mood` inputs this painter already receives.
//
// The painter receives:
//   animationValue  – 0.0 → 1.0 oscillating value (drives bounce / blink)
//   mood            – current MascotMood (drives color / expression)

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/mascot_state.dart';

class MascotPainter extends CustomPainter {
  final double animationValue; // 0.0 – 1.0
  final MascotMood mood;

  const MascotPainter({
    required this.animationValue,
    required this.mood,
  });

  // -----------------------------------------------------------------
  // Color scheme per mood
  // -----------------------------------------------------------------
  Color get _bodyColor => switch (mood) {
        MascotMood.idle        => const Color(0xFF5B8CCC),
        MascotMood.typing      => const Color(0xFF4CAF50),
        MascotMood.encouraging => const Color(0xFFFF9800),
        MascotMood.frantic     => const Color(0xFFE53935),
      };

  Color get _accentColor => switch (mood) {
        MascotMood.idle        => const Color(0xFF3A6EA8),
        MascotMood.typing      => const Color(0xFF388E3C),
        MascotMood.encouraging => const Color(0xFFF57C00),
        MascotMood.frantic     => const Color(0xFFB71C1C),
      };

  // -----------------------------------------------------------------
  // Paint
  // -----------------------------------------------------------------
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Bob up and down: more energetic when typing, frantic when speeding.
    final bobAmplitude = switch (mood) {
      MascotMood.frantic => 10.0,
      MascotMood.typing  => 6.0,
      _                  => 2.5,
    };
    final bob = math.sin(animationValue * 2 * math.pi) * bobAmplitude;

    // Frantic: add a horizontal shake on top of the vertical bob.
    final shake = mood == MascotMood.frantic
        ? math.sin(animationValue * 8 * math.pi) * 4.0
        : 0.0;

    // Squash & stretch — subtle organic feel.
    final stretch = 1.0 + math.sin(animationValue * 2 * math.pi) * 0.04;
    final squash   = 1.0 / stretch;

    canvas.save();
    canvas.translate(cx + shake, cy + bob);
    canvas.scale(squash, stretch);

    // --- Body (rounded blob) ---
    final bodyPaint = Paint()
      ..color = _bodyColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(2, 6), width: 44, height: 18),
      shadowPaint,
    );

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 48, height: 52),
      bodyPaint,
    );

    // Belly highlight
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 6), width: 24, height: 26),
      Paint()..color = _bodyColor.withOpacity(0.4),
    );

    // --- Ears ---
    _drawEar(canvas, -18, -24, _accentColor);
    _drawEar(canvas,  18, -24, _accentColor);

    // --- Eyes ---
    final blinkProgress = _blinkProgress();
    _drawEye(canvas, -10, -6, blinkProgress);
    _drawEye(canvas,  10, -6, blinkProgress);

    // --- Mouth (expression changes with mood) ---
    _drawMouth(canvas);

    // --- Blush (encouraging only) ---
    if (mood == MascotMood.encouraging) {
      final blushPaint = Paint()
        ..color = Colors.pink.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-14, 4), width: 12, height: 7),
        blushPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(14, 4), width: 12, height: 7),
        blushPaint,
      );
    }

    canvas.restore();
  }

  void _drawEar(Canvas canvas, double x, double y, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 14, height: 18),
      paint,
    );
    // Inner ear
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 1), width: 7, height: 10),
      Paint()..color = Colors.pink.shade200.withOpacity(0.7),
    );
  }

  void _drawEye(Canvas canvas, double x, double y, double blinkProgress) {
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final eyeH = 10.0 * (1.0 - blinkProgress.clamp(0.0, 0.95));

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 10, height: eyeH.clamp(1.0, 10)),
      eyePaint,
    );

    if (eyeH > 3) {
      // Pupil
      canvas.drawCircle(
        Offset(x + 1, y + 1),
        3.5,
        Paint()..color = const Color(0xFF1A1A2E),
      );
      // Shine
      canvas.drawCircle(
        Offset(x + 2.5, y - 1),
        1.2,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawMouth(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    switch (mood) {
      case MascotMood.idle:
        // Neutral small smile.
        path.moveTo(-7, 10);
        path.quadraticBezierTo(0, 15, 7, 10);
      case MascotMood.typing:
        // Open excited mouth.
        path.moveTo(-8, 10);
        path.quadraticBezierTo(0, 18, 8, 10);
        canvas.drawPath(path, paint);
        final fillPath = Path()
          ..moveTo(-8, 10)
          ..quadraticBezierTo(0, 18, 8, 10)
          ..quadraticBezierTo(0, 13, -8, 10);
        canvas.drawPath(
          fillPath,
          Paint()
            ..color = const Color(0xFF1A1A2E).withOpacity(0.6)
            ..style = PaintingStyle.fill,
        );
        return;
      case MascotMood.frantic:
        // Wide-open panicked O mouth.
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, 13), width: 14, height: 12),
          Paint()
            ..color = const Color(0xFF1A1A2E).withOpacity(0.7)
            ..style = PaintingStyle.fill,
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, 13), width: 14, height: 12),
          paint..style = PaintingStyle.stroke,
        );
        return;
      case MascotMood.encouraging:
        // Big warm smile.
        path.moveTo(-10, 10);
        path.quadraticBezierTo(0, 20, 10, 10);
    }
    canvas.drawPath(path, paint);
  }

  // Blink every ~4 seconds (driven by animationValue cycling 0→1).
  // animationValue oscillates; we trigger a blink when it crosses 0.9.
  double _blinkProgress() {
    // Map animationValue to a blink curve: sharp spike near 0.92.
    final t = animationValue;
    if (t > 0.90 && t < 0.97) {
      return math.sin((t - 0.90) / 0.07 * math.pi);
    }
    return 0.0;
  }

  @override
  bool shouldRepaint(MascotPainter old) =>
      old.animationValue != animationValue || old.mood != mood;
}
