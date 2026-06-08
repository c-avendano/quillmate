// widgets/writing_screen.dart
//
// Layout (normal mode):
//
//   ┌─ TopBar (44px) ──────────────────────────────────────────────┐
//   │  [+][Open][Save]       filename ●       [Focus][Settings]    │
//   ├─ FormattingBar (38px) ────────────────────────────────────────┤
//   │  Bold  Italic  Strike  Code  Link  Quote  H1  H2  H3  •  1. │
//   ├───────────────────────────────────────────────────────────────┤
//   │                                                               │
//   │   workspace (canvasColor fills edge-to-edge)                  │
//   │                                                               │
//   │        # Heading                                              │
//   │        Body text at 18px / 1.8 line-height…                  │
//   │        (constrained to 800px, centred)                        │
//   │                                                               │
//   │                                         [mascot]  ←draggable │
//   ├─ BottomBar (36px) ────────────────────────────────────────────┤
//   │  124 words                            32/40 wpm ✍️            │
//   └───────────────────────────────────────────────────────────────┘
//
// Focus mode: fullscreen (window_manager), only the editor + mascot visible.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../models/file_controller.dart';
import '../models/mascot_state.dart';
import '../models/settings_controller.dart';
import '../models/writing_activity_controller.dart';
import 'formatting_bar.dart';
import 'mascot_widget.dart';
import 'settings_panel.dart';
import 'writing_area.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});
  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  final SettingsController          _settings = SettingsController();
  late final WritingActivityController _activity;
  final FileController              _files    = FileController();

  final GlobalKey<WritingAreaState> _editorKey   = GlobalKey<WritingAreaState>();
  final GlobalKey<ScaffoldState>    _scaffoldKey = GlobalKey<ScaffoldState>();

  // Mascot: starts null (placed bottom-right on first layout), draggable.
  Offset? _mascotPos;
  static const double _mascotRightPad  = 24;
  static const double _mascotBottomPad = 16;

  @override
  void initState() {
    super.initState();
    _activity = WritingActivityController(settings: _settings);
    _activity.addListener(_rebuild);
    _files.addListener(_onFileChanged);
    _settings.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  void _onFileChanged() {
    _editorKey.currentState?.loadContent(_files.currentContent);
    setState(() {});
  }

  @override
  void dispose() {
    _activity.removeListener(_rebuild);
    _activity.dispose();
    _files.removeListener(_onFileChanged);
    _files.dispose();
    _settings.removeListener(_rebuild);
    _settings.dispose();
    super.dispose();
  }

  bool get _focus => _settings.focusMode;

  Future<void> _toggleFocus() async {
    final next = !_settings.focusMode;
    _settings.setFocusMode(next);
    await windowManager.setFullScreen(next);
  }

  Future<void> _handleNew()  async => _files.newFile(onConfirm: _confirmDiscard);
  Future<void> _handleOpen() async => _files.openFile(context);
  Future<void> _handleSave() async => _files.saveFile(context);

  Future<bool> _confirmDiscard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _settings.canvasColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Unsaved changes',
            style: TextStyle(color: _settings.textColor,
                fontSize: 16, fontWeight: FontWeight.w600,
                fontFamily: 'sans-serif')),
        content: Text('Discard unsaved changes?',
            style: TextStyle(color: _settings.chromeTextColor,
                fontSize: 14, fontFamily: 'sans-serif')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: _settings.chromeTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Discard',
                style: TextStyle(color: _settings.primaryColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  String get _bubble => switch (_activity.mascotState) {
        MascotState.encouraging => _activity.encouragementMessage,
        MascotState.typingFast  => 'On fire! 🔥',
        _                       => '',
      };

  int get _wordCount {
    final t = _files.currentContent.trim();
    return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final s    = _settings;
    final size = MediaQuery.of(context).size;

    // Chrome heights — must match the actual widget heights below.
    const topBarH      = 44.0;
    const fmtBarH      = 38.0;
    const bottomBarH   = 36.0;
    final chromeH = _focus ? 0.0 : topBarH + fmtBarH + bottomBarH;

    // Initialise mascot to bottom-right of the editor area (not the full window).
    final stackH = size.height - chromeH;
    _mascotPos ??= Offset(
      size.width - kMascotSize - _mascotRightPad,
      stackH     - kMascotSize - _mascotBottomPad,
    );

    return Scaffold(
      key:             _scaffoldKey,
      backgroundColor: s.canvasColor,  // seamless fill
      endDrawer:       SettingsPanel(settings: s),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              _handleSave,
          const SingleActivator(LogicalKeyboardKey.keyF,
              control: true, shift: true): _toggleFocus,
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [

              // ── Top bar ──────────────────────────────────────────
              if (!_focus)
                _TopBar(
                  filename:   _files.displayName,
                  unsaved:    _files.hasUnsavedChanges,
                  s:          s,
                  onNew:      _handleNew,
                  onOpen:     _handleOpen,
                  onSave:     _handleSave,
                  onFocus:    _toggleFocus,
                  onSettings: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),

              // ── Formatting bar ───────────────────────────────────
              // Hidden in focus mode.
              // The controller is read from the editor's GlobalKey state.
              // It is always non-null by the time this runs because WritingArea
              // is built in the same pass (same build() call, earlier in Column).
              if (!_focus)
                _FormattingBarSlot(
                  editorKey: _editorKey,
                  settings:  s,
                  onChanged: () {
                    _activity.recordKeyPress();
                    _editorKey.currentState?.refocus();
                  },
                ),

              // ── Editor + mascot ──────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    // The editor fills the entire Stack area.
                    WritingArea(
                      key:          _editorKey,
                      focusMode:    _focus,
                      fontFamily:   s.fontFamily,
                      textColor:    s.textColor,
                      canvasColor:  s.canvasColor,
                      borderColor:  s.borderColor,
                      primaryColor: s.primaryColor,
                      onKeyPress:   _activity.recordKeyPress,
                      onChanged:    _files.onContentChanged,
                    ),

                    // Mascot: starts bottom-right, draggable anywhere.
                    // MediaQuery gives us the real window size so clamping works.
                    Positioned(
                      left: _mascotPos!.dx,
                      top:  _mascotPos!.dy,
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          setState(() {
                            _mascotPos = Offset(
                              (_mascotPos!.dx + d.delta.dx)
                                  .clamp(0, size.width  - kMascotSize),
                              (_mascotPos!.dy + d.delta.dy)
                                  .clamp(0, stackH      - kMascotSize),
                            );
                          });
                        },
                        child: MascotWidget(
                          state:    _activity.mascotState,
                          message:  _bubble,
                          settings: s,
                        ),
                      ),
                    ),

                    // Focus mode exit hint.
                    if (_focus)
                      Positioned(
                        bottom: 16, left: 0, right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _toggleFocus,
                            child: Text(
                              'Ctrl+Shift+F to exit focus mode',
                              style: TextStyle(
                                color:      s.textColor.withOpacity(0.2),
                                fontSize:   11,
                                fontFamily: 'sans-serif',
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Bottom bar ───────────────────────────────────────
              if (!_focus)
                _BottomBar(
                  mascotState: _activity.mascotState,
                  currentWpm:  _activity.currentWpm,
                  targetWpm:   s.targetWpm,
                  wordCount:   _wordCount,
                  s:           s,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final String             filename;
  final bool               unsaved;
  final SettingsController s;
  final VoidCallback       onNew;
  final VoidCallback       onOpen;
  final VoidCallback       onSave;
  final VoidCallback       onFocus;
  final VoidCallback       onSettings;

  const _TopBar({
    required this.filename,
    required this.unsaved,
    required this.s,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onFocus,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: s.chromeColor,
        border: Border(bottom: BorderSide(color: s.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          _TBtn(Icons.add,               'New',             s, onNew),
          _TBtn(Icons.folder_open_outlined, 'Open',         s, onOpen),
          _TBtn(Icons.save_outlined,     'Save  (Ctrl+S)',  s, onSave),
          Expanded(
            child: Center(
              child: Text(
                unsaved ? '$filename  ●' : filename,
                style: TextStyle(
                  color:      unsaved ? s.primaryColor : s.chromeTextColor,
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'sans-serif',
                ),
              ),
            ),
          ),
          _TBtn(Icons.center_focus_strong_outlined,
              'Focus mode  (Ctrl+Shift+F)', s, onFocus),
          _TBtn(Icons.tune, 'Settings', s, onSettings),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom bar
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  final MascotState        mascotState;
  final int                currentWpm;
  final int                targetWpm;
  final int                wordCount;
  final SettingsController s;

  const _BottomBar({
    required this.mascotState,
    required this.currentWpm,
    required this.targetWpm,
    required this.wordCount,
    required this.s,
  });

  String get _mood => switch (mascotState) {
        MascotState.idle         => '',
        MascotState.typingSlow   => '✍️',
        MascotState.typingMedium => '💪',
        MascotState.typingFast   => '🔥',
        MascotState.encouraging  => '💛',
      };

  Color get _wpmColor => switch (mascotState) {
        MascotState.typingSlow   => const Color(0xFF5B8CCC),
        MascotState.typingMedium => const Color(0xFFFFAA00),
        MascotState.typingFast   => const Color(0xFFE53935),
        _                        => s.chromeTextColor,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color:  s.chromeColor,
        border: Border(top: BorderSide(color: s.borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '$wordCount ${wordCount == 1 ? "word" : "words"}',
            style: TextStyle(
                color: s.chromeTextColor, fontSize: 12,
                fontFamily: 'sans-serif'),
          ),
          const Spacer(),
          Text(
            '$currentWpm / $targetWpm wpm  $_mood',
            style: TextStyle(
                color: _wpmColor, fontSize: 12, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared toolbar button
// ---------------------------------------------------------------------------

class _TBtn extends StatelessWidget {
  final IconData           icon;
  final String             tip;
  final SettingsController s;
  final VoidCallback       onPressed;
  const _TBtn(this.icon, this.tip, this.s, this.onPressed);

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tip,
        child: IconButton(
          icon:         Icon(icon, size: 17),
          color:        s.chromeTextColor,
          hoverColor:   s.primaryColor.withOpacity(0.08),
          splashRadius: 16,
          onPressed:    onPressed,
        ),
      );
}

// ---------------------------------------------------------------------------
// Formatting bar slot
// ---------------------------------------------------------------------------
//
// Reads the editor controller from the GlobalKey after the first frame.
// Uses a post-frame callback to trigger a rebuild once the key is resolved.

class _FormattingBarSlot extends StatefulWidget {
  final GlobalKey<WritingAreaState> editorKey;
  final SettingsController          settings;
  final VoidCallback                onChanged;

  const _FormattingBarSlot({
    required this.editorKey,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<_FormattingBarSlot> createState() => _FormattingBarSlotState();
}

class _FormattingBarSlotState extends State<_FormattingBarSlot> {
  @override
  void initState() {
    super.initState();
    // Trigger a rebuild after the first frame so the GlobalKey state is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.editorKey.currentState?.controller;
    if (ctrl == null) return const SizedBox(height: 38);
    return FormattingBar(
      controller: ctrl,
      settings:   widget.settings,
      onChanged:  widget.onChanged,
    );
  }
}
