// widgets/writing_screen.dart
//
// Root screen. Wires four controllers together:
//   SettingsController         → theme, fontFamily, focusMode, targetWpm
//   WritingActivityController  → WPM measurement → MascotState
//   FileController             → file I/O → editor content + title
//   WritingArea (GlobalKey)    → receives loadContent() after file ops
//
// Focus mode + title bar
// ──────────────────────
// Toggling focus mode calls windowManager.setFullScreen(true/false).
// This removes the OS title bar (window decorations) entirely on Linux/GTK,
// giving a fully distraction-free canvas.
// Ctrl+Shift+F and the toolbar button both call _toggleFocusMode().
//
// Theme propagation
// ─────────────────
// Every chrome widget (status bar, toolbar) reads its colours from
// _settings.chromeColor and _settings.chromeTextColor so they adapt
// when the user switches theme. No hardcoded dark colours anywhere.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../models/file_controller.dart';
import '../models/mascot_state.dart';
import '../models/settings_controller.dart';
import '../models/writing_activity_controller.dart';
import 'mascot_widget.dart';
import 'settings_panel.dart';
import 'writing_area.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  final SettingsController _settings = SettingsController();
  late final WritingActivityController _activityController;
  final FileController _fileController = FileController();

  final GlobalKey<WritingAreaState> _editorKey   = GlobalKey<WritingAreaState>();
  final GlobalKey<ScaffoldState>    _scaffoldKey = GlobalKey<ScaffoldState>();

  Offset _mascotPosition      = const Offset(60, 60);
  bool   _positionInitialized = false;

  @override
  void initState() {
    super.initState();
    _activityController = WritingActivityController(settings: _settings);
    _activityController.addListener(_onActivityChanged);
    _fileController.addListener(_onFileChanged);
    _settings.addListener(_onSettingsChanged);
  }

  void _onActivityChanged() => setState(() {});
  void _onSettingsChanged()  => setState(() {});

  void _onFileChanged() {
    _editorKey.currentState?.loadContent(_fileController.currentContent);
    setState(() {});
  }

  @override
  void dispose() {
    _activityController.removeListener(_onActivityChanged);
    _activityController.dispose();
    _fileController.removeListener(_onFileChanged);
    _fileController.dispose();
    _settings.removeListener(_onSettingsChanged);
    _settings.dispose();
    super.dispose();
  }

  bool get _focusMode => _settings.focusMode;

  // ---- Focus mode toggle ----
  //
  // Sets the app fullscreen via window_manager when entering focus mode.
  // This removes the OS title bar completely — not just the app toolbar.
  // Exiting restores the window to its previous state.

  Future<void> _toggleFocusMode() async {
    final next = !_settings.focusMode;
    _settings.setFocusMode(next);
    await windowManager.setFullScreen(next);
  }

  // ---- File handlers ----

  Future<void> _handleNew()  async => _fileController.newFile(onConfirm: _showDiscardDialog);
  Future<void> _handleOpen() async => _fileController.openFile(context);
  Future<void> _handleSave() async => _fileController.saveFile(context);

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _settings.chromeColor,
        title:   Text('Unsaved changes',
            style: TextStyle(color: _settings.textColor)),
        content: Text('You have unsaved changes. Discard them?',
            style: TextStyle(color: _settings.chromeTextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String get _bubbleMessage => switch (_activityController.mascotState) {
        MascotState.encouraging => _activityController.encouragementMessage,
        MascotState.typingFast  => 'On fire! 🔥',
        _                       => '',
      };

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (!_positionInitialized && size.width > 0) {
      _mascotPosition = Offset(size.width / 2 - kMascotSize / 2, 30);
      _positionInitialized = true;
    }

    return Scaffold(
      key:             _scaffoldKey,
      backgroundColor: _settings.backgroundColor,
      endDrawer:       SettingsPanel(settings: _settings),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              _handleSave,
          const SingleActivator(LogicalKeyboardKey.keyF,
              control: true, shift: true):
              _toggleFocusMode,
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              Column(
                children: [
                  // Status bar and toolbar — hidden in focus mode.
                  if (!_focusMode) ...[
                    _StatusBar(
                      displayName:       _fileController.displayName,
                      hasUnsavedChanges: _fileController.hasUnsavedChanges,
                      mascotState:       _activityController.mascotState,
                      currentWpm:        _activityController.currentWpm,
                      targetWpm:         _settings.targetWpm,
                      chromeColor:       _settings.chromeColor,
                      chromeTextColor:   _settings.chromeTextColor,
                    ),
                    Divider(height: 1,
                        color: _settings.chromeTextColor.withOpacity(0.15)),
                    _Toolbar(
                      chromeColor:     _settings.chromeColor,
                      chromeTextColor: _settings.chromeTextColor,
                      onNew:      _handleNew,
                      onOpen:     _handleOpen,
                      onSave:     _handleSave,
                      onFocus:    _toggleFocusMode,
                      onSettings: () => _scaffoldKey.currentState?.openEndDrawer(),
                    ),
                    Divider(height: 1,
                        color: _settings.chromeTextColor.withOpacity(0.15)),
                  ],

                  Expanded(
                    child: WritingArea(
                      key:        _editorKey,
                      focusMode:  _focusMode,
                      fontFamily: _settings.fontFamily,
                      textColor:  _settings.textColor,
                      onKeyPress: _activityController.recordKeyPress,
                      onChanged:  _fileController.onContentChanged,
                    ),
                  ),
                ],
              ),

              // Focus mode exit hint.
              if (_focusMode)
                Positioned(
                  bottom: 16, left: 0, right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _toggleFocusMode,
                      child: Text(
                        'Ctrl+Shift+F to exit focus mode',
                        style: TextStyle(
                          color: _settings.textColor.withOpacity(0.2),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),

              // Draggable mascot — always visible.
              Positioned(
                left: _mascotPosition.dx,
                top:  _mascotPosition.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _mascotPosition = Offset(
                        (_mascotPosition.dx + details.delta.dx)
                            .clamp(0, size.width  - kMascotSize),
                        (_mascotPosition.dy + details.delta.dy)
                            .clamp(0, size.height - kMascotSize - 60),
                      );
                    });
                  },
                  child: MascotWidget(
                    state:   _activityController.mascotState,
                    message: _bubbleMessage,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar
// ---------------------------------------------------------------------------

class _Toolbar extends StatelessWidget {
  final Color        chromeColor;
  final Color        chromeTextColor;
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onFocus;
  final VoidCallback onSettings;

  const _Toolbar({
    required this.chromeColor,
    required this.chromeTextColor,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onFocus,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: chromeColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _Btn(icon: Icons.insert_drive_file_outlined, tip: 'New',                        color: chromeTextColor, onPressed: onNew),
          _Btn(icon: Icons.folder_open_outlined,       tip: 'Open',                       color: chromeTextColor, onPressed: onOpen),
          _Btn(icon: Icons.save_outlined,              tip: 'Save  (Ctrl+S)',             color: chromeTextColor, onPressed: onSave),
          const Spacer(),
          _Btn(icon: Icons.center_focus_strong_outlined, tip: 'Focus  (Ctrl+Shift+F)',   color: chromeTextColor, onPressed: onFocus),
          _Btn(icon: Icons.tune,                       tip: 'Settings',                  color: chromeTextColor, onPressed: onSettings),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData     icon;
  final String       tip;
  final Color        color;
  final VoidCallback onPressed;
  const _Btn({required this.icon, required this.tip, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tip,
        child: IconButton(
          icon:         Icon(icon, size: 18),
          color:        color,
          hoverColor:   color.withOpacity(0.12),
          splashRadius: 16,
          onPressed:    onPressed,
        ),
      );
}

// ---------------------------------------------------------------------------
// Status bar
// ---------------------------------------------------------------------------

class _StatusBar extends StatelessWidget {
  final String      displayName;
  final bool        hasUnsavedChanges;
  final MascotState mascotState;
  final int         currentWpm;
  final int         targetWpm;
  final Color       chromeColor;
  final Color       chromeTextColor;

  const _StatusBar({
    required this.displayName,
    required this.hasUnsavedChanges,
    required this.mascotState,
    required this.currentWpm,
    required this.targetWpm,
    required this.chromeColor,
    required this.chromeTextColor,
  });

  String get _moodLabel => switch (mascotState) {
        MascotState.idle         => 'Idle',
        MascotState.typingSlow   => 'Slow ✍️',
        MascotState.typingMedium => 'Medium 💪',
        MascotState.typingFast   => 'On fire 🔥',
        MascotState.encouraging  => 'Encouraging 💛',
      };

  @override
  Widget build(BuildContext context) {
    final wpmColor = switch (mascotState) {
      MascotState.typingSlow   => const Color(0xFF5B8CCC),
      MascotState.typingMedium => const Color(0xFFFFAA00),
      MascotState.typingFast   => const Color(0xFFE53935),
      _                        => chromeTextColor.withOpacity(0.5),
    };

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: chromeColor,
      child: Row(
        children: [
          Text('QuillMate',
              style: TextStyle(
                color: chromeTextColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              )),
          const SizedBox(width: 12),
          Text(
            hasUnsavedChanges ? '● $displayName' : displayName,
            style: TextStyle(
              color: hasUnsavedChanges
                  ? const Color(0xFFFF9800)
                  : chromeTextColor.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Text('$currentWpm / $targetWpm wpm',
              style: TextStyle(
                  color: wpmColor, fontSize: 11, fontFamily: 'monospace')),
          const SizedBox(width: 20),
          Text(_moodLabel,
              style: TextStyle(
                  color: chromeTextColor.withOpacity(0.6), fontSize: 11)),
        ],
      ),
    );
  }
}
