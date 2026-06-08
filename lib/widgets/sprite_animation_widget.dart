// widgets/sprite_animation_widget.dart
//
// Renders one animation clip from a sprite sheet.
// Supports both Flutter asset bundle images and arbitrary file paths
// (for user-supplied custom mascot spritesheets).

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../sprites/sprite_animation_config.dart';
import '../sprites/sprite_sheet.dart';

class SpriteAnimationWidget extends StatefulWidget {
  final SpriteAnimationConfig config;
  final Size                  displaySize;

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

  late final Ticker _ticker;
  Duration _lastTickTime      = Duration.zero;
  Duration _frameAccumulator  = Duration.zero;
  int      _frameIndex        = 0;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _loadImage(widget.config.sheet);
  }

  @override
  void didUpdateWidget(SpriteAnimationWidget old) {
    super.didUpdateWidget(old);
    if (old.config.sheet.assetPath != widget.config.sheet.assetPath ||
        old.config.sheet.isFilePath != widget.config.sheet.isFilePath) {
      _frameIndex       = 0;
      _frameAccumulator = Duration.zero;
      _image            = null;
      _loadImage(widget.config.sheet);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _loadImage(SpriteSheet sheet) async {
    try {
      ui.Image image;

      if (sheet.isFilePath) {
        // Load from the filesystem for user-supplied spritesheets.
        final bytes = await File(sheet.assetPath).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        image = frame.image;
      } else {
        // Load from the Flutter asset bundle.
        final completer = Completer<ui.Image>();
        final stream = AssetImage(sheet.assetPath)
            .resolve(ImageConfiguration.empty);
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (ImageInfo info, bool _) {
            if (!completer.isCompleted) completer.complete(info.image);
            stream.removeListener(listener);
          },
          onError: (Object e, StackTrace? _) {
            if (!completer.isCompleted) completer.completeError(e);
            stream.removeListener(listener);
          },
        );
        stream.addListener(listener);
        image = await completer.future;
      }

      if (mounted) setState(() => _image = image);
    } catch (_) {
      // Load failure → _image stays null → placeholder painter shows through.
    }
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastTickTime;
    _lastTickTime = elapsed;
    _frameAccumulator += delta;

    final frameDuration = widget.config.frameDuration;
    while (_frameAccumulator >= frameDuration) {
      _frameAccumulator -= frameDuration;
      final next = (_frameIndex + 1) % widget.config.sheet.frameCount;
      setState(() => _frameIndex = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: widget.displaySize,
      painter: _image != null
          ? _SpriteFramePainter(
              image:      _image!,
              sourceRect: widget.config.sheet.sourceRect(_frameIndex),
            )
          : null,
      child: SizedBox(
        width:  widget.displaySize.width,
        height: widget.displaySize.height,
      ),
    );
  }
}

class _SpriteFramePainter extends CustomPainter {
  final ui.Image image;
  final ui.Rect  sourceRect;
  const _SpriteFramePainter({required this.image, required this.sourceRect});

  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawImageRect(image, sourceRect, Offset.zero & size, Paint());

  @override
  bool shouldRepaint(_SpriteFramePainter old) =>
      old.image != image || old.sourceRect != sourceRect;
}
