// widgets/formatting_bar.dart
//
// A slim row of Markdown formatting buttons that sit between the top toolbar
// and the writing area. Hidden in focus mode.
//
// Each button wraps or unwraps a Markdown syntax pair around the current
// selection in the editor's TextEditingController.
//
// Design principles:
//   • Labelled icons, not bare symbols — "Bold B" not just "**"
//   • Tooltip shows the Markdown syntax so power users learn it
//   • If text is selected: wrap it. If cursor only: insert markers + move cursor inside
//   • If selection is already wrapped: unwrap it (toggle behaviour)
//   • The bar reads chromeColor/chromeTextColor from the theme — no hardcoded colours

import 'package:flutter/material.dart';
import '../models/settings_controller.dart';

/// One formatting action.
class _FormatAction {
  final String label;      // shown on the button
  final String tooltip;    // shown on hover
  final String prefix;     // Markdown open marker
  final String suffix;     // Markdown close marker (often same as prefix)
  final IconData? icon;    // optional icon shown alongside label

  const _FormatAction({
    required this.label,
    required this.tooltip,
    required this.prefix,
    required this.suffix,
    this.icon,
  });
}

const List<_FormatAction> _actions = [
  _FormatAction(
    label:   'Bold',
    tooltip: 'Bold  **text**',
    prefix:  '**',
    suffix:  '**',
    icon:    Icons.format_bold,
  ),
  _FormatAction(
    label:   'Italic',
    tooltip: 'Italic  _text_',
    prefix:  '_',
    suffix:  '_',
    icon:    Icons.format_italic,
  ),
  _FormatAction(
    label:   'Strike',
    tooltip: 'Strikethrough  ~~text~~',
    prefix:  '~~',
    suffix:  '~~',
    icon:    Icons.format_strikethrough,
  ),
  _FormatAction(
    label:   'Code',
    tooltip: 'Inline code  `text`',
    prefix:  '`',
    suffix:  '`',
    icon:    Icons.code,
  ),
  _FormatAction(
    label:   'Link',
    tooltip: 'Link  [text](url)',
    prefix:  '[',
    suffix:  '](url)',
    icon:    Icons.link,
  ),
  _FormatAction(
    label:   'Quote',
    tooltip: 'Blockquote  > text',
    prefix:  '> ',
    suffix:  '',
    icon:    Icons.format_quote,
  ),
  _FormatAction(
    label:   'H1',
    tooltip: 'Heading 1  # text',
    prefix:  '# ',
    suffix:  '',
    icon:    null,
  ),
  _FormatAction(
    label:   'H2',
    tooltip: 'Heading 2  ## text',
    prefix:  '## ',
    suffix:  '',
    icon:    null,
  ),
  _FormatAction(
    label:   'H3',
    tooltip: 'Heading 3  ### text',
    prefix:  '### ',
    suffix:  '',
    icon:    null,
  ),
  _FormatAction(
    label:   '• List',
    tooltip: 'Bullet list  - item',
    prefix:  '- ',
    suffix:  '',
    icon:    Icons.format_list_bulleted,
  ),
  _FormatAction(
    label:   '1. List',
    tooltip: 'Numbered list  1. item',
    prefix:  '1. ',
    suffix:  '',
    icon:    Icons.format_list_numbered,
  ),
];

class FormattingBar extends StatelessWidget {
  final TextEditingController controller;
  final SettingsController    settings;
  final VoidCallback          onChanged;
  /// Called when the user clicks the collapse chevron.
  final VoidCallback?         onCollapse;

  const FormattingBar({
    super.key,
    required this.controller,
    required this.settings,
    required this.onChanged,
    this.onCollapse,
  });

  // ---- Core formatting logic ----
  //
  // Wrap selected text with prefix+suffix, or insert markers at cursor.
  // If the selection is already wrapped, unwrap it instead.
  void _apply(_FormatAction action) {
    final ctrl      = controller;
    final text      = ctrl.text;
    final sel       = ctrl.selection;

    if (!sel.isValid) return;

    final start     = sel.start;
    final end       = sel.end;
    final selected  = text.substring(start, end);
    final prefix    = action.prefix;
    final suffix    = action.suffix;

    // Detect if already wrapped (toggle off).
    final before = start >= prefix.length
        ? text.substring(start - prefix.length, start)
        : '';
    final after = end + suffix.length <= text.length
        ? text.substring(end, end + suffix.length)
        : '';

    if (suffix.isNotEmpty && before == prefix && after == suffix) {
      // Unwrap
      final newText = text.replaceRange(
        start - prefix.length,
        end + suffix.length,
        selected,
      );
      ctrl.value = TextEditingValue(
        text:      newText,
        selection: TextSelection(
          baseOffset:  start - prefix.length,
          extentOffset: start - prefix.length + selected.length,
        ),
      );
      onChanged();
      return;
    }

    // Line-level markers (headings, lists, blockquote): apply to start of line.
    if (suffix.isEmpty) {
      // Find start of current line.
      final lineStart = text.lastIndexOf('\n', start > 0 ? start - 1 : 0);
      final insertAt  = lineStart < 0 ? 0 : lineStart + 1;
      final newText   = text.replaceRange(insertAt, insertAt, prefix);
      ctrl.value = TextEditingValue(
        text:      newText,
        selection: TextSelection.collapsed(
          offset: end + prefix.length,
        ),
      );
      onChanged();
      return;
    }

    // Inline markers: wrap selection or insert at cursor.
    if (selected.isEmpty) {
      // No selection: insert markers and place cursor between them.
      final newText = text.replaceRange(start, start, '$prefix$suffix');
      ctrl.value = TextEditingValue(
        text:      newText,
        selection: TextSelection.collapsed(offset: start + prefix.length),
      );
    } else {
      // Wrap selection.
      final newText = text.replaceRange(start, end, '$prefix$selected$suffix');
      ctrl.value = TextEditingValue(
        text:      newText,
        selection: TextSelection(
          baseOffset:   start,
          extentOffset: start + prefix.length + selected.length + suffix.length,
        ),
      );
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final s = settings;

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: s.canvasColor,       // sits on the canvas, not the chrome
        border: Border(
          bottom: BorderSide(color: s.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Scrollable action buttons.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: _actions.map((action) {
                  return Tooltip(
                    message: action.tooltip,
                    waitDuration: const Duration(milliseconds: 600),
                    child: InkWell(
                      onTap: () => _apply(action),
                      borderRadius: BorderRadius.circular(4),
                      hoverColor: s.primaryColor.withOpacity(0.08),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (action.icon != null) ...[
                              Icon(action.icon, size: 15,
                                  color: s.chromeTextColor),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              action.label,
                              style: TextStyle(
                                fontSize:   12,
                                fontFamily: 'sans-serif',
                                fontWeight: FontWeight.w500,
                                color:      s.chromeTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Collapse chevron — pinned to the right edge.
          if (onCollapse != null) ...[
            Container(width: 1, height: 20, color: s.borderColor),
            Tooltip(
              message: 'Hide toolbar',
              child: InkWell(
                onTap: onCollapse,
                borderRadius: BorderRadius.circular(4),
                hoverColor: s.primaryColor.withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  child: Icon(Icons.keyboard_arrow_up,
                      size: 16, color: s.chromeTextColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
