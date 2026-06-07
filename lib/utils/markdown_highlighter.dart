// utils/markdown_highlighter.dart
//
// Builds a syntax-highlighted TextSpan from plain Markdown text.
//
// THEME AWARENESS
// ───────────────
// The old version used hardcoded dark-theme colours. This version derives
// all syntax colours from the base text colour so the output is readable on
// any background (white, black, sepia, or anything else).
//
// The approach: compute whether the theme is "dark" or "light" from the
// luminance of the base text colour, then choose a matching palette.
// Syntax colours are picked to have enough contrast on the theme background.
//
// Public API:
//   buildHighlightedSpan(text, baseStyle)  →  TextSpan

import 'package:flutter/painting.dart';

// ---------------------------------------------------------------------------
// Palette selection
// ---------------------------------------------------------------------------

class _Palette {
  final Color heading;
  final Color bold;
  final Color italic;
  final Color code;
  final Color link;
  final Color blockquote;
  final Color hr;
  const _Palette({
    required this.heading,
    required this.bold,
    required this.italic,
    required this.code,
    required this.link,
    required this.blockquote,
    required this.hr,
  });
}

// Dark background palette — vivid colours that pop on dark backgrounds.
const _darkPalette = _Palette(
  heading:    Color(0xFF7EC8E3), // sky blue
  bold:       Color(0xFFFFD700), // gold
  italic:     Color(0xFFB0E0A8), // sage green
  code:       Color(0xFFE8A87C), // warm orange
  link:       Color(0xFF9B8EF0), // lavender
  blockquote: Color(0xFF9E9E9E), // mid-grey
  hr:         Color(0xFF616161), // dim grey
);

// Light background palette — muted, ink-like colours readable on white/sepia.
const _lightPalette = _Palette(
  heading:    Color(0xFF1565C0), // deep blue
  bold:       Color(0xFF5D4037), // dark brown
  italic:     Color(0xFF2E7D32), // forest green
  code:       Color(0xFFBF360C), // dark orange-red
  link:       Color(0xFF4527A0), // deep purple
  blockquote: Color(0xFF757575), // medium grey
  hr:         Color(0xFFBDBDBD), // light grey
);

// ---------------------------------------------------------------------------
// Rule definition
// ---------------------------------------------------------------------------

class _Rule {
  final RegExp  pattern;
  final Color Function(_Palette) color;
  const _Rule(this.pattern, this.color);
}

final List<_Rule> _rules = [
  _Rule(RegExp(r'^#{1,6} .+',  multiLine: true), (p) => p.heading),
  _Rule(RegExp(r'(\*\*|__).+?\1'),               (p) => p.bold),
  _Rule(RegExp(r'(?<!\*)(\*|_)(?!\*)(?!\s).+?(?<!\s)\1(?!\*)'), (p) => p.italic),
  _Rule(RegExp(r'`[^`]+`'),                      (p) => p.code),
  _Rule(RegExp(r'\[.+?\]\(.+?\)'),               (p) => p.link),
  _Rule(RegExp(r'^> .+', multiLine: true),       (p) => p.blockquote),
  _Rule(RegExp(r'^[-*]{3,}$', multiLine: true),  (p) => p.hr),
];

// ---------------------------------------------------------------------------
// Public builder
// ---------------------------------------------------------------------------

/// Returns a [TextSpan] with Markdown syntax highlighting applied.
/// [baseStyle] carries both the font family and the base text colour;
/// syntax colours are chosen based on the luminance of that colour.
TextSpan buildHighlightedSpan(String text, TextStyle baseStyle) {
  if (text.isEmpty) return TextSpan(text: text, style: baseStyle);

  // Pick palette based on whether the text colour is light or dark.
  // Light text  → dark background → use the dark palette.
  // Dark text   → light background → use the light palette.
  final textColor = baseStyle.color ?? const Color(0xFFE2E2E2);
  final isLightText = textColor.computeLuminance() > 0.5;
  final palette = isLightText ? _darkPalette : _lightPalette;

  // Collect non-overlapping annotations.
  final annotations = <_Annotation>[];
  for (final rule in _rules) {
    for (final match in rule.pattern.allMatches(text)) {
      final overlaps = annotations.any(
        (a) => match.start < a.end && match.end > a.start,
      );
      if (!overlaps) {
        annotations.add(_Annotation(
          match.start, match.end,
          TextStyle(color: rule.color(palette), fontWeight:
              // Preserve bold weight for bold matches.
              rule.pattern.pattern.contains(r'\*\*') ? FontWeight.bold : null),
        ));
      }
    }
  }
  annotations.sort((a, b) => a.start.compareTo(b.start));

  // Build TextSpan list.
  final spans = <TextSpan>[];
  int cursor = 0;
  for (final ann in annotations) {
    if (ann.start > cursor) {
      spans.add(TextSpan(
        text:  text.substring(cursor, ann.start),
        style: baseStyle,
      ));
    }
    spans.add(TextSpan(
      text:  text.substring(ann.start, ann.end),
      style: baseStyle.merge(ann.style),
    ));
    cursor = ann.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }

  return TextSpan(children: spans, style: baseStyle);
}

class _Annotation {
  final int       start;
  final int       end;
  final TextStyle style;
  const _Annotation(this.start, this.end, this.style);
}
