// widgets/sprite_animation_widget.dart
//
// SpriteAnimationWidget renders one animation clip from a sprite sheet.
//
// Responsibilities:
//   • Load the image asset once (Flutter's image cache handles deduplication).
//   • Advance the frame index at the configured FPS using a Ticker.
//   • Clip and draw the correct frame via SpriteAnimationPainter.
//   • React to config changes:
//       – Different assetPath → reset frame, reload image.
//       – Different fps only  → picked up automatically on the next tick.
//
// Why a Ticker instead of AnimationController?
//   AnimationController drives a 0→1 curve, which is ideal for tweens.
//   Frame-based animation needs wall-clock elapsed time to advance discrete
//   indices at a specific FPS — a Ticker provides raw elapsed Duration directly.
//
// This widget is self-contained and has no dependency on MascotState.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../sprites/sprite_animation_config.dart';
import '../sprites/sprite_sheet.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

class SpriteAnimationWidget extends StatefulWidget {
  final SpriteAnimationConfig config;

  /// The size at which the mascot is displayed on screen.
  /// Each frame is scaled to fill this rect (aspect ratio not enforced here;
  /// make frameWidth == frameHeight for square mascots).
  final Size displaySize;

  const SpriteAnimationWidget({
    super.key,
    required this.config,
    required this.displaySize,
  });

  @override
  State<SpriteAnimationWidget> createState() => _SpriteAnimationWidgetState();
}

class _SpriteAnimationWidgetState extends State<SpriteAnimationWidget>
    with SingleTickerProviderStateMixin {

  // ---- Ticker ----
  late final Ticker _ticker;
  Duration _lastTickTime = Duration.zero;  // total elapsed at previous tick
  Duration _frameAccumulator = Duration.zero; // time spent in current frame

  // ---- Frame ----
  int _frameIndex = 0;

  // ---- Loaded image ----
  // Null while loading or if the asset is missing (placeholder takes over).
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _loadImage(widget.config.sheet.assetPath);
  }

  @override
  void didUpdateWidget(SpriteAnimationWidget old) {
    super.didUpdateWidget(old);

    if (old.config.sheet.assetPath != widget.config.sheet.assetPath) {
      // Switched to a different animation clip.
      _frameIndex = 0;
      _frameAccumulator = Duration.zero;
      _image = null;
      _loadImage(widget.config.sheet.assetPath);
    }
    // FPS changes are picked up automatically; _onTick always reads
    // widget.config.frameDuration, so no explicit action needed.
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ---- Image loading ----
  //
  // Uses Flutter's standard ImageStream API so the image cache is shared
  // with the rest of the app — the same asset is never decoded twice.

  Future<void> _loadImage(String assetPath) async {
    try {
      final completer = Completer<ui.Image>();

      final stream = AssetImage(assetPath).resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          if (!completer.isCompleted) completer.complete(info.image);
          stream.removeListener(listener);
        },
        onError: (Object error, StackTrace? _) {
          if (!completer.isCompleted) completer.completeError(error);
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);

      final image = await completer.future;
      if (mounted) setState(() => _image = image);
    } catch (_) {
      // Asset not found or decode error.
      // _image stays null; the placeholder painter in MascotWidget renders instead.
    }
  }

  // ---- Ticker callback ----
  //
  // [elapsed] is the total time since the Ticker started.
  // We compute per-tick deltas so pauses (e.g. window minimised) don't
  // cause a burst of frame advances when the app resumes.

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastTickTime;
    _lastTickTime = elapsed;

    _frameAccumulator += delta;

    // How long each frame should be displayed at the current FPS.
    final frameDuration = widget.config.frameDuration;

    // Advance as many frames as have accumulated (usually just one).
    while (_frameAccumulator >= frameDuration) {
      _frameAccumulator -= frameDuration;
      final next = (_frameIndex + 1) % widget.config.sheet.frameCount;
      if (next != _frameIndex) {
        setState(() => _frameIndex = next);
      } else {
        _frameIndex = next; // single-frame sheet; no rebuild needed
      }
    }
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    // If the image is loaded, render the current frame.
    // If not, render a transparent placeholder of the correct size so the
    // parent layout doesn't shift when the image arrives.
    return CustomPaint(
      size: widget.displaySize,
      painter: _image != null
          ? SpriteAnimationPainter(
              image: _image!,
              sourceRect: widget.config.sheet.sourceRect(_frameIndex),
            )
          : null,
      child: SizedBox(
        width: widget.displaySize.width,
        height: widget.displaySize.height,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
//
// Clips one frame from the decoded image and scales it to the canvas size.
// drawImageRect handles the source→dest scaling in a single GPU draw call.
// ---------------------------------------------------------------------------

class SpriteAnimationPainter extends CustomPainter {
  final ui.Image image;
  final Rect sourceRect;

  const SpriteAnimationPainter({
    required this.image,
    required this.sourceRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final destRect = Offset.zero & size; // fill the allocated canvas
    canvas.drawImageRect(image, sourceRect, destRect, Paint());
  }

  @override
  bool shouldRepaint(SpriteAnimationPainter old) =>
      old.image != image || old.sourceRect != sourceRect;
}
