// widgets/settings_panel.dart
//
// Settings drawer — fully theme-aware.
// Every colour comes from SettingsController so it adapts to Light/Sepia/Dark.
// No hardcoded colours anywhere in this file.

import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/material.dart';

import '../models/settings_controller.dart';

class SettingsPanel extends StatelessWidget {
  final SettingsController settings;
  const SettingsPanel({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final s = settings;
        return Drawer(
          backgroundColor: s.canvasColor,
          width: 300,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: s.chromeColor,
                    border: Border(
                        bottom: BorderSide(color: s.borderColor, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tune, color: s.primaryColor, size: 16),
                      const SizedBox(width: 8),
                      Text('Settings',
                          style: TextStyle(
                            color:      s.textColor,
                            fontSize:   14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'sans-serif',
                          )),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, size: 16, color: s.chromeTextColor),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 14,
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SLabel('Theme', s),
                        const SizedBox(height: 10),
                        _ThemeRadios(settings: s),

                        _SDivider(s),

                        _SLabel('Font', s),
                        const SizedBox(height: 10),
                        _FontDropdown(settings: s),

                        _SDivider(s),

                        _SLabel('Editor', s),
                        const SizedBox(height: 10),
                        _FocusRow(settings: s),

                        _SDivider(s),

                        _SLabel('Mascot', s),
                        const SizedBox(height: 10),
                        _MascotPicker(settings: s),

                        _SDivider(s),

                        _SLabel('Target WPM', s),
                        const SizedBox(height: 10),
                        _WpmSlider(settings: s),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border:
                        Border(top: BorderSide(color: s.borderColor, width: 1)),
                  ),
                  child: Text(
                    'Speed: 10 s rolling window  ·  1 word = 5 chars',
                    style: TextStyle(
                      color:      s.chromeTextColor.withOpacity(0.5),
                      fontSize:   10,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

class _SLabel extends StatelessWidget {
  final String             text;
  final SettingsController s;
  const _SLabel(this.text, this.s);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          color:       s.chromeTextColor.withOpacity(0.6),
          fontSize:    10,
          letterSpacing: 1.2,
          fontWeight:  FontWeight.w600,
          fontFamily:  'sans-serif',
        ),
      );
}

class _SDivider extends StatelessWidget {
  final SettingsController s;
  const _SDivider(this.s);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: s.borderColor, height: 1),
      );
}

// ---------------------------------------------------------------------------
// Theme radios
// ---------------------------------------------------------------------------

class _ThemeRadios extends StatelessWidget {
  final SettingsController settings;
  const _ThemeRadios({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: kEditorThemes.map((preset) {
        final selected = settings.theme == preset;
        return Expanded(
          child: GestureDetector(
            onTap: () => settings.setTheme(preset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: preset.canvas,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:  selected ? settings.primaryColor : settings.borderColor,
                  width:  selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text('Aa',
                      style: TextStyle(
                          color:      preset.text,
                          fontSize:   14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'sans-serif')),
                  const SizedBox(height: 4),
                  Text(preset.label,
                      style: TextStyle(
                          color:      preset.text.withOpacity(0.6),
                          fontSize:   9,
                          letterSpacing: 0.6,
                          fontFamily: 'sans-serif')),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Font dropdown
// ---------------------------------------------------------------------------

class _FontDropdown extends StatefulWidget {
  final SettingsController settings;
  const _FontDropdown({required this.settings});

  @override
  State<_FontDropdown> createState() => _FontDropdownState();
}

class _FontDropdownState extends State<_FontDropdown> {
  late List<String> _fonts;

  @override
  void initState() {
    super.initState();
    _fonts = _loadFonts();
    if (!_fonts.contains(widget.settings.fontFamily)) {
      _fonts = [widget.settings.fontFamily, ..._fonts];
    }
  }

  List<String> _loadFonts() {
    final dirs = [
      '/usr/share/fonts',
      '/usr/local/share/fonts',
      '${Platform.environment['HOME']}/.fonts',
      '${Platform.environment['HOME']}/.local/share/fonts',
    ];
    final families = <String>{};
    for (final dirPath in dirs) {
      try {
        final dir = Directory(dirPath);
        if (!dir.existsSync()) continue;
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is! File) continue;
          final name = entity.uri.pathSegments.last.toLowerCase();
          if (!name.endsWith('.ttf') && !name.endsWith('.otf')) continue;
          var family = entity.uri.pathSegments.last
              .replaceAll(RegExp(r'\.(ttf|otf)$', caseSensitive: false), '')
              .replaceAll(
                  RegExp(
                      r'[-_](Bold|Italic|Light|Regular|Medium|Thin|Black|'
                      r'ExtraLight|SemiBold|ExtraBold|Heavy|Condensed|Oblique)$',
                      caseSensitive: false),
                  '')
              .replaceAll('-', ' ')
              .replaceAll('_', ' ')
              .trim();
          if (family.isNotEmpty) families.add(family);
        }
      } catch (_) {}
    }
    if (families.isEmpty) return ['sans-serif', 'serif', 'monospace'];
    return families.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return DropdownButton<String>(
      value:           _fonts.contains(s.fontFamily) ? s.fontFamily : _fonts.first,
      isExpanded:      true,
      dropdownColor:   s.canvasColor,
      style:           TextStyle(color: s.textColor, fontSize: 13, fontFamily: 'sans-serif'),
      iconEnabledColor: s.chromeTextColor,
      underline:       Container(height: 1, color: s.borderColor),
      onChanged:       (v) { if (v != null) s.setFontFamily(v); },
      selectedItemBuilder: (ctx) => _fonts
          .map((f) => Align(
                alignment: Alignment.centerLeft,
                child: Text(f,
                    style: TextStyle(
                        fontFamily: f, color: s.textColor, fontSize: 13))))
          .toList(),
      items: _fonts
          .map((f) => DropdownMenuItem(
                value: f,
                child: Text(f,
                    style: TextStyle(
                        fontFamily: f, color: s.textColor, fontSize: 13))))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Focus mode toggle
// ---------------------------------------------------------------------------

class _FocusRow extends StatelessWidget {
  final SettingsController settings;
  const _FocusRow({required this.settings});

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return Row(
      children: [
        Icon(Icons.center_focus_strong_outlined,
            color: s.chromeTextColor, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Focus mode',
                  style: TextStyle(
                      color: s.textColor, fontSize: 13,
                      fontWeight: FontWeight.w600, fontFamily: 'sans-serif')),
              const SizedBox(height: 2),
              Text('Ctrl+Shift+F',
                  style: TextStyle(
                      color: s.chromeTextColor.withOpacity(0.5),
                      fontSize: 10, fontFamily: 'sans-serif')),
            ],
          ),
        ),
        Switch(
          value:              s.focusMode,
          onChanged:          s.setFocusMode,
          activeColor:        s.primaryColor,
          inactiveTrackColor: s.borderColor,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mascot picker with sprite sheet guide
// ---------------------------------------------------------------------------

class _MascotPicker extends StatelessWidget {
  final SettingsController settings;
  const _MascotPicker({required this.settings});

  Future<void> _browse() async {
    final file = await fs.openFile(acceptedTypeGroups: [
      const fs.XTypeGroup(label: 'PNG sprite sheet', extensions: ['png']),
    ]);
    if (file == null) return;
    settings.setCustomMascot(
      path:        file.path,
      frameCount:  settings.customFrameCount,
      frameWidth:  settings.customFrameWidth,
      frameHeight: settings.customFrameHeight,
    );
  }

  void _showGuide(BuildContext context) {
    final s = settings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: s.canvasColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Sprite Sheet Guide',
            style: TextStyle(color: s.textColor, fontSize: 15,
                fontWeight: FontWeight.w600, fontFamily: 'sans-serif')),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A sprite sheet is a PNG with all animation frames arranged '
                  'horizontally in a single row.',
                  style: TextStyle(color: s.chromeTextColor, fontSize: 13,
                      fontFamily: 'sans-serif', height: 1.5)),
              const SizedBox(height: 16),
              // Visual diagram drawn with Flutter widgets
              _SpriteSheetDiagram(s: s),
              const SizedBox(height: 16),
              _GuideRow('Frame size', '80 × 80 px recommended', s),
              _GuideRow('Layout',     'Left to right, single row', s),
              _GuideRow('Format',     'PNG with transparency', s),
              _GuideRow('Frames',     'Adjust the frame counter after loading', s),
              const SizedBox(height: 8),
              Text('QuillMate cycles through all frames at the configured FPS. '
                  'Use more frames for smoother animation.',
                  style: TextStyle(color: s.chromeTextColor.withOpacity(0.7),
                      fontSize: 11, fontFamily: 'sans-serif', height: 1.5)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Got it',
                style: TextStyle(color: s.primaryColor,
                    fontWeight: FontWeight.w600, fontFamily: 'sans-serif')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final hasCustom = s.customMascotPath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasCustom ? s.customMascotPath!.split('/').last : 'Using built-in mascot',
          style: TextStyle(
            color:     hasCustom ? s.primaryColor : s.chromeTextColor.withOpacity(0.5),
            fontSize:  11,
            fontStyle: hasCustom ? FontStyle.normal : FontStyle.italic,
            fontFamily: 'sans-serif',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _SBtn('Browse…', s.primaryColor, _browse),
            if (hasCustom) ...[
              const SizedBox(width: 8),
              _SBtn('Reset', s.chromeTextColor, s.clearCustomMascot),
            ],
            const Spacer(),
            // Help link
            GestureDetector(
              onTap: () => _showGuide(context),
              child: Row(
                children: [
                  Icon(Icons.help_outline, size: 13,
                      color: s.primaryColor.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text('View example',
                      style: TextStyle(
                        color:      s.primaryColor.withOpacity(0.8),
                        fontSize:   11,
                        fontFamily: 'sans-serif',
                        decoration: TextDecoration.underline,
                        decorationColor: s.primaryColor.withOpacity(0.5),
                      )),
                ],
              ),
            ),
          ],
        ),
        if (hasCustom) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Frames',
                  style: TextStyle(color: s.chromeTextColor,
                      fontSize: 12, fontFamily: 'sans-serif')),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.remove, size: 14, color: s.chromeTextColor),
                splashRadius: 14,
                onPressed: s.customFrameCount > 1
                    ? () => s.setCustomMascot(
                          path: s.customMascotPath!,
                          frameCount: s.customFrameCount - 1,
                          frameWidth: s.customFrameWidth,
                          frameHeight: s.customFrameHeight)
                    : null,
              ),
              Text('${s.customFrameCount}',
                  style: TextStyle(
                      color: s.primaryColor, fontSize: 16,
                      fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.add, size: 14, color: s.chromeTextColor),
                splashRadius: 14,
                onPressed: () => s.setCustomMascot(
                  path: s.customMascotPath!,
                  frameCount: s.customFrameCount + 1,
                  frameWidth: s.customFrameWidth,
                  frameHeight: s.customFrameHeight),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _GuideRow extends StatelessWidget {
  final String             label;
  final String             value;
  final SettingsController s;
  const _GuideRow(this.label, this.value, this.s);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: TextStyle(color: s.chromeTextColor, fontSize: 12,
                      fontWeight: FontWeight.w600, fontFamily: 'sans-serif')),
            ),
            Expanded(
              child: Text(value,
                  style: TextStyle(color: s.textColor, fontSize: 12,
                      fontFamily: 'sans-serif')),
            ),
          ],
        ),
      );
}

/// A simple drawn diagram showing a sprite sheet layout.
class _SpriteSheetDiagram extends StatelessWidget {
  final SettingsController s;
  const _SpriteSheetDiagram({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color:        s.chromeColor,
        border:       Border.all(color: s.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: List.generate(4, (i) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: s.primaryColor.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(3),
                color: s.primaryColor.withOpacity(0.06),
              ),
              child: Center(
                child: Text('f${i + 1}',
                    style: TextStyle(
                      color:      s.primaryColor,
                      fontSize:   11,
                      fontFamily: 'monospace',
                    )),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SBtn extends StatelessWidget {
  final String       label;
  final Color        color;
  final VoidCallback onPressed;
  const _SBtn(this.label, this.color, this.onPressed);

  @override
  Widget build(BuildContext context) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side:            BorderSide(color: color.withOpacity(0.4)),
          padding:         const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize:     Size.zero,
          tapTargetSize:   MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: onPressed,
        child: Text(label,
            style: const TextStyle(fontSize: 12, fontFamily: 'sans-serif')),
      );
}

// ---------------------------------------------------------------------------
// WPM slider
// ---------------------------------------------------------------------------

class _WpmSlider extends StatelessWidget {
  final SettingsController settings;
  const _WpmSlider({required this.settings});

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Target',
                style: TextStyle(color: s.textColor, fontSize: 13,
                    fontWeight: FontWeight.w600, fontFamily: 'sans-serif')),
            const Spacer(),
            Text('${s.targetWpm}',
                style: TextStyle(color: s.primaryColor, fontSize: 20,
                    fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            Text(' wpm',
                style: TextStyle(color: s.chromeTextColor.withOpacity(0.5),
                    fontSize: 11, fontFamily: 'sans-serif')),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor:   s.primaryColor,
            inactiveTrackColor: s.borderColor,
            thumbColor:         s.primaryColor,
            overlayColor:       s.primaryColor.withOpacity(0.12),
            trackHeight:        3,
          ),
          child: Slider(
            value:     s.targetWpm.toDouble(),
            min:       kMinTargetWpm.toDouble(),
            max:       kMaxTargetWpm.toDouble(),
            divisions: kMaxTargetWpm - kMinTargetWpm,
            onChanged: (v) => s.setTargetWpm(v.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$kMinTargetWpm',
                  style: TextStyle(
                      color: s.chromeTextColor.withOpacity(0.4),
                      fontSize: 10, fontFamily: 'sans-serif')),
              Text('$kMaxTargetWpm',
                  style: TextStyle(
                      color: s.chromeTextColor.withOpacity(0.4),
                      fontSize: 10, fontFamily: 'sans-serif')),
            ],
          ),
        ),
      ],
    );
  }
}
