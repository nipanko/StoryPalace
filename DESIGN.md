# Design

StoryPalace borrows the look of an orienteering map and its course overprint. Each room is the terrain. The story path is a purple course on top of it: a start triangle, numbered control circles, legs that stop at each circle's edge, and a double-circle finish. Everything else stays out of the way.

## Colour (map inks)

| Token | Hex | Job |
|---|---|---|
| ink | `#1E1E1E` | text, 2 px frames and rules, selected room header |
| muted | `#5B5B5B` | secondary text (6.6:1 on white) |
| paper | `#FFFFFF` | the ground ("runnable forest"), panels |
| course purple | `#B4248C` | the path, control numbers, primary buttons, focus rings, caret. Used for nothing decorative |
| purple dark | `#951C74` | primary hover and pressed |
| purple tint | `#FBE6F3` | the selected control row |
| open-land yellow | `#F7C04A` | selected control fill on the map, pressed flat buttons |
| yellow tint | `#FDF1D2` | hover |
| thicket green | `#7DB55E`, text `#3F7A2A` | "punched" (remembered) |
| contour brown | `#B96A2C` | contour hairlines on the home screen, at 16–26% alpha |
| missed red | `#C8362D` | "missed", destructive actions |

State never relies on colour alone. A punched control gets a check badge, a missed one is struck through with an X, and punch-card boxes show ✓ or ✗.

## Type

- **Barlow Condensed Bold** for display text, palace names, and control numerals (30–40 px). Numerals are purple, with a white halo on the map.
- **Barlow Condensed SemiBold** for buttons (18 px) and tracked caps labels (14 px, +1 px spacing).
- **Barlow** Regular and SemiBold for body text (15–17 px) and row titles (18 px).
- Emoji fall back to the system colour emoji font inside any text.

## Shape and space

- 4 px corners everywhere. Buttons and inputs have a 2 px ink frame; map frames and dialogs use the same frame. Popups get one soft shadow (18 px blur, 6 px down).
- Room tabs are map-sheet tabs: the active tab joins the map frame, and inactive tabs sit on `#F3F2EE`.
- Spacing steps: 4, 8, 10, 12, 16, 20, 24, 28.

## Components

- **Buttons:** primary (purple fill), outlined (paper with an ink frame), flat (no frame, yellow-tint hover), segmented (ink fill when on).
- **Control description row:** purple numeral, picture, title, and a one-line story. When selected it expands in place into the editor: picture button, what to remember, picture ideas, story, Earlier, Later, Remove.
- **Toasts:** an ink panel with white text. The remove toast has an Undo button in yellow.

## Motion

Motion only shows a change of state, and stays between 150 and 600 ms.

- Screens fade in over 160 ms.
- While the course runs, the map eases in toward the current control (zoom 1.35, 450 ms cubic ease-out), and the new leg draws itself from the last control (600 ms). This is the one signature move.
- In 3D, the camera glides along the route through doorways, then turns to face the control.

## 3D

Rooms are unlit and flat-coloured with the same wall, side, and floor colours as the 2D art, so the two views read as one place. Floors carry drawn patterns (planks, tiles, checker, slabs). Each control stands on a post with an orange-and-white kite flag, has a billboarded picture inside a purple ring, and shows its number to the upper right. The course runs as a purple ribbon on the floor.
