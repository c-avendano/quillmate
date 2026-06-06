// widgets/writing_area.dart
//
// WritingArea is the main editing surface.
//
// It uses a TextField with a RichTextController (a TextEditingController
// subclass) that re-runs the Markdown highlighter on every edit.
// The syntax colors are applied via buildTextSpan(), which Flutter calls
// whenever it repaints the field.
//
// Key-press counting: we listen to onChanged (fires for every character)
// rather than raw keyboard events so we don't double-count modifier keys.

import 'package:flutter/material.dart';

import '../utils/markdown_highlighter.dart';

/// Callback fired on every character change.
typedef OnKeyPress = void Function();

class WritingArea extends StatefulWidget {
  final OnKeyPress onKeyPress;

  const WritingArea({super.key, required this.onKeyPress});

  @override
  State<WritingArea> createState() => _WritingAreaState();
}

class _WritingAreaState extends State<WritingArea> {
  late final _HighlightingController _controller;
  final FocusNode _focusNode = FocusNode();

  static const _baseStyle = TextStyle(
    fontSize: 16,
    height: 1.65,
    color: Color(0xFFE2E2E2),
    fontFamily: 'monospace',
  );

  @override
  void initState() {
    super.initState();
    _controller = _HighlightingController();
    // Auto-focus so the user can start typing immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 32, 48, 32),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,  // Expand to fill all available vertical space.
        expands: true,
        style: _baseStyle,
        cursorColor: const Color(0xFF7EC8E3),
        cursorWidth: 2,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '# Start writing…\n\nMarkdown is supported.',
          hintStyle: TextStyle(
            color: Color(0x44E2E2E2),
            fontFamily: 'monospace',
            fontSize: 16,
            height: 1.65,
          ),
        ),
        onChanged: (_) {
          // Called once per edit (insertion or deletion).
          widget.onKeyPress();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RichText-capable TextEditingController
// ---------------------------------------------------------------------------

/// Overrides buildTextSpan() to apply Markdown syntax highlighting.
/// Everything else is standard TextEditingController behaviour.
class _HighlightingController extends TextEditingController {
  static const _baseStyle = TextStyle(
    fontSize: 16,
    height: 1.65,
    color: Color(0xFFE2E2E2),
    fontFamily: 'monospace',
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Delegate to our utility function.
    return buildHighlightedSpan(text, style ?? _baseStyle);
  }
}
