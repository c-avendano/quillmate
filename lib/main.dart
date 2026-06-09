// main.dart
//
// Initialises window_manager with a hidden title bar so the app header
// integrates the window controls directly (Apostrophe-style unified bar).

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'widgets/writing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  // Hide the native OS title bar so our _TopBar becomes the only chrome.
  // DragToMoveArea in _TopBar lets the user still drag the window.
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      minimumSize: Size(640, 480),
      titleBarStyle: TitleBarStyle.hidden,  // removes native title bar
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

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
          seedColor: const Color(0xFF006A62),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const WritingScreen(),
    );
  }
}
