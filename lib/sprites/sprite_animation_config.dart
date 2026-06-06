// sprites/sprite_animation_config.dart
//
// SpriteAnimationConfig is the single place that maps each MascotState
// to its sprite sheet and playback speed.
//
// To add a new state or swap an asset:
//   1. Edit kMascotAnimations below — nowhere else.
//
// FPS guidance for a desktop writing companion:
//   Idle        — 6 fps  : slow, breathing feel
//   typingSlow  — 10 fps : engaged but relaxed
//   typingFast  — 18 fps : urgent, frantic energy
//   encouraging — 8 fps  : warm, gentle pulse

import '../models/mascot_state.dart';
import 'sprite_sheet.dart';

/// Bundles a [SpriteSheet] with a playback speed for one animation clip.
class SpriteAnimationConfig {
  final SpriteSheet sheet;

  /// Frames per second. Clamped to > 0 by [SpriteAnimationWidget].
  final double fps;

  const SpriteAnimationConfig({required this.sheet, required this.fps});

  /// Duration of one full animation cycle.
  Duration get cycleDuration =>
      Duration(microseconds: (1000000 / fps * sheet.frameCount).round());

  /// Duration of a single frame.
  Duration get frameDuration =>
      Duration(microseconds: (1000000 / fps).round());
}

// ---------------------------------------------------------------------------
// Master animation table
//
// frameWidth / frameHeight: match your actual PNG dimensions.
// frameCount: number of horizontal frames in each sheet.
//
// These are placeholder values — update them when real assets are ready.
// The asset paths match what is declared in pubspec.yaml under flutter.assets.
// ---------------------------------------------------------------------------

const Map<MascotState, SpriteAnimationConfig> kMascotAnimations = {
  MascotState.idle: SpriteAnimationConfig(
    sheet: SpriteSheet(
      assetPath: 'assets/idle.png',
      frameCount: 4,
      frameWidth: 80,
      frameHeight: 80,
    ),
    fps: 6,
  ),

  MascotState.typingSlow: SpriteAnimationConfig(
    sheet: SpriteSheet(
      assetPath: 'assets/typing.png',
      frameCount: 6,
      frameWidth: 80,
      frameHeight: 80,
    ),
    fps: 10,
  ),

  MascotState.typingMedium: SpriteAnimationConfig(
    sheet: SpriteSheet(
      assetPath: 'assets/typing.png', // reuses typing sheet; swap for a dedicated medium sheet later
      frameCount: 6,
      frameWidth: 80,
      frameHeight: 80,
    ),
    fps: 13,
  ),

  MascotState.typingFast: SpriteAnimationConfig(
    sheet: SpriteSheet(
      assetPath: 'assets/excited.png',
      frameCount: 6,
      frameWidth: 80,
      frameHeight: 80,
    ),
    fps: 18,
  ),

  MascotState.encouraging: SpriteAnimationConfig(
    sheet: SpriteSheet(
      assetPath: 'assets/encouraging.png',
      frameCount: 4,
      frameWidth: 80,
      frameHeight: 80,
    ),
    fps: 8,
  ),
};
