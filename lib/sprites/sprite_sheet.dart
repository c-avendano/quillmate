// sprites/sprite_sheet.dart
//
// Pure data — no Flutter imports, no timers, no state.
// Describes the layout of a single horizontal sprite sheet image.
//
// Assumptions (standard for simple desktop mascots):
//   • All frames are the same width.
//   • Frames are arranged left-to-right in a single row.
//   • The asset is a PNG with a transparent background.
//
// Example sheet with 4 frames, each 64 × 64 px:
//
//   ┌──────┬──────┬──────┬──────┐
//   │  f0  │  f1  │  f2  │  f3  │  total width: 256 px
//   └──────┴──────┴──────┴──────┘  height:       64 px

// Rect lives in dart:ui, not pure Dart — import it so this file stays
// free of the full Flutter framework dependency.
import 'dart:ui' show Rect;

/// Describes one horizontal sprite sheet.
class SpriteSheet {
  /// Asset path relative to the project root, e.g. 'assets/idle.png'.
  final String assetPath;

  /// Number of animation frames in this sheet.
  final int frameCount;

  /// Width of a single frame in pixels.
  /// Height of the sheet equals the height of a single frame.
  final double frameWidth;

  /// Height of a single frame in pixels.
  final double frameHeight;

  const SpriteSheet({
    required this.assetPath,
    required this.frameCount,
    required this.frameWidth,
    required this.frameHeight,
  });

  /// The source [Rect] on the sheet for [frameIndex] (zero-based).
  /// Used by [SpriteAnimationPainter] to clip the correct region.
  Rect sourceRect(int frameIndex) {
    assert(frameIndex >= 0 && frameIndex < frameCount,
        'frameIndex $frameIndex out of range [0, $frameCount)');
    return Rect.fromLTWH(
      frameIndex * frameWidth,
      0,
      frameWidth,
      frameHeight,
    );
  }

  /// Total sheet width in pixels.
  double get totalWidth => frameWidth * frameCount;
}
