# Sticky

A native macOS sticky note app that celebrates every time you tick something off. Built with Swift and SwiftUI.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

---

## Download

Grab the latest release from the [Releases](https://github.com/Harit556/Sticky/releases) page. Unzip and drag to Applications.

> First launch: right-click → Open to get past Gatekeeper (app is unsigned).

---

## What it does

Floating sticky notes that live on your desktop. Each one has its own to-do list. Tick something off and get a confetti explosion. That's basically it.

---

## Features

### The basics
- Multiple floating sticky windows — each with their own tasks and colour
- Windows stay where you put them between launches
- Right-click anywhere on a sticky to open its settings
- `⌘N` to create a new sticky, `⇧⌘O` to open all of them side by side
- `⌥⇧S` to hide or show all stickies from anywhere on your Mac

### Tasks
- Press Enter to add a new task and immediately start the next one
- Click the checkbox to complete (with strikethrough)
- Backspace on an empty task to delete it
- Drag to reorder
- Option to auto-sort completed tasks to the bottom

### Minimise
- Click the chevron next to the title to collapse a sticky to a slim 36px bar
- Click it again to expand

### Confetti
5 styles to choose from:
- **Classic** — streaming rectangles (the original)
- **Burst** — everything explodes outward from one point
- **Stars** — 5-pointed star shapes
- **Emoji** — 🎉✨🌟💫 pop up, float, and fade
- **Minimal** — 3–5 large slow-falling pieces, barely there

All styles respond to Size, Amount, Gravity, and Colour settings.

### Sound effects
- Confetti, Yay, Yippie, Cat Laugh, Apple Pay, Rizz, Click Nice
- Import your own MP3
- Or turn sound off entirely

### Per-sticky settings
Every sticky can have its own:
- Colour theme (6 presets + custom colour picker)
- Sound effect
- Confetti style, size, amount, gravity, volume, and colour
- Always on top toggle

### Zapier integration
Connect task completions to 5,000+ apps. Set a webhook URL in Settings → Zapier Integration and tasks will flow to Notion, Slack, Google Sheets, Todoist — wherever you want.

---

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| `⌘N` | New sticky |
| `⇧⌘O` | Open all stickies side by side |
| `⌥⇧S` | Show / hide all stickies |
| `Enter` | New task |
| `Backspace` | Delete empty task |
| `⌘Q` | Quit |

---

## Building from source

Requires Xcode 15+ and macOS 14+. No third-party dependencies.

```bash
git clone https://github.com/Harit556/Sticky.git
cd Sticky
open Sticky.xcodeproj
```

Press `⌘R` to build and run.

---

## Tech

Swift + SwiftUI, SpriteKit for confetti, AVFoundation for audio, JSON persistence with atomic writes.
