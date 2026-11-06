# StoryPalace

Remember anything by building memory palaces. Pick a place you know well, put a vivid picture at each spot along a path, write the little story that ties it there, then walk the path and test yourself.

Built with 💖 by **Storybook Interactive Private Limited**.

## What it does

- **Palaces and rooms.** Ready-made illustrated rooms (living room, kitchen, bedroom, hallway, classroom, library, castle hall, garden, beach), or a photo of a real place you know.
- **Memories on a path.** Click anywhere on a room to stick a memory there. Each one is a numbered sticker on a pink path, from the start triangle to the finish ring. Drag to move, reorder with Earlier and Later.
- **Pictures and stories.** Search about 1,800 emoji, or use your own image. Typing what to remember suggests pictures for you.
- **2D map or 3D walk.** Switch any time. In 3D, drag to look around and use W A S D or the arrow keys to walk through the rooms.
- **Run the course.** A guided walk, control by control, with the path drawing itself as you go.
- **Punch test.** Recall each control before revealing it, then mark it as got it or missed it. You get a score, the list of missed controls, and a one-click retest of only those. Results are saved with the palace.
- **Yours, offline.** No account, no internet. Export a palace to a `.palace` file to back it up or share it, and import files from others.

Keyboard: `R` runs the course, `T` starts the test, `Delete` removes the selected control, `Ctrl+Z` undoes. While running: `←` `→` or `Space` move along, `Space` shows the answer, `1` means missed, `2` means got it, and `Esc` leaves.

## Install

| | |
|---|---|
| **Windows 10/11** | Run `StoryPalace-Setup.exe` and follow the setup wizard. It adds StoryPalace to the Start menu (and optionally the desktop) and can be removed from *Settings → Apps*. No admin rights needed. |
| **macOS 10.13+** (Apple Silicon and Intel) | Unzip `StoryPalace.zip` and drag **StoryPalace.app** into Applications. The first time, right-click the app and choose **Open**, then **Open** again. The app is not notarised by Apple yet. |

Your palaces are saved automatically to:

- Windows: `%APPDATA%\StoryPalace`
- macOS: `~/Library/Application Support/StoryPalace`

## Build from source

The app is made with [Godot](https://godotengine.org) 4.7.2 (standard version, not .NET).

1. Install Godot 4.7.2 and its export templates (*Editor → Manage Export Templates*).
2. Open this folder in Godot, or export from the command line:

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/StoryPalace.exe
```

```bash
godot --headless --path . --export-release "macOS" build/macos/StoryPalace.zip
```

To build the Windows installer, install [Inno Setup 6](https://jrsoftware.org/isinfo.php) and run `ISCC installer/storypalace.iss` after exporting the exe; it writes `build/installer/StoryPalace-Setup-<version>.exe`.

A Mac build made on Windows or Linux gets an ad-hoc signature only. To notarise it for the Mac App Store or for opening without the right-click step, export on a Mac with an Apple Developer ID.

### Self-check

This command drives every screen, clicks and drags real input on the map, round-trips an export and import, saves screenshots, and exits with code 0 only if every check passes:

```bash
godot --path . --resolution 1440x900 -- --windowed --scale=1 --shots=/path/to/screenshots
```

To run only the checks, with no window and no screenshots:

```bash
godot --headless --path . -- --shots=none
```

## Project layout

```
scripts/
  main.gd           app root: window scale, screens
  store.gd          saving, loading, pictures, export/import (autoload "Store")
  home.gd           palace library and the how-it-works legend
  palace_screen.gd  editor: room tabs, map or 3D view, control descriptions
  map_view.gd       a room as a 2D map with its course (click, drag)
  palace_world.gd   the palace in 3D
  tour.gd           run the course and the punch test
  course.gd         course notation drawing (start, controls, legs, finish)
  scene_art.gd      the ready-made rooms, drawn in code
  pickers.gd        picture picker and room picker
  emoji.gd, ui.gd, thumb.gd, sample.gd, shots.gd
data/               emoji list (Unicode), interface icons
fonts/              Young Serif and Nunito
licenses/           third-party licences
```

## Credits

- Engine: Godot Engine, MIT licence (`licenses/godot-MIT.txt`, `licenses/godot-COPYRIGHT.txt`)
- Typefaces: Young Serif and Nunito, SIL Open Font License (`licenses/youngserif-OFL.txt`, `licenses/nunito-OFL.txt`)
- Interface icons: Lucide, ISC licence (`licenses/lucide-ISC.txt`)
- Emoji names: Unicode emoji data. Emoji pictures are drawn by your system's emoji font.

© 2026 Storybook Interactive Private Limited. Released under the MIT licence (see `LICENSE`).
