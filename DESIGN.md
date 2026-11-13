# Design system

StoryPalace looks and behaves like professional desktop software: neutral surfaces, one accent colour, one typeface, a strict spacing grid, and the same components on every screen. The rooms and the memories are the only colourful things on screen. All tokens live in `scripts/ui.gd`; screens use them and nothing ad hoc.

## Colour

| Token | Hex | Used for |
|---|---|---|
| `TEXT` | `#1A1D23` | primary text |
| `MUTED` | `#5F6672` | secondary text (5.9:1 on white) |
| `SUBTLE` | `#868D99` | captions, placeholders, disabled |
| `BG` | `#F4F5F7` | app background |
| `SURFACE` | `#FFFFFF` | toolbars, panels, cards, inputs |
| `SUNKEN` | `#ECEEF1` | canvas wells, segmented-control tracks |
| `HOVER` | `#F0F2F5` | hover on rows and ghost buttons |
| `BORDER` / `BORDER_STRONG` | `#DFE2E7` / `#C7CCD4` | panel hairlines / control outlines |
| `ACCENT` | `#4F46E5` | the path, number tags, primary action, focus ring, selection (6.3:1 with white) |
| `ACCENT_HOVER` / `ACCENT_TINT` | `#4338CA` / `#EEF0FE` | pressed and hover / selected rows |
| `SUCCESS` (+ tint) | `#1F7A4D` / `#E6F4EC` | remembered |
| `DANGER` (+ tint) | `#C8322B` / `#FCEBEA` | missed, destructive actions |

State never relies on colour alone: a remembered memory gets a check badge and the words "Got it", a missed one is crossed out and labelled "Missed".

## Dark mode

Every colour token has a dark value (`UI.DARK` in `scripts/ui.gd`): background `#111318`, surfaces `#1A1D24`, text `#E8EAED`, accent `#6366F1`. The app follows the system setting until the user picks one with the sun/moon button in the toolbar; the choice is saved. Map markers stay white in both themes so pictures read the same.

## Type

One family, Inter, at four weights (400, 500, 600, 700). Emoji fall back to the system colour emoji font.

| Style | Size / weight | Used for |
|---|---|---|
| Display | 24 / 600 | page titles, the memory title on the run card |
| H1 | 20 / 600 | reserved |
| H2 | 16 / 600 | toolbar titles, dialog titles |
| H3 | 14 / 600 | row and card titles |
| Body | 14 / 400 | text |
| Muted | 13 / 400 | secondary text; 12 in the status bar and field labels |
| Caps | 11 / 600, upper case | group headers in lists |

## Space and shape

- Spacing uses a 4-pt grid: `S1` 4, `S2` 8, `S3` 12, `S4` 16, `S6` 24, `S8` 32.
- Borders are 1 px. Radius is 6 on controls, 8 on panels and cards, 10 on popups.
- Shadows mean "this floats": only popups, menus, dialogs and toasts have one.
- Fixed heights: toolbar 52, panel header 40, status bar 28, buttons about 32.

## Components

- **Toolbar** (`UI.bar`): white, hairline below. Navigation on the left, view switch and actions on the right, primary action last.
- **Panel** (`UI.panel`): bordered surface with a 40 px header (title, then icon actions) and a body.
- **Buttons:** primary (accent fill), default (white, outlined), flat (ghost), danger (red text), icon (32 px square ghost), segmented (chip on a sunken track).
- **Badge** (`UI.badge`): neutral, accent, success or danger pill for counts and status.
- **Number tag** (`UI.number_tag`): the accent circle every memory carries in lists, on the map and in 3D.
- **Inputs:** white, 1 px strong border, 2 px accent border on focus.
- **Toast** (`UI.toast`): dark, bottom centre, optional action (Undo).
- **Status bar:** contextual hint on the left; room and memory counts and the save state on the right.
- **Map markers** (`scripts/course.gd`): white disc, accent ring, picture inside, number tag; a solid triangle marks the start and a second ring the finish; legs are 2 px accent lines that stop at each marker's edge.

## Layout

- **Home:** toolbar (logo, search, Import, New palace), then a grid of 288 px palace cards.
- **Editor:** toolbar, then Rooms panel (232 px), room canvas (flexible), Memories panel (27% of the width, 320–400 px), then the status bar.
- **Run and test:** toolbar with a 3 px progress bar under it, room canvas, and a card panel (30% of the width, 340–440 px).
- **Responsive:** under 1200 px the Rooms panel folds to thumbnails (92 px); under 1100 px Run, Test and the Palaces breadcrumb drop their labels. Minimum window is 1024 × 680.

## Motion

Motion is short and never bounces: 120 ms for state changes, 180 ms for surfaces appearing, cubic ease-out.

- Screens, cards and step content fade in.
- A new marker settles from 60% to full size.
- While the course runs, the map eases toward the current marker (400 ms) and the next leg draws itself (600 ms).
- In 3D, the camera glides along the route and turns to face each memory.

## 3D

Rooms are unlit and flat-coloured with the same palette as the 2D art; floors have drawn patterns. Each memory stands on a post with an accent-and-white flag and shows its picture inside an accent ring. The path is an accent ribbon on the floor.
