// models/file_controller.dart
//
// All file I/O: new, open, save (Markdown), export (HTML, PDF).
//
// Export approach:
//   HTML — converts Markdown to a self-contained HTML file using a simple
//           regex-based renderer. No external package needed.
//   PDF  — uses the 'pdf' package (pure Dart) to build a page from the
//           Markdown plain text. Formatted sections (headings, bold) are
//           parsed from the content and styled with pdf.TextStyle.

import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FileController extends ChangeNotifier {
  String? get currentPath       => _currentPath;
  String  get currentContent    => _currentContent;
  bool    get hasUnsavedChanges => _hasUnsavedChanges;

  String get displayName =>
      _currentPath != null ? _currentPath!.split('/').last : 'Untitled';

  String? _currentPath;
  String  _currentContent = '';
  bool    _hasUnsavedChanges = false;

  // ---- Content tracking ----

  void onContentChanged(String newContent) {
    _currentContent = newContent;
    if (!_hasUnsavedChanges) {
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  // ---- New ----

  Future<void> newFile({required Future<bool> Function() onConfirm}) async {
    if (_hasUnsavedChanges) {
      if (!await onConfirm()) return;
    }
    _currentPath = null;
    _currentContent = '';
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // ---- Open ----

  Future<void> openFile(BuildContext context) async {
    final file = await fs.openFile(acceptedTypeGroups: [
      const fs.XTypeGroup(
          label: 'Markdown', extensions: ['md', 'markdown', 'txt']),
    ]);
    if (file == null) return;
    final content = await File(file.path).readAsString();
    _currentPath = file.path;
    _currentContent = content;
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // ---- Save (Markdown) ----

  Future<void> saveFile(BuildContext context) async {
    if (_currentPath != null) {
      await _write(_currentPath!, _currentContent);
    } else {
      final location = await fs.getSaveLocation(
        acceptedTypeGroups: [
          const fs.XTypeGroup(label: 'Markdown', extensions: ['md']),
        ],
        suggestedName: 'untitled.md',
      );
      if (location == null) return;
      await _write(location.path, _currentContent);
      _currentPath = location.path;
    }
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // ---- Export HTML ----
  //
  // Converts Markdown to a self-contained HTML page.
  // The conversion handles the most common Markdown constructs:
  // headings, bold, italic, code, blockquotes, lists, horizontal rules.

  Future<void> exportAsHtml(BuildContext context) async {
    final location = await fs.getSaveLocation(
      acceptedTypeGroups: [
        const fs.XTypeGroup(label: 'HTML', extensions: ['html']),
      ],
      suggestedName: _htmlName(),
    );
    if (location == null) return;

    final html = _markdownToHtml(_currentContent);
    await _write(location.path, html);
  }

  // ---- Export PDF ----
  //
  // Builds a PDF using the 'pdf' pure-Dart package.
  // Each Markdown line is inspected and styled accordingly.
  // No external tools (wkhtmltopdf etc.) required.

  Future<void> exportAsPdf(BuildContext context) async {
    final location = await fs.getSaveLocation(
      acceptedTypeGroups: [
        const fs.XTypeGroup(label: 'PDF', extensions: ['pdf']),
      ],
      suggestedName: _pdfName(),
    );
    if (location == null) return;

    final pdfBytes = await _buildPdf(_currentContent);
    await File(location.path).writeAsBytes(pdfBytes);
  }

  // ---- Internal helpers ----

  Future<void> _write(String path, String content) =>
      File(path).writeAsString(content);

  String _htmlName() {
    if (_currentPath == null) return 'untitled.html';
    return _currentPath!
        .split('/')
        .last
        .replaceAll(RegExp(r'\.(md|markdown|txt)$'), '.html');
  }

  String _pdfName() {
    if (_currentPath == null) return 'untitled.pdf';
    return _currentPath!
        .split('/')
        .last
        .replaceAll(RegExp(r'\.(md|markdown|txt)$'), '.pdf');
  }

  // ---------------------------------------------------------------------------
  // Markdown → HTML
  // ---------------------------------------------------------------------------

  String _markdownToHtml(String markdown) {
    final lines = markdown.split('\n');
    final buf = StringBuffer();

    buf.writeln('<!DOCTYPE html>');
    buf.writeln('<html lang="en"><head><meta charset="UTF-8">');
    buf.writeln('<meta name="viewport" content="width=device-width">');
    buf.writeln('<title>${_escHtml(displayName)}</title>');
    buf.writeln('<style>');
    buf.writeln('''
      body { font-family: Georgia, serif; max-width: 800px; margin: 60px auto;
             padding: 0 24px; font-size: 18px; line-height: 1.8;
             color: #1b1c1c; background: #fcf9f8; }
      h1,h2,h3,h4,h5,h6 { font-family: sans-serif; color: #006a62;
                           margin-top: 2em; }
      code { background: #f0eded; padding: 2px 6px; border-radius: 3px;
             font-size: 0.9em; }
      pre  { background: #f0eded; padding: 16px; border-radius: 4px;
             overflow: auto; }
      blockquote { border-left: 3px solid #bcc9c6; margin-left: 0;
                   padding-left: 1em; color: #6d7a77; }
      hr { border: none; border-top: 1px solid #bcc9c6; margin: 2em 0; }
    ''');
    buf.writeln('</style></head><body>');

    bool inCodeBlock = false;
    bool inUl = false;
    bool inOl = false;

    for (final raw in lines) {
      final line = raw;

      // Fenced code block
      if (line.startsWith('```')) {
        if (inUl) { buf.writeln('</ul>'); inUl = false; }
        if (inOl) { buf.writeln('</ol>'); inOl = false; }
        if (inCodeBlock) {
          buf.writeln('</code></pre>');
          inCodeBlock = false;
        } else {
          buf.writeln('<pre><code>');
          inCodeBlock = true;
        }
        continue;
      }
      if (inCodeBlock) { buf.writeln(_escHtml(line)); continue; }

      // Headings
      final hMatch = RegExp(r'^(#{1,6})\s+(.+)').firstMatch(line);
      if (hMatch != null) {
        if (inUl) { buf.writeln('</ul>'); inUl = false; }
        if (inOl) { buf.writeln('</ol>'); inOl = false; }
        final level = hMatch.group(1)!.length;
        buf.writeln('<h$level>${_inlineHtml(hMatch.group(2)!)}</h$level>');
        continue;
      }

      // HR
      if (RegExp(r'^[-*]{3,}$').hasMatch(line.trim())) {
        buf.writeln('<hr>'); continue;
      }

      // Unordered list
      if (RegExp(r'^[-*+]\s').hasMatch(line)) {
        if (inOl) { buf.writeln('</ol>'); inOl = false; }
        if (!inUl) { buf.writeln('<ul>'); inUl = true; }
        buf.writeln('<li>${_inlineHtml(line.replaceFirst(RegExp(r'^[-*+]\s'), ''))}</li>');
        continue;
      }

      // Ordered list
      if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        if (inUl) { buf.writeln('</ul>'); inUl = false; }
        if (!inOl) { buf.writeln('<ol>'); inOl = true; }
        buf.writeln('<li>${_inlineHtml(line.replaceFirst(RegExp(r'^\d+\.\s'), ''))}</li>');
        continue;
      }

      // Close open lists
      if (inUl) { buf.writeln('</ul>'); inUl = false; }
      if (inOl) { buf.writeln('</ol>'); inOl = false; }

      // Blockquote
      if (line.startsWith('> ')) {
        buf.writeln('<blockquote>${_inlineHtml(line.substring(2))}</blockquote>');
        continue;
      }

      // Blank line
      if (line.trim().isEmpty) { buf.writeln('<br>'); continue; }

      // Paragraph
      buf.writeln('<p>${_inlineHtml(line)}</p>');
    }

    if (inUl) buf.writeln('</ul>');
    if (inOl) buf.writeln('</ol>');

    buf.writeln('</body></html>');
    return buf.toString();
  }

  /// Apply inline Markdown (bold, italic, code, links) to a string.
  String _inlineHtml(String s) {
    s = _escHtml(s);
    s = s.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => '<strong>${m[1]}</strong>');
    s = s.replaceAllMapped(RegExp(r'__(.+?)__'),     (m) => '<strong>${m[1]}</strong>');
    s = s.replaceAllMapped(RegExp(r'\*(.+?)\*'),     (m) => '<em>${m[1]}</em>');
    s = s.replaceAllMapped(RegExp(r'_(.+?)_'),       (m) => '<em>${m[1]}</em>');
    s = s.replaceAllMapped(RegExp(r'~~(.+?)~~'),     (m) => '<del>${m[1]}</del>');
    s = s.replaceAllMapped(RegExp(r'`(.+?)`'),       (m) => '<code>${m[1]}</code>');
    s = s.replaceAllMapped(RegExp(r'\[(.+?)\]\((.+?)\)'),
        (m) => '<a href="${m[2]}">${m[1]}</a>');
    return s;
  }

  String _escHtml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  // ---------------------------------------------------------------------------
  // Markdown → PDF (using the 'pdf' pure-Dart package)
  // ---------------------------------------------------------------------------

  Future<Uint8List> _buildPdf(String markdown) async {
    final doc = pw.Document();

    final lines = markdown.split('\n');
    final widgets = <pw.Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 8));
        continue;
      }

      // Headings
      final hMatch = RegExp(r'^(#{1,6})\s+(.+)').firstMatch(line);
      if (hMatch != null) {
        final level = hMatch.group(1)!.length;
        final fontSize = [32.0, 26.0, 22.0, 18.0, 16.0, 14.0][level - 1];
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 4),
          child: pw.Text(
            hMatch.group(2)!,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ));
        continue;
      }

      // Blockquote
      if (line.startsWith('> ')) {
        widgets.add(pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: PdfColors.grey400, width: 3),
            ),
          ),
          padding: const pw.EdgeInsets.only(left: 12, top: 2, bottom: 2),
          child: pw.Text(line.substring(2),
              style: const pw.TextStyle(color: PdfColors.grey600)),
        ));
        continue;
      }

      // HR
      if (RegExp(r'^[-*]{3,}$').hasMatch(line.trim())) {
        widgets.add(pw.Divider(color: PdfColors.grey300));
        continue;
      }

      // Normal paragraph (strip basic inline syntax for PDF)
      final plain = _stripInlineMd(line);
      widgets.add(pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Text(plain,
            style: const pw.TextStyle(fontSize: 12),
            softWrap: true),
      ));
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(56),
        build: (_) => widgets,
      ),
    );

    return doc.save();
  }

  /// Strip common inline Markdown markers for plain-text PDF output.
  /// Uses replaceAllMapped because Dart's replaceAll does not support
  /// backreference strings like r'$1' — it treats them as literals.
  String _stripInlineMd(String s) {
    String strip(String input, RegExp re) =>
        input.replaceAllMapped(re, (m) => m.group(1) ?? '');

    s = strip(s, RegExp(r'\*\*(.+?)\*\*'));
    s = strip(s, RegExp(r'__(.+?)__'));
    s = strip(s, RegExp(r'\*(.+?)\*'));
    s = strip(s, RegExp(r'_(.+?)_'));
    s = strip(s, RegExp(r'~~(.+?)~~'));
    s = strip(s, RegExp(r'`(.+?)`'));
    s = s.replaceAllMapped(RegExp(r'\[(.+?)\]\(.+?\)'), (m) => m.group(1) ?? '');
    return s;
  }
}
