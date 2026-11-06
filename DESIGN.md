# Design

StoryPalace looks like a cosy sticker desktop. Every panel is a pastel window with an outlined title bar, and every memory is a sticker pressed onto a room along a pink path. It draws on four references: the calm three-column layout of a science studio app, retro OS window frames, a Y2K grid desktop, and a confident game title screen.

## Colour

| Token | Hex | Job |
|---|---|---|
| ink | `#35294A` | text and every 2 px outline (11:1 on cream) |
| muted | `#6B5F7D` | secondary text |
| ground | `#FFF5E6` | the desk, with a faint 32 px grid |
| paper | `#FFFDF8` | window bodies, inputs |
| pink | `#D02E6E` | the path, number tags, primary action, focus ring, caret (4.9:1 with white) |
| pink dark | `#B0225B` | primary hover and pressed |
| butter | `#FFD166` | secondary action (Punch test), selected sticker halo, Memories title bar |
| lavender | `#CFC9F2`, tint `#EEEBFB` | room window title bar, selection, hover |
| teal | `#9ED8CF` | Rooms title bar, current room header, "tested" chip |
| peach | `#FFC2A8` | the open memory card, run and test card window |
| sky | `#5C8DF6` | reserved for 3D accents |
| green | `#23805F` | remembered |
| red | `#C93A2C` | missed, destructive |

State never relies on colour alone. A remembered sticker gets a check badge, a missed one is crossed out, and the punch card shows ✓ or ✗.

## Type

- **Young Serif** for display text: the app name (46 px), palace names (34 px), and section and card headings (26 px).
- **Nunito** for everything else: body 16–17 px at weight 500, row titles 17 px at 800, buttons 16 px at 800, and window title bars and number tags at 900.
- Emoji fall back to the system colour emoji font inside any text.

## Shape

- Windows have a 14 px radius, a 2 px ink outline, and a soft shadow (14 px blur, 5 px down, ink at 13%). The title bar is 40 px tall in a role colour, with a 2 px rule below it. Title-bar buttons are real actions: 28 px outlined squares with a butter hover.
- Buttons have a 12 px radius and a 2 px ink outline: pink for primary, butter for secondary, paper for neutral.
- Stickers are a paper disc with a pink ring and an ink outline, plus a pink pill number tag. Selected stickers get a butter halo; new ones land with a bounce.
- Spacing steps: 4, 6, 8, 10, 12, 14, 18, 20, 24, 28.

## Layout

- **Editor:** a Rooms window (thumbnails), the room window (map or 3D, with the 2D/3D switch floating top-right and a hint pill bottom-left), and a Memories window whose selected card expands into its editor.
- **Under 1280 px:** the Rooms window folds to a thumbnail strip.
- **Under 1120 px:** Run and Test become icon-only buttons.
- **Side windows** scale with the screen: Memories between 330 and 430 px, the run card between 340 and 460 px.

## Motion

Motion signals state and lasts 80–380 ms.

- Screens and windows pop open: scale 0.94 to 1, back-ease overshoot, staggered 40 ms.
- Buttons lift to 1.03–1.08 on hover and squash to 0.95 on press. Only scale changes, so the layout never jumps.
- A new memory sticker lands with a 380 ms bounce.
- While the course runs, the map eases toward the current sticker and the new pink leg draws itself (600 ms). This is the signature move.
- Each run and test step settles in like a fresh sticker.

## 3D

Rooms are unlit and flat-coloured with the same palette as the 2D art, and floors have drawn patterns. Each memory stands on a post with a pink-and-white flag and shows a billboarded picture inside a pink ring. The path is a pink ribbon on the floor.
