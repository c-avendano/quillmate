// sprites/sprite_sheet.dart
//
// Pure data describing one horizontal sprite sheet.
// isFilePath: true  → load from an absolute filesystem path (user custom)
// isFilePath: false → load from the Flutter asset bundle (bundled assets)

import 'dart:ui' show Rect;

class SpriteSheet {
  final String assetPath;   // asset key OR absolute file path
  final int    frameCount;
  final double frameWidth;
  final double frameHeight;
  final bool   isFilePath;  // true = dart:io File, false = AssetImage

  const SpriteSheet({
    required this.assetPath,
    required this.frameCount,
    required this.frameWidth,
    required this.frameHeight,
    this.isFilePath = false,
  });

  Rect sourceRect(int frameIndex) {
    assert(frameIndex >= 0 && frameIndex < frameCount);
    return Rect.fromLTWH(frameIndex * frameWidth, 0, frameWidth, frameHeight);
  }

  double get totalWidth => frameWidth * frameCount;
}
