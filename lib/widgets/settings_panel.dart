// widgets/settings_panel.dart
//
// Settings drawer — slides in from the right.
// Reads and writes only SettingsController.
//
// Sections:
//   • Background (White / Black / Sepia radio buttons)
//   • Font (system font dropdown)
//   • Focus mode toggle
//   • Target WPM slider

import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;

import 'package:flutter/material.dart';

import '../models/settings_controller.dart';

class SettingsPanel extends StatelessWidget {
  final SettingsController settings;
  const SettingsPanel({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1E1E3A),
      width: 300,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ---- Header ----
                Row(
                  children: [
                    const Icon(Icons.tune, color: Color(0xFF7EC8E3), size: 18),
                    const SizedBox(width: 8),
                    const Text('Settings',
                        style: TextStyle(
                          color: Color(0xFF7EC8E3),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        )),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: const Color(0x66E2E2E2),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ---- Background ----
                _Label('Background'),
                const SizedBox(height: 10),
                _ThemeRadios(settings: settings),

                _Gap(),

                // ---- Font ----
                _Label('Font'),
                const SizedBox(height: 10),
                _FontDropdown(settings: settings),

                _Gap(),

                // ---- Focus mode ----
                _Label('Editor'),
                const SizedBox(height: 10),
                _FocusRow(settings: settings),

                _Gap(),

              // ---- Mascot ----
              _Label('Mascot'),
              const SizedBox(height: 10),
              _MascotPicker(settings: settings),

              _Gap(),

              // ---- Target WPM ----
                _Label('Target WPM'),
                const SizedBox(height: 10),
                _WpmSlider(settings: settings),

                const Spacer(),

                const Text(
                  'Speed measured over 60 s.  1 word = 5 chars.',
                  style: TextStyle(
                      color: Color(0x33E2E2E2), fontSize: 10, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout helpers
// ---------------------------------------------------------------------------

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Color(0x88E2E2E2),
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _Gap extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: Color(0x22FFFFFF), height: 1),
      );
}

// ---------------------------------------------------------------------------
// Background — three radio buttons (White / Black / Sepia)
// ---------------------------------------------------------------------------
//
// Each button shows a colour swatch + label.
// The selected one gets a blue border; others are dimmed.
//
// To add a preset, add an entry to kEditorThemes in settings_controller.dart.
// This widget requires no changes.

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
                color: preset.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF7EC8E3)
                      : const Color(0x33FFFFFF),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  // Aa preview in the preset's own text colour.
                  Text('Aa',
                      style: TextStyle(
                        color: preset.text,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 4),
                  Text(preset.label,
                      style: TextStyle(
                        color: preset.text.withOpacity(0.6),
                        fontSize: 9,
                        letterSpacing: 0.8,
                      )),
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
// Font — system font dropdown
// ---------------------------------------------------------------------------
//
// Flutter exposes the fonts loaded by the engine via
// PlatformDispatcher.instance.fonts (available since Flutter 3.10).
// We read those names, sort them, and present them in a DropdownButton.
// Fallback: a small curated list if the API returns nothing.

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
    // Ensure the current selection is always in the list.
    if (!_fonts.contains(widget.settings.fontFamily)) {
      _fonts = [widget.settings.fontFamily, ..._fonts];
    }
  }

  // Scans standard Linux font directories and extracts family names from
  // filenames. This is a fast, dependency-free approach that works on any
  // Flutter version and reflects fonts the user has actually installed.
  //
  // It reads font file names and strips extensions/variants to produce a
  // clean list. It is not perfect (font files don't always match the
  // internal family name), but it gives a useful, real list to pick from.
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
          if (!name.endsWith('.ttf') &&
              !name.endsWith('.otf') &&
              !name.endsWith('.woff') &&
              !name.endsWith('.woff2')) continue;
          // Strip extension and common weight/style suffixes to get a
          // rough family name. E.g. "RobotoCondensed-Bold.ttf" → "Roboto Condensed"
          var family = entity.uri.pathSegments.last;
          family = family.replaceAll(RegExp(r'\.(ttf|otf|woff2?)$',
              caseSensitive: false), '');
          family = family.replaceAll(
              RegExp(r'[-_](Bold|Italic|Light|Regular|Medium|Thin|'
                  r'Black|ExtraLight|SemiBold|ExtraBold|Heavy|'
                  r'Condensed|Expanded|BoldItalic|LightItalic|'
                  r'MediumItalic|SemiBoldItalic|Oblique)$',
                  caseSensitive: false),
              '');
          family = family.replaceAll('-', ' ').replaceAll('_', ' ').trim();
          if (family.isNotEmpty) families.add(family);
        }
      } catch (_) {
        // Skip unreadable directories silently.
      }
    }

    if (families.isEmpty) {
      // Fallback: generic CSS family names that Flutter resolves on all platforms.
      return ['sans-serif', 'serif', 'monospace'];
    }

    return families.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _fonts.contains(widget.settings.fontFamily)
          ? widget.settings.fontFamily
          : _fonts.first,
      isExpanded: true,         // fills the drawer width — no overflow
      dropdownColor: const Color(0xFF1E1E3A),
      style: const TextStyle(color: Color(0xCCE2E2E2), fontSize: 13),
      iconEnabledColor: const Color(0x66E2E2E2),
      underline: Container(height: 1, color: const Color(0x33FFFFFF)),
      onChanged: (v) {
        if (v != null) widget.settings.setFontFamily(v);
      },
      // Show the selected font rendered in itself.
      selectedItemBuilder: (context) => _fonts
          .map((f) => Align(
                alignment: Alignment.centerLeft,
                child: Text(f,
                    style: TextStyle(
                      fontFamily: f,
                      color: const Color(0xCCE2E2E2),
                      fontSize: 13,
                    )),
              ))
          .toList(),
      items: _fonts
          .map((f) => DropdownMenuItem(
                value: f,
                child: Text(f,
                    style: TextStyle(
                      fontFamily: f,
                      color: const Color(0xCCE2E2E2),
                      fontSize: 13,
                    )),
              ))
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
    return Row(
      children: [
        const Icon(Icons.center_focus_strong_outlined,
            color: Color(0xAAE2E2E2), size: 16),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Focus mode',
                  style: TextStyle(
                      color: Color(0xCCE2E2E2),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('Ctrl+Shift+F',
                  style: TextStyle(color: Color(0x44E2E2E2), fontSize: 10)),
            ],
          ),
        ),
        Switch(
          value:              settings.focusMode,
          onChanged:          settings.setFocusMode,
          activeColor:        const Color(0xFF7EC8E3),
          inactiveTrackColor: const Color(0x33E2E2E2),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Target WPM slider
// ---------------------------------------------------------------------------

class _WpmSlider extends StatelessWidget {
  final SettingsController settings;
  const _WpmSlider({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Target',
                style: TextStyle(
                    color: Color(0xCCE2E2E2),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${settings.targetWpm}',
                style: const TextStyle(
                  color: Color(0xFF7EC8E3),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                )),
            const Text(' wpm',
                style: TextStyle(color: Color(0x66E2E2E2), fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor:   const Color(0xFF4A90D9),
            inactiveTrackColor: const Color(0x33E2E2E2),
            thumbColor:         const Color(0xFF7EC8E3),
            overlayColor:       const Color(0x224A90D9),
            trackHeight:        3,
          ),
          child: Slider(
            value:     settings.targetWpm.toDouble(),
            min:       kMinTargetWpm.toDouble(),
            max:       kMaxTargetWpm.toDouble(),
            divisions: kMaxTargetWpm - kMinTargetWpm,
            onChanged: (v) => settings.setTargetWpm(v.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$kMinTargetWpm',
                  style: const TextStyle(
                      color: Color(0x33E2E2E2), fontSize: 10)),
              Text('$kMaxTargetWpm',
                  style: const TextStyle(
                      color: Color(0x33E2E2E2), fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mascot picker
// ---------------------------------------------------------------------------
//
// Lets the user browse for a PNG sprite sheet on their filesystem.
// The file path is stored in SettingsController.customMascotPath.
// Frame count can be adjusted with a simple stepper so any sheet works.

class _MascotPicker extends StatelessWidget {
  final SettingsController settings;
  const _MascotPicker({required this.settings});

  Future<void> _browse() async {
    const typeGroup = fs.XTypeGroup(
      label: 'PNG sprite sheet',
      extensions: ['png'],
    );
    final file = await fs.openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    settings.setCustomMascot(
      path:       file.path,
      frameCount: settings.customFrameCount,
      frameWidth: settings.customFrameWidth,
      frameHeight: settings.customFrameHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCustom = settings.customMascotPath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current status
        Text(
          hasCustom
              ? settings.customMascotPath!.split('/').last
              : 'Using built-in mascot',
          style: TextStyle(
            color:      hasCustom
                ? const Color(0xFF7EC8E3)
                : const Color(0x66E2E2E2),
            fontSize:   11,
            fontFamily: 'sans-serif',
            fontStyle:  hasCustom ? FontStyle.normal : FontStyle.italic,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),

        // Browse / Reset buttons
        Row(
          children: [
            _OutlineBtn(
              label:     'Browse…',
              color:     const Color(0xFF7EC8E3),
              onPressed: _browse,
            ),
            if (hasCustom) ...[
              const SizedBox(width: 8),
              _OutlineBtn(
                label:     'Reset',
                color:     const Color(0x66E2E2E2),
                onPressed: settings.clearCustomMascot,
              ),
            ],
          ],
        ),

        if (hasCustom) ...[
          const SizedBox(height: 14),
          // Frame count stepper — lets the user match their sheet layout.
          Row(
            children: [
              const Text('Frames',
                  style: TextStyle(
                      color: Color(0xAAE2E2E2),
                      fontSize: 12,
                      fontFamily: 'sans-serif')),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove, size: 14),
                color: const Color(0x88E2E2E2),
                splashRadius: 14,
                onPressed: settings.customFrameCount > 1
                    ? () => settings.setCustomMascot(
                          path:       settings.customMascotPath!,
                          frameCount: settings.customFrameCount - 1,
                          frameWidth:  settings.customFrameWidth,
                          frameHeight: settings.customFrameHeight,
                        )
                    : null,
              ),
              Text(
                '${settings.customFrameCount}',
                style: const TextStyle(
                  color:      Color(0xFF7EC8E3),
                  fontSize:   16,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 14),
                color: const Color(0x88E2E2E2),
                splashRadius: 14,
                onPressed: () => settings.setCustomMascot(
                  path:       settings.customMascotPath!,
                  frameCount: settings.customFrameCount + 1,
                  frameWidth:  settings.customFrameWidth,
                  frameHeight: settings.customFrameHeight,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String       label;
  final Color        color;
  final VoidCallback onPressed;
  const _OutlineBtn({required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side:            BorderSide(color: color.withOpacity(0.5)),
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
