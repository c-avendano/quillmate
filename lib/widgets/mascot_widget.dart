// widgets/mascot_widget.dart
//
// Pure display. Receives MascotState + optional message + optional custom path.
//
// Rendering priority:
//   1. Custom sprite sheet (user-supplied file path via settings)
//   2. Bundled asset sprite sheet (assets/idle.png etc.)
//   3. CustomPainter placeholder (always renders; sits underneath)
//
// The placeholder is always visible as layer 1 of a Stack.
// The sprite layer sits on top as layer 2 and covers it once loaded.

import 'package:flutter/material.dart';

import '../models/mascot_state.dart';
import '../models/settings_controller.dart';
import '../sprites/sprite_animation_config.dart';
import '../sprites/sprite_sheet.dart';
import 'mascot_painter.dart';
import 'sprite_animation_widget.dart';

const double kMascotSize = 80.0;
const Size   kMascotDisplaySize = Size(kMascotSize, kMascotSize);

class MascotWidget extends StatelessWidget {
  final MascotState         state;
  final String              message;
  final SettingsController? settings; // optional — null = use bundled assets

  const MascotWidget({
    super.key,
    required this.state,
    this.message  = '',
    this.settings,
  });

  Color get _bubbleColor => switch (state) {
        MascotState.typingFast  => const Color(0xFFE53935),
        MascotState.encouraging => const Color(0xFFFF9800),
        _                       => Colors.transparent,
      };

  /// Build the config to pass to SpriteAnimationWidget.
  /// If a custom path is set, every state uses that single sheet.
  SpriteAnimationConfig _config() {
    final custom = settings?.customMascotPath;
    if (custom != null && custom.isNotEmpty) {
      return SpriteAnimationConfig(
        sheet: SpriteSheet(
          assetPath:   custom,
          frameCount:  settings!.customFrameCount,
          frameWidth:  settings!.customFrameWidth,
          frameHeight: settings!.customFrameHeight,
          isFilePath:  true, // load from disk, not from assets bundle
        ),
        fps: kMascotAnimations[state]?.fps ?? 8,
      );
    }
    return kMascotAnimations[state]!;
  }

  @override
  Widget build(BuildContext context) {
    final config = _config();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speech bubble
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: message.isNotEmpty
              ? _Bubble(
                  key:     ValueKey(message),
                  message: message,
                  color:   _bubbleColor,
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 4),

        SizedBox(
          width: kMascotSize, height: kMascotSize,
          child: Stack(
            children: [
              _PlaceholderMascot(state: state),
              SpriteAnimationWidget(
                key:         ValueKey('${state.name}-${config.sheet.assetPath}'),
                config:      config,
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
// Placeholder — animated CustomPainter shown until/if the sprite loads
// ---------------------------------------------------------------------------

class _PlaceholderMascot extends StatefulWidget {
  final MascotState state;
  const _PlaceholderMascot({required this.state});
  @override
  State<_PlaceholderMascot> createState() => _PlaceholderMascotState();
}

class _PlaceholderMascotState extends State<_PlaceholderMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const Map<MascotState, Duration> _durations = {
    MascotState.idle:         Duration(milliseconds: 2800),
    MascotState.typingSlow:   Duration(milliseconds: 900),
    MascotState.typingMedium: Duration(milliseconds: 550),
    MascotState.typingFast:   Duration(milliseconds: 300),
    MascotState.encouraging:  Duration(milliseconds: 1600),
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: _durations[widget.state]!)
      ..repeat();
  }

  @override
  void didUpdateWidget(_PlaceholderMascot old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _ctrl.duration = _durations[widget.state];
      if (!_ctrl.isAnimating) _ctrl.repeat();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(
      painter: MascotPainter(animationValue: _ctrl.value, state: widget.state),
      size: kMascotDisplaySize,
    ),
  );
}

// ---------------------------------------------------------------------------
// Speech bubble
// ---------------------------------------------------------------------------

class _Bubble extends StatelessWidget {
  final String message;
  final Color  color;
  const _Bubble({super.key, required this.message, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color:        color,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color:      Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset:     const Offset(0, 3),
        ),
      ],
    ),
    child: Text(message,
        style: const TextStyle(
          color:      Colors.white,
          fontWeight: FontWeight.bold,
          fontSize:   13,
          fontFamily: 'sans-serif',
        )),
  );
}
