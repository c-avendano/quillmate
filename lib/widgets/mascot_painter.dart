// widgets/mascot_painter.dart
//
// Pure rendering — receives a MascotState enum value and an animation tick.
// No knowledge of keypresses, controllers, or timers.
//
// HOW TO SWAP IN A SPRITE SHEET:
//   Replace this file's CustomPainter with an Image.asset() driven by the
//   same (animationValue, state) inputs. MascotWidget passes both already.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/mascot_state.dart';

class MascotPainter extends CustomPainter {
  final double animationValue; // 0.0 – 1.0, repeating
  final MascotState state;

  const MascotPainter({required this.animationValue, required this.state});

  // -----------------------------------------------------------------
  // Color per FSM state
  // -----------------------------------------------------------------
  Color get _bodyColor => switch (state) {
        MascotState.idle        => const Color(0xFF5B8CCC), // blue
        MascotState.typingSlow  => const Color(0xFF4CAF50), // green
        MascotState.typingMedium => const Color(0xFFFFD700), // yellow
        MascotState.typingFast  => const Color(0xFFE53935), // red
        MascotState.encouraging => const Color(0xFFFF9800), // orange
      };

  Color get _accentColor => switch (state) {
        MascotState.idle        => const Color(0xFF3A6EA8),
        MascotState.typingSlow  => const Color(0xFF388E3C),
        MascotState.typingMedium => const Color(0xFFB8960C),
        MascotState.typingFast  => const Color(0xFFB71C1C),
        MascotState.encouraging => const Color(0xFFF57C00),
      };

  // -----------------------------------------------------------------
  // Paint
  // -----------------------------------------------------------------
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final bobAmplitude = switch (state) {
      MascotState.typingFast   => 10.0,
      MascotState.typingMedium => 7.5,
      MascotState.typingSlow   => 5.0,
      _                        => 2.5,
    };
    final bob   = math.sin(animationValue * 2 * math.pi) * bobAmplitude;
    final shake = state == MascotState.typingFast
        ? math.sin(animationValue * 8 * math.pi) * 4.0
        : 0.0;

    final stretch = 1.0 + math.sin(animationValue * 2 * math.pi) * 0.04;
    final squash  = 1.0 / stretch;

    canvas.save();
    canvas.translate(cx + shake, cy + bob);
    canvas.scale(squash, stretch);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(2, 6), width: 44, height: 18),
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 48, height: 52),
      Paint()..color = _bodyColor,
    );

    // Belly highlight
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 6), width: 24, height: 26),
      Paint()..color = _bodyColor.withOpacity(0.4),
    );

    _drawEar(canvas, -18, -24);
    _drawEar(canvas,  18, -24);

    final blink = _blinkProgress();
    _drawEye(canvas, -10, -6, blink);
    _drawEye(canvas,  10, -6, blink);

    _drawMouth(canvas);

    // Blush — encouraging only
    if (state == MascotState.encouraging) {
      final blush = Paint()
        ..color = Colors.pink.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: const Offset(-14, 4), width: 12, height: 7), blush);
      canvas.drawOval(Rect.fromCenter(center: const Offset( 14, 4), width: 12, height: 7), blush);
    }

    canvas.restore();
  }

  void _drawEar(Canvas canvas, double x, double y) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 14, height: 18),
      Paint()..color = _accentColor,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 1), width: 7, height: 10),
      Paint()..color = Colors.pink.shade200.withOpacity(0.7),
    );
  }

  void _drawEye(Canvas canvas, double x, double y, double blinkProgress) {
    final eyeH = (10.0 * (1.0 - blinkProgress.clamp(0.0, 0.95))).clamp(1.0, 10.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 10, height: eyeH),
      Paint()..color = Colors.white,
    );
    if (eyeH > 3) {
      canvas.drawCircle(Offset(x + 1, y + 1), 3.5, Paint()..color = const Color(0xFF1A1A2E));
      canvas.drawCircle(Offset(x + 2.5, y - 1), 1.2, Paint()..color = Colors.white);
    }
  }

  void _drawMouth(Canvas canvas) {
    final stroke = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    switch (state) {
      case MascotState.idle:
        canvas.drawPath(
          Path()..moveTo(-7, 10)..quadraticBezierTo(0, 15, 7, 10),
          stroke,
        );

      case MascotState.typingSlow:
        // Small relaxed smile — engaged but not rushed.
        canvas.drawPath(
          Path()..moveTo(-6, 10)..quadraticBezierTo(0, 14, 6, 10),
          stroke,
        );

      case MascotState.typingMedium:
        // Open excited mouth with fill — picking up pace.
        final arc = Path()..moveTo(-8, 10)..quadraticBezierTo(0, 18, 8, 10);
        canvas.drawPath(arc, stroke);
        canvas.drawPath(
          Path()..moveTo(-8, 10)..quadraticBezierTo(0, 18, 8, 10)..quadraticBezierTo(0, 13, -8, 10),
          Paint()..color = const Color(0xFF1A1A2E).withOpacity(0.6)..style = PaintingStyle.fill,
        );

      case MascotState.typingFast:
        // Wide-open panicked O
        final oval = Rect.fromCenter(center: const Offset(0, 13), width: 14, height: 12);
        canvas.drawOval(oval, Paint()..color = const Color(0xFF1A1A2E).withOpacity(0.7)..style = PaintingStyle.fill);
        canvas.drawOval(oval, stroke..style = PaintingStyle.stroke);

      case MascotState.encouraging:
        canvas.drawPath(
          Path()..moveTo(-10, 10)..quadraticBezierTo(0, 20, 10, 10),
          stroke,
        );
    }
  }

  double _blinkProgress() {
    final t = animationValue;
    if (t > 0.90 && t < 0.97) {
      return math.sin((t - 0.90) / 0.07 * math.pi);
    }
    return 0.0;
  }

  @override
  bool shouldRepaint(MascotPainter old) =>
      old.animationValue != animationValue || old.state != state;
}
