// utils/markdown_highlighter.dart
//
// Syntax highlighting that respects the current theme.
//
// On light themes: syntax uses the brand primary teal (#006a62) family.
// On dark themes:  syntax uses the bright inverse-primary (#5fdacc) family.
//
// The palette is picked by reading the luminance of the text colour:
//   light text (luminance > 0.5) → dark background → dark palette
//   dark text  (luminance ≤ 0.5) → light background → light palette

import 'package:flutter/painting.dart';

class _Palette {
  final Color heading;
  final Color bold;
  final Color italic;
  final Color code;
  final Color link;
  final Color blockquote;
  const _Palette({
    required this.heading,
    required this.bold,
    required this.italic,
    required this.code,
    required this.link,
    required this.blockquote,
  });
}

// Light background — uses design-doc teal family and warm accents.
// Goal: syntax feels like part of the brand, not visual noise.
const _lightPalette = _Palette(
  heading:    Color(0xFF006A62), // primary teal — headings are landmarks
  bold:       Color(0xFF004D47), // darker teal — strong emphasis
  italic:     Color(0xFF5D4037), // warm brown — gentle emphasis
  code:       Color(0xFF984728), // tertiary orange-brown — code stands out
  link:       Color(0xFF006A62), // teal — links match headings
  blockquote: Color(0xFF6D7A77), // outline-variant grey — quoted, receded
);

// Dark background — bright versions of the same roles.
const _darkPalette = _Palette(
  heading:    Color(0xFF5FDACC), // inverse-primary bright teal
  bold:       Color(0xFF7EF6E8), // primary-fixed — brightest teal
  italic:     Color(0xFFFFB59B), // tertiary-fixed-dim — warm highlight
  code:       Color(0xFFE88561), // tertiary-container — orange
  link:       Color(0xFF5FDACC), // same as heading
  blockquote: Color(0xFF9CA3AF), // muted grey
);

class _Rule {
  final RegExp pattern;
  final Color Function(_Palette) color;
  final FontWeight? weight;
  const _Rule(this.pattern, this.color, {this.weight});
}

final List<_Rule> _rules = [
  _Rule(RegExp(r'^#{1,6} .+', multiLine: true), (p) => p.heading,
      weight: FontWeight.w600),
  _Rule(RegExp(r'(\*\*|__).+?\1'),              (p) => p.bold,
      weight: FontWeight.bold),
  _Rule(RegExp(r'(?<!\*)(\*|_)(?!\*)(?!\s).+?(?<!\s)\1(?!\*)'), (p) => p.italic),
  _Rule(RegExp(r'`[^`]+`'),                     (p) => p.code),
  _Rule(RegExp(r'\[.+?\]\(.+?\)'),              (p) => p.link),
  _Rule(RegExp(r'^> .+', multiLine: true),      (p) => p.blockquote),
];

TextSpan buildHighlightedSpan(String text, TextStyle baseStyle) {
  if (text.isEmpty) return TextSpan(text: text, style: baseStyle);

  final textColor = baseStyle.color ?? const Color(0xFF1B1C1C);
  final isLightText = textColor.computeLuminance() > 0.5;
  final palette = isLightText ? _darkPalette : _lightPalette;

  final annotations = <_Annotation>[];
  for (final rule in _rules) {
    for (final match in rule.pattern.allMatches(text)) {
      final overlaps = annotations.any(
        (a) => match.start < a.end && match.end > a.start,
      );
      if (!overlaps) {
        annotations.add(_Annotation(
          match.start, match.end,
          TextStyle(
            color:      rule.color(palette),
            fontWeight: rule.weight,
          ),
        ));
      }
    }
  }
  annotations.sort((a, b) => a.start.compareTo(b.start));

  final spans = <TextSpan>[];
  int cursor = 0;
  for (final ann in annotations) {
    if (ann.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, ann.start), style: baseStyle));
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
  final int start;
  final int end;
  final TextStyle style;
  const _Annotation(this.start, this.end, this.style);
}
