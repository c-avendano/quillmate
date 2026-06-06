// main.dart
//
// Entry point for QuillMate — a distraction-free Markdown writing app
// with an animated mascot companion.
//
// Architecture overview:
//   main.dart                              → App bootstrap
//   models/mascot_state.dart               → FSM enum: idle/typingSlow/typingFast/encouraging
//   models/writing_activity_controller.dart → Owns the FSM; tracks speed; exposes state
//   sprites/sprite_sheet.dart              → Pure data: asset path, frame count, frame size
//   sprites/sprite_animation_config.dart   → Maps each MascotState → sheet + FPS
//   widgets/writing_area.dart              → Full-screen Markdown text editor
//   widgets/sprite_animation_widget.dart   → Loads sheet, advances frames via Ticker
//   widgets/mascot_widget.dart             → Bubble + sprite layer + placeholder fallback
//   widgets/mascot_painter.dart            → CustomPainter fallback (no asset needed)
//   utils/markdown_highlighter.dart        → Lightweight syntax coloring for the editor

import 'package:flutter/material.dart';

import 'widgets/writing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuillMateApp());
}

class QuillMateApp extends StatelessWidget {
  const QuillMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuillMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'monospace',
      ),
      home: const WritingScreen(),
    );
  }
}
