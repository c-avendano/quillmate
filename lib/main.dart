// main.dart — QuillMate entry point.
//
// Initialises window_manager before runApp so focus mode can hide the
// OS title bar (window decorations) on Linux/GTK.

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'widgets/writing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // window_manager must be initialised before the window is shown.
  // We set a sensible minimum size so the editor is never unusable.
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(600, 400));

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
      ),
      home: const WritingScreen(),
    );
  }
}
