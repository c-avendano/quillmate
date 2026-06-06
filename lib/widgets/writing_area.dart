// widgets/writing_area.dart
//
// WritingArea — the main editing surface.
//
// Normal mode:
//   Fixed side padding, TextField expands to fill all vertical space.
//
// Focus mode (Apostrophe-style):
//   • Text column is constrained to kFocusColumnWidth (680 px) and
//     centred horizontally.
//   • The TextField is NOT expanded; it grows with content.
//   • A SingleChildScrollView wraps it so long documents scroll.
//   • Top padding (kFocusTopPadding) pushes the first line down to a
//     comfortable eye-level position — roughly 1/3 from the top.
//   This means you always write near the centre of the screen rather
//   than at the very top edge.
//
// Font and colour:
//   fontFamily and textColor are passed in from SettingsController so
//   the editor reflects the user's current preferences immediately.

import 'package:flutter/material.dart';

import '../utils/markdown_highlighter.dart';

typedef OnKeyPress = void Function();
typedef OnChanged  = void Function(String text);

/// Constrained prose width in focus mode (~68 chars at 16 px monospace).
const double kFocusColumnWidth = 680;

/// Top padding in focus mode — pushes writing zone to eye-level.
const double kFocusTopPadding = 180;

class WritingArea extends StatefulWidget {
  final OnKeyPress onKeyPress;
  final OnChanged  onChanged;
  final bool       focusMode;
  final String     fontFamily;
  final Color      textColor;

  const WritingArea({
    super.key,
    required this.onKeyPress,
    required this.onChanged,
    this.focusMode  = false,
    this.fontFamily = 'monospace',
    this.textColor  = const Color(0xFFE2E2E2),
  });

  @override
  State<WritingArea> createState() => WritingAreaState();
}

class WritingAreaState extends State<WritingArea> {
  late _HighlightingController _controller;
  final FocusNode      _focusNode     = FocusNode();
  final ScrollController _scrollCtrl  = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = _HighlightingController(
      fontFamily: widget.fontFamily,
      textColor:  widget.textColor,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void didUpdateWidget(WritingArea old) {
    super.didUpdateWidget(old);
    // Rebuild the controller when font/colour changes so the style propagates.
    if (old.fontFamily != widget.fontFamily || old.textColor != widget.textColor) {
      final text = _controller.text;
      final sel  = _controller.selection;
      _controller.dispose();
      _controller = _HighlightingController(
        fontFamily: widget.fontFamily,
        textColor:  widget.textColor,
      );
      _controller.value = TextEditingValue(text: text, selection: sel);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void loadContent(String text) {
    _controller.value = TextEditingValue(
      text:      text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _focusNode.requestFocus();
  }

  // ---- Shared text field ----

  TextStyle get _style => TextStyle(
    fontSize:   16,
    height:     1.65,
    color:      widget.textColor,
    fontFamily: widget.fontFamily,
  );

  // Normal mode: expands to fill all available vertical space.
  Widget _buildExpandedField() {
    return TextField(
      controller: _controller,
      focusNode:  _focusNode,
      maxLines:   null,
      expands:    true,
      style:      _style,
      cursorColor: const Color(0xFF7EC8E3),
      cursorWidth: 2,
      decoration:  _decoration(),
      onChanged:   _onChanged,
    );
  }

  // Focus mode: grows with content, scrolled by SingleChildScrollView.
  Widget _buildGrowingField() {
    return TextField(
      controller: _controller,
      focusNode:  _focusNode,
      maxLines:   null,   // grows with content
      expands:    false,  // must be false when inside a scroll view
      style:      _style,
      cursorColor: const Color(0xFF7EC8E3),
      cursorWidth: 2,
      decoration:  _decoration(),
      onChanged:   _onChanged,
    );
  }

  InputDecoration _decoration() => InputDecoration(
    border:    InputBorder.none,
    hintText:  '# Start writing…\n\nMarkdown is supported.',
    hintStyle: TextStyle(
      color:      widget.textColor.withOpacity(0.25),
      fontFamily: widget.fontFamily,
      fontSize:   16,
      height:     1.65,
    ),
  );

  void _onChanged(String text) {
    widget.onKeyPress();
    widget.onChanged(text);
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {

    // ---- Normal mode ----
    if (!widget.focusMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(48, 32, 48, 32),
        child: _buildExpandedField(),
      );
    }

    // ---- Focus mode ----
    //
    // Layout:
    //   SingleChildScrollView          (scrolls the whole document)
    //   └─ Center                      (centres column horizontally)
    //      └─ ConstrainedBox (680 px)  (comfortable prose width)
    //         └─ Padding               (eye-level top offset + bottom space)
    //            └─ TextField          (grows with content, no expands)
    //
    // The top padding pushes the first line of text ~1/3 down the screen
    // so you're writing in the natural focal zone, not the top-left corner.
    // As the document grows the user scrolls normally.

    return SingleChildScrollView(
      controller: _scrollCtrl,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kFocusColumnWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, kFocusTopPadding, 0, 120),
            child: _buildGrowingField(),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Syntax-highlighting controller
// Rebuilds its base style when font/colour changes (via didUpdateWidget above).
// ---------------------------------------------------------------------------

class _HighlightingController extends TextEditingController {
  final String fontFamily;
  final Color  textColor;

  _HighlightingController({required this.fontFamily, required this.textColor});

  TextStyle get _base => TextStyle(
    fontSize:   16,
    height:     1.65,
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
