// utils/markdown_highlighter.dart
//
// A lightweight TextSpan builder that applies basic Markdown syntax colors
// to a plain text string. This is intentionally simple — it is NOT a full
// parser. It handles the most common patterns so the editor feels alive
// without requiring a heavy dependency.
//
// To extend: add more RegExp entries to [_rules] below.

import 'package:flutter/painting.dart';

// ---------------------------------------------------------------------------
// Color palette for syntax highlighting (dark-theme oriented)
// ---------------------------------------------------------------------------
const _colorHeading    = Color(0xFF7EC8E3); // blue-ish
const _colorBold       = Color(0xFFFFD700); // gold
const _colorItalic     = Color(0xFFB0E0A8); // soft green
const _colorCode       = Color(0xFFE8A87C); // orange
const _colorLink       = Color(0xFF9B8EF0); // lavender
const _colorBlockquote = Color(0xFF999999); // grey
const _colorHr         = Color(0xFF666666); // dimmer grey
const _colorDefault    = Color(0xFFE2E2E2); // near-white

// A single syntax rule: a pattern and the style to apply.
class _Rule {
  final RegExp pattern;
  final TextStyle style;
  const _Rule(this.pattern, this.style);
}

final List<_Rule> _rules = [
  // Headings: # H1  ## H2  etc.
  _Rule(
    RegExp(r'^#{1,6} .+', multiLine: true),
    const TextStyle(color: _colorHeading, fontWeight: FontWeight.bold),
  ),
  // Bold: **text** or __text__
  _Rule(
    RegExp(r'(\*\*|__).+?\1'),
    const TextStyle(color: _colorBold, fontWeight: FontWeight.bold),
  ),
  // Italic: *text* or _text_  (non-greedy, avoids colliding with bold)
  _Rule(
    RegExp(r'(?<!\*)(\*|_)(?!\*)(?!\s).+?(?<!\s)\1(?!\*)'),
    const TextStyle(color: _colorItalic, fontStyle: FontStyle.italic),
  ),
  // Inline code: `code`
  _Rule(
    RegExp(r'`[^`]+`'),
    const TextStyle(
      color: _colorCode,
      fontFamily: 'monospace',
      backgroundColor: Color(0x22FFFFFF),
    ),
  ),
  // Links: [text](url)
  _Rule(
    RegExp(r'\[.+?\]\(.+?\)'),
    const TextStyle(color: _colorLink, decoration: TextDecoration.underline),
  ),
  // Blockquote lines: > text
  _Rule(
    RegExp(r'^> .+', multiLine: true),
    const TextStyle(color: _colorBlockquote, fontStyle: FontStyle.italic),
  ),
  // Horizontal rule: --- or ***
  _Rule(
    RegExp(r'^[-*]{3,}$', multiLine: true),
    const TextStyle(color: _colorHr),
  ),
];

/// Builds a [TextSpan] tree with syntax-highlighted regions.
///
/// The approach: we scan the text for each rule in order, collecting
/// non-overlapping match ranges and annotating them with their styles.
/// Unmatched regions get the default style.
TextSpan buildHighlightedSpan(String text, TextStyle baseStyle) {
  if (text.isEmpty) {
    return TextSpan(text: text, style: baseStyle);
  }

  // Collect all (start, end, style) annotations.
  final annotations = <_Annotation>[];

  for (final rule in _rules) {
    for (final match in rule.pattern.allMatches(text)) {
      // Skip if this range overlaps an already-claimed region.
      final overlaps = annotations.any(
        (a) => match.start < a.end && match.end > a.start,
      );
      if (!overlaps) {
        annotations.add(_Annotation(match.start, match.end, rule.style));
      }
    }
  }

  // Sort by start position.
  annotations.sort((a, b) => a.start.compareTo(b.start));

  // Build the TextSpan list.
  final spans = <TextSpan>[];
  int cursor = 0;

  for (final ann in annotations) {
    if (ann.start > cursor) {
      // Plain text before this annotation.
      spans.add(TextSpan(
        text: text.substring(cursor, ann.start),
        style: baseStyle.copyWith(color: _colorDefault),
      ));
    }
    spans.add(TextSpan(
      text: text.substring(ann.start, ann.end),
      style: baseStyle.merge(ann.style),
    ));
    cursor = ann.end;
  }

  // Remaining plain text.
  if (cursor < text.length) {
    spans.add(TextSpan(
      text: text.substring(cursor),
      style: baseStyle.copyWith(color: _colorDefault),
    ));
  }

  return TextSpan(children: spans, style: baseStyle);
}

class _Annotation {
  final int start;
  final int end;
  final TextStyle style;
  const _Annotation(this.start, this.end, this.style);
}
