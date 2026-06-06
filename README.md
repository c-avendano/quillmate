# QuillMate

A distraction-free Markdown writing environment with an animated mascot companion.

---

## Project Structure

```
lib/
├── main.dart                     # App entry point
├── models/
│   ├── mascot_state.dart         # MascotMood enum + immutable state snapshot
│   └── typing_monitor.dart       # ChangeNotifier: tracks typing, drives mood transitions
├── utils/
│   └── markdown_highlighter.dart # Lightweight regex-based syntax coloring
└── widgets/
    ├── writing_screen.dart       # Root screen: wires editor ↔ mascot ↔ monitor
    ├── writing_area.dart         # Full-screen TextField with rich-text highlighting
    ├── mascot_widget.dart        # Draggable, animated mascot + bubble
    └── mascot_painter.dart       # CustomPainter drawing the mascot shape
```

### Mascot States

| Mood         | Trigger                                | Animation speed |
|-------------|----------------------------------------|-----------------|
| Idle        | Default / no recent typing             | Slow (2.8 s)    |
| Typing      | User pressed a key                     | Fast (0.7 s)    |
| Encouraging | 10 s of silence after typing           | Medium (1.6 s)  |

### Swapping in Sprite Sheets

Replace `MascotPainter` in `mascot_painter.dart` with an `Image.asset()` or a
sprite-sheet frame index driven by `animationValue` and `mood`. The parent
`MascotWidget` passes both values already — no other changes needed.

---

## Running on Fedora Silverblue

Fedora Silverblue uses an immutable base image; install Flutter inside a
**toolbox** (or distrobox) container to keep the host clean.

### 1 — Create a toolbox container (Fedora 40+)

```bash
toolbox create --image registry.fedoraproject.org/fedora-toolbox:40 flutter-box
toolbox enter flutter-box
```

### 2 — Install dependencies inside the toolbox

```bash
sudo dnf install -y \
  git curl unzip xz zip \
  clang cmake ninja-build pkg-config \
  gtk3-devel \
  libstdc++-devel \
  mesa-libGL-devel
```

### 3 — Install Flutter (stable channel)

```bash
git clone https://github.com/flutter/flutter.git ~/flutter --depth 1 -b stable
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
flutter doctor
```

`flutter doctor` will list any remaining missing components. For Linux desktop
you typically only need the GTK libraries above.

### 4 — Enable Linux desktop support

```bash
flutter config --enable-linux-desktop
```

### 5 — Run QuillMate

```bash
# Inside the toolbox, cd to wherever you placed this project:
cd /path/to/quillmate
flutter pub get
flutter run -d linux
```

The app window should open immediately. Start typing to see the mascot
switch from **Idle → Typing**. Stop for 10 seconds and watch it switch to
**Encouraging** with a message bubble.

### 6 — Build a release binary

```bash
flutter build linux --release
# Binary lands at: build/linux/x64/release/bundle/quillmate
```

You can copy the entire `bundle/` folder anywhere and run the binary directly.

### Troubleshooting

| Problem | Fix |
|---------|-----|
| `flutter: command not found` | Re-run `source ~/.bashrc` or open a new toolbox shell |
| `No connected devices` | Run `flutter config --enable-linux-desktop` then retry |
| Wayland compositing glitches | Set `GDK_BACKEND=x11 flutter run -d linux` |
| Missing libGL / GL errors | `sudo dnf install mesa-libGL mesa-libGL-devel` |

---

## Extending the Project

- **More moods**: add a value to `MascotMood`, handle it in `MascotPainter._bodyColor` / `_drawMouth`, and set a duration in `MascotWidget._durations`.
- **More encouragements**: add strings to the `_encouragements` list in `typing_monitor.dart`.
- **Markdown preview**: add a split-pane view using the `markdown` pub package in a second column alongside `WritingArea`.
- **Word count**: parse `_controller.text.split(RegExp(r'\s+'))` in `WritingArea` and expose it via a callback similar to `onKeyPress`.
