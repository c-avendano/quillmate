// widgets/writing_area.dart
//
// The writing surface — borderless, seamless with the workspace.
// No card, no border, no shadow. The text just lives on the background.
//
// The max-width constraint (800px) and generous padding (64px vertical)
// remain — they are typography choices, not decoration choices.
//
// Exposes [controller] via [WritingAreaState] so FormattingBar can
// read and modify the selection without going through a callback chain.

import 'package:flutter/material.dart';
import '../utils/markdown_highlighter.dart';

typedef OnKeyPress = void Function();
typedef OnChanged  = void Function(String text);

const double kContainerMax   = 800;
const double kEditorPaddingV = 64;
const double kEditorPaddingH = 48;
const double kWorkspacePadH  = 40;
const double kWorkspacePadV  = 32;

class WritingArea extends StatefulWidget {
  final OnKeyPress onKeyPress;
  final OnChanged  onChanged;
  final bool       focusMode;
  final String     fontFamily;
  final Color      textColor;
  final Color      canvasColor;   // kept for background fill (no border now)
  final Color      borderColor;   // unused visually, kept for API compat
  final Color      primaryColor;

  const WritingArea({
    super.key,
    required this.onKeyPress,
    required this.onChanged,
    this.focusMode    = false,
    this.fontFamily   = 'sans-serif',
    this.textColor    = const Color(0xFF1B1C1C),
    this.canvasColor  = const Color(0xFFFFFFFF),
    this.borderColor  = const Color(0xFFBCC9C6),
    this.primaryColor = const Color(0xFF006A62),
  });

  @override
  State<WritingArea> createState() => WritingAreaState();
}

class WritingAreaState extends State<WritingArea> {
  late _HighlightingController _controller;
  final FocusNode        _focusNode = FocusNode();
  final ScrollController _scroll    = ScrollController();

  /// Exposed so FormattingBar can read/write the selection directly.
  TextEditingController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = _HighlightingController(
        fontFamily: widget.fontFamily, textColor: widget.textColor);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void didUpdateWidget(WritingArea old) {
    super.didUpdateWidget(old);
    if (old.fontFamily != widget.fontFamily ||
        old.textColor  != widget.textColor) {
      final text = _controller.text;
      final sel  = _controller.selection;
      _controller.dispose();
      _controller = _HighlightingController(
          fontFamily: widget.fontFamily, textColor: widget.textColor);
      _controller.value = TextEditingValue(text: text, selection: sel);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void loadContent(String text) {
    _controller.value = TextEditingValue(
      text:      text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _focusNode.requestFocus();
  }

  /// Refocus the editor (called by FormattingBar after applying formatting).
  void refocus() => _focusNode.requestFocus();

  TextStyle get _editorStyle => TextStyle(
    fontSize:   18,
    height:     1.8,
    color:      widget.textColor,
    fontFamily: widget.fontFamily,
  );

  Widget _buildTextField() => TextField(
    controller:  _controller,
    focusNode:   _focusNode,
    maxLines:    null,
    expands:     false,
    style:       _editorStyle,
    cursorColor: widget.primaryColor,
    cursorWidth: 2,
    decoration: InputDecoration(
      border:    InputBorder.none,
      hintText:  '# Start writing…',
      hintStyle: TextStyle(
        color:      widget.textColor.withOpacity(0.28),
        fontFamily: widget.fontFamily,
        fontSize:   18,
        height:     1.8,
      ),
    ),
    onChanged: (text) {
      widget.onKeyPress();
      widget.onChanged(text);
    },
  );

  @override
  Widget build(BuildContext context) {
    // Both modes: borderless, scrollable, centred column.
    // Focus mode removes the workspace padding so the text fills the screen edge.
    final hPad = widget.focusMode ? kWorkspacePadH : kWorkspacePadH;
    final vPad = widget.focusMode ? kEditorPaddingV : kWorkspacePadV;

    return Container(
      color: widget.canvasColor, // fill the whole area with theme background
      child: SingleChildScrollView(
        controller: _scroll,
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kContainerMax),
            child: _buildTextField(),
          ),
        ),
      ),
    );
  }
}

class _HighlightingController extends TextEditingController {
  final String fontFamily;
  final Color  textColor;

  _HighlightingController({required this.fontFamily, required this.textColor});

  TextStyle get _base => TextStyle(
    fontSize:   18,
    height:     1.8,
    color:      textColor,
    fontFamily: fontFamily,
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return buildHighlightedSpan(text, style ?? _base);
  }
}
