// main.dart
//
// Entry point for QuillMate — a distraction-free Markdown writing app
// with an animated mascot companion.
//
// Architecture overview:
//   main.dart              → App bootstrap, window configuration
//   models/mascot_state.dart → Pure enum + data describing mascot mood
//   models/typing_monitor.dart → Tracks typing activity, emits state changes
//   widgets/writing_area.dart  → Full-screen Markdown text editor
//   widgets/mascot_widget.dart → Draggable animated mascot + message bubble
//   widgets/mascot_painter.dart → CustomPainter drawing the mascot shape
//                                  (swap this for SpriteSheet later)
//   utils/markdown_highlighter.dart → Lightweight syntax coloring for the editor

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
