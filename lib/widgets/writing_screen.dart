// widgets/writing_screen.dart
//
// Layout (normal mode):
//
//   ┌─ TopBar (44px, DragToMoveArea) ──────────────────────────────┐
//   │  [+][Open][Save▾]     filename ●     [Focus][⊞][Settings]   │
//   ├─ FormattingBar (animated, collapsible) ───────────────────────┤
//   │  Bold Italic Strike Code Link Quote H1 H2 H3 • 1.   [^] │
//   ├───────────────────────────────────────────────────────────────┤
//   │  editor (800px centred, seamless background)                  │
//   │                                          [mascot] draggable   │
//   ├─ BottomBar (36px) ────────────────────────────────────────────┤
//   │  124 words                          32/40 wpm ✍️              │
//   └───────────────────────────────────────────────────────────────┘

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

  Offset? _mascotPos;
  static const double _mascotRightPad  = 24;
  static const double _mascotBottomPad = 16;

  // Formatting bar visibility (persists for the session, starts visible).
  bool _fmtBarVisible = true;

  @override
  void initState() {
    super.initState();
    _activity = WritingActivityController(settings: _settings);
    _activity.addListener(_rebuild);
    _files.addListener(_onFileChanged);
    _settings.addListener(_rebuild);

    // Show WPM onboarding dialog after first frame if not yet set.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_settings.hasSetWpm) _showWpmOnboarding();
    });
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

  // ---- Focus toggle ----

  Future<void> _toggleFocus() async {
    final next = !_settings.focusMode;
    _settings.setFocusMode(next);
    await windowManager.setFullScreen(next);
  }

  // ---- File handlers ----

  Future<void> _handleNew()  async => _files.newFile(onConfirm: _confirmDiscard);
  Future<void> _handleOpen() async => _files.openFile(context);
  Future<void> _handleSave() async => _files.saveFile(context);
  Future<void> _handleExportHtml() async => _files.exportAsHtml(context);
  Future<void> _handleExportPdf()  async => _files.exportAsPdf(context);

  Future<bool> _confirmDiscard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _settings.canvasColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Unsaved changes',
            style: TextStyle(color: _settings.textColor, fontSize: 16,
                fontWeight: FontWeight.w600, fontFamily: 'sans-serif')),
        content: Text('Discard unsaved changes?',
            style: TextStyle(color: _settings.chromeTextColor,
                fontSize: 14, fontFamily: 'sans-serif')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: TextStyle(color: _settings.chromeTextColor))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text('Discard',
                  style: TextStyle(color: _settings.primaryColor,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
    return ok ?? false;
  }

  // ---- WPM onboarding ----

  Future<void> _showWpmOnboarding() async {
    final s = _settings;
    int draft = s.targetWpm;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: s.canvasColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text('Welcome to QuillMate ✨',
              style: TextStyle(color: s.textColor, fontSize: 17,
                  fontWeight: FontWeight.w700, fontFamily: 'sans-serif')),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\'s your typical writing speed?\n'
                  'The mascot uses this to cheer you on.',
                  style: TextStyle(color: s.chromeTextColor, fontSize: 14,
                      fontFamily: 'sans-serif', height: 1.5),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('$draft wpm',
                        style: TextStyle(color: s.primaryColor, fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace')),
                    const Spacer(),
                    Text(_wpmLabel(draft),
                        style: TextStyle(color: s.chromeTextColor,
                            fontSize: 12, fontFamily: 'sans-serif')),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(ctx).copyWith(
                    activeTrackColor:   s.primaryColor,
                    inactiveTrackColor: s.borderColor,
                    thumbColor:         s.primaryColor,
                    trackHeight:        3,
                  ),
                  child: Slider(
                    value:     draft.toDouble(),
                    min:       kMinTargetWpm.toDouble(),
                    max:       kMaxTargetWpm.toDouble(),
                    divisions: kMaxTargetWpm - kMinTargetWpm,
                    onChanged: (v) => setLocal(() => draft = v.round()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$kMinTargetWpm slow',
                          style: TextStyle(color: s.chromeTextColor.withOpacity(0.4),
                              fontSize: 10, fontFamily: 'sans-serif')),
                      Text('$kMaxTargetWpm fast',
                          style: TextStyle(color: s.chromeTextColor.withOpacity(0.4),
                              fontSize: 10, fontFamily: 'sans-serif')),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('You can change this anytime in Settings.',
                    style: TextStyle(color: s.chromeTextColor.withOpacity(0.5),
                        fontSize: 11, fontFamily: 'sans-serif')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                s.setTargetWpm(draft);
                s.markWpmSet();
                Navigator.pop(ctx);
              },
              child: Text('Start writing',
                  style: TextStyle(color: s.primaryColor,
                      fontWeight: FontWeight.w700, fontFamily: 'sans-serif')),
            ),
          ],
        ),
      ),
    );
  }

  String _wpmLabel(int wpm) {
    if (wpm < 30) return 'Relaxed';
    if (wpm < 50) return 'Comfortable';
    if (wpm < 70) return 'Steady';
    if (wpm < 90) return 'Brisk';
    return 'Fast';
  }

  // ---- Mascot bubble ----

  String get _bubble => switch (_activity.mascotState) {
        MascotState.encouraging => _activity.encouragementMessage,
        MascotState.typingFast  => 'On fire! 🔥',
        _                       => '',
      };

  int get _wordCount {
    final t = _files.currentContent.trim();
    return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
  }

  // Heights used for mascot clamping — must match widget heights below.
  static const _topBarH    = 44.0;
  static const _fmtBarH    = 38.0;
  static const _bottomBarH = 36.0;

  @override
  Widget build(BuildContext context) {
    final s    = _settings;
    final size = MediaQuery.of(context).size;

    final chromeH = _focus
        ? 0.0
        : _topBarH + (_fmtBarVisible ? _fmtBarH : 0) + _bottomBarH;
    final stackH = size.height - chromeH;

    _mascotPos ??= Offset(
      size.width - kMascotSize - _mascotRightPad,
      stackH     - kMascotSize - _mascotBottomPad,
    );

    return Scaffold(
      key:             _scaffoldKey,
      backgroundColor: s.canvasColor,
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

              // ── Top bar (drag area for window movement) ──────────
              if (!_focus)
                DragToMoveArea(
                  child: _TopBar(
                    filename:      _files.displayName,
                    unsaved:       _files.hasUnsavedChanges,
                    s:             s,
                    onNew:         _handleNew,
                    onOpen:        _handleOpen,
                    onSave:        _handleSave,
                    onExportHtml:  _handleExportHtml,
                    onExportPdf:   _handleExportPdf,
                    onFocus:       _toggleFocus,
                    onSettings:    () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                ),

              // ── Formatting bar (animated collapse) ───────────────
              if (!_focus)
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve:    Curves.easeInOut,
                  child: _fmtBarVisible
                      ? _FormattingBarSlot(
                          editorKey: _editorKey,
                          settings:  s,
                          visible:   _fmtBarVisible,
                          onToggle:  () => setState(() => _fmtBarVisible = false),
                          onChanged: () {
                            _activity.recordKeyPress();
                            _editorKey.currentState?.refocus();
                          },
                        )
                      : _CollapsedFmtBar(
                          s:        s,
                          onExpand: () => setState(() => _fmtBarVisible = true),
                        ),
                ),

              // ── Editor + mascot ──────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
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

                    // Mascot: bottom-right default, fully draggable.
                    Positioned(
                      left: _mascotPos!.dx,
                      top:  _mascotPos!.dy,
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          setState(() {
                            _mascotPos = Offset(
                              (_mascotPos!.dx + d.delta.dx)
                                  .clamp(0, size.width - kMascotSize),
                              (_mascotPos!.dy + d.delta.dy)
                                  .clamp(0, stackH     - kMascotSize),
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
  final VoidCallback       onExportHtml;
  final VoidCallback       onExportPdf;
  final VoidCallback       onFocus;
  final VoidCallback       onSettings;

  const _TopBar({
    required this.filename,
    required this.unsaved,
    required this.s,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onExportHtml,
    required this.onExportPdf,
    required this.onFocus,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color:  s.chromeColor,
        border: Border(bottom: BorderSide(color: s.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          _TBtn(Icons.add,                  'New',            s, onNew),
          _TBtn(Icons.folder_open_outlined, 'Open',           s, onOpen),
          _TBtn(Icons.save_outlined,        'Save (Ctrl+S)',  s, onSave),

          // Export dropdown
          _ExportMenu(s: s, onHtml: onExportHtml, onPdf: onExportPdf),

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
              'Focus mode (Ctrl+Shift+F)', s, onFocus),
          _TBtn(Icons.tune, 'Settings', s, onSettings),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Export dropdown menu
// ---------------------------------------------------------------------------

class _ExportMenu extends StatelessWidget {
  final SettingsController s;
  final VoidCallback       onHtml;
  final VoidCallback       onPdf;
  const _ExportMenu({required this.s, required this.onHtml, required this.onPdf});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip:  'Export',
      color:    s.canvasColor,
      shape:    RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: s.borderColor)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_outlined, size: 17, color: s.chromeTextColor),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: s.chromeTextColor),
          ],
        ),
      ),
      onSelected: (v) {
        if (v == 'html') onHtml();
        if (v == 'pdf')  onPdf();
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'html',
            child: Text('Export as HTML',
                style: TextStyle(color: s.textColor, fontSize: 13,
                    fontFamily: 'sans-serif'))),
        PopupMenuItem(value: 'pdf',
            child: Text('Export as PDF',
                style: TextStyle(color: s.textColor, fontSize: 13,
                    fontFamily: 'sans-serif'))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Formatting bar slot + collapsed strip
// ---------------------------------------------------------------------------

class _FormattingBarSlot extends StatefulWidget {
  final GlobalKey<WritingAreaState> editorKey;
  final SettingsController          settings;
  final bool                        visible;
  final VoidCallback                onToggle;
  final VoidCallback                onChanged;

  const _FormattingBarSlot({
    required this.editorKey,
    required this.settings,
    required this.visible,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  State<_FormattingBarSlot> createState() => _FormattingBarSlotState();
}

class _FormattingBarSlotState extends State<_FormattingBarSlot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.editorKey.currentState?.controller;
    if (ctrl == null) return SizedBox(height: 38, child: Container(color: widget.settings.canvasColor));
    return FormattingBar(
      controller:  ctrl,
      settings:    widget.settings,
      onChanged:   widget.onChanged,
      onCollapse:  widget.onToggle,
    );
  }
}

/// Tiny strip shown when the formatting bar is collapsed.
class _CollapsedFmtBar extends StatelessWidget {
  final SettingsController s;
  final VoidCallback       onExpand;
  const _CollapsedFmtBar({required this.s, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      decoration: BoxDecoration(
        color:  s.canvasColor,
        border: Border(bottom: BorderSide(color: s.borderColor, width: 1)),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: onExpand,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Formatting',
                    style: TextStyle(
                      color:      s.chromeTextColor.withOpacity(0.5),
                      fontSize:   10,
                      fontFamily: 'sans-serif',
                    )),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down,
                    size: 14, color: s.chromeTextColor.withOpacity(0.5)),
              ],
            ),
          ),
        ),
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
          Text('$wordCount ${wordCount == 1 ? "word" : "words"}',
              style: TextStyle(color: s.chromeTextColor,
                  fontSize: 12, fontFamily: 'sans-serif')),
          const Spacer(),
          Text('$currentWpm / $targetWpm wpm  $_mood',
              style: TextStyle(color: _wpmColor,
                  fontSize: 12, fontFamily: 'monospace')),
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
