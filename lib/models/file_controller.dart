// models/file_controller.dart
//
// FileController handles all file system operations for the editor.
// It is a plain ChangeNotifier — no widgets, no BuildContext required
// for the I/O itself (BuildContext is passed in only where file_selector
// needs it for the native dialog on some platforms).
//
// Public API — connect these to UI buttons in WritingScreen:
//
//   await _fileController.newFile(onConfirm: () => _showDiscardDialog(context))
//   await _fileController.openFile(context)
//   await _fileController.saveFile(context)
//
// The controller exposes:
//   currentContent    — text to load into the editor after open/new
//   currentPath       — null for unsaved files, set after save/open
//   hasUnsavedChanges — drives the "unsaved" dot in the status bar
//   displayName       — filename for the title, or 'Untitled'

import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class FileController extends ChangeNotifier {
  // ---- Public state ----

  String? get currentPath => _currentPath;
  String get currentContent => _currentContent;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  String get displayName =>
      _currentPath != null ? _currentPath!.split('/').last : 'Untitled';

  // ---- Private state ----

  String? _currentPath;
  String _currentContent = '';
  bool _hasUnsavedChanges = false;

  // ---- Called by WritingScreen on every editor keystroke ----
  //
  // Keeps _currentContent in sync so saveFile() always writes the
  // latest text. Only notifies listeners on the first change (to flip
  // the unsaved indicator) — not on every keypress.

  void onContentChanged(String newContent) {
    _currentContent = newContent;
    if (!_hasUnsavedChanges) {
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  // ---- New file ----
  //
  // Clears the editor. Shows a discard confirmation if there are unsaved
  // changes — supply a dialog via [onConfirm].
  //
  // Example in WritingScreen:
  //   await _fileController.newFile(
  //     onConfirm: () => _showDiscardDialog(context),
  //   );

  Future<void> newFile({required Future<bool> Function() onConfirm}) async {
    if (_hasUnsavedChanges) {
      final confirmed = await onConfirm();
      if (!confirmed) return;
    }
    _currentPath = null;
    _currentContent = '';
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // ---- Open file ----
  //
  // Shows the OS file picker filtered to Markdown / plain text.
  // On success notifyListeners() fires — WritingScreen loads the content.
  //
  // Example in WritingScreen:
  //   await _fileController.openFile(context);

  Future<void> openFile(BuildContext context) async {
    const typeGroup = fs.XTypeGroup(
      label: 'Markdown',
      extensions: ['md', 'markdown', 'txt'],
    );

    // file_selector's openFile is imported under the 'fs' prefix to avoid
    // clashing with this method's own name.
    final file = await fs.openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return; // user cancelled

    final content = await File(file.path).readAsString();
    _currentPath = file.path;
    _currentContent = content;
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // ---- Save file ----
  //
  // Known path → overwrites silently (no dialog).
  // New document → shows a save-as dialog.
  //
  // Example in WritingScreen:
  //   await _fileController.saveFile(context);
  //
  // To add Ctrl+S, wrap the editor in a Focus widget with onKeyEvent,
  // or use the shortcuts/actions system — see WritingScreen for the hook.

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
      if (location == null) return; // user cancelled
      await _write(location.path, _currentContent);
      _currentPath = location.path;
    }

    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // ---- Internal ----

  Future<void> _write(String path, String content) =>
      File(path).writeAsString(content);
}
