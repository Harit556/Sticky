# StickyTodos

A native macOS sticky note to-do list app built with Swift and SwiftUI. Every completed task triggers a confetti celebration with sound.

## Requirements

- **macOS 14.0** (Sonoma) or later
- **Xcode 15.0** or later
- No third-party dependencies

## Setup & Build

1. Open `StickyTodos.xcodeproj` in Xcode
2. Select the `StickyTodos` scheme and a Mac target
3. Press `Cmd+R` to build and run

Or build from the command line:

```bash
xcodebuild -project StickyTodos.xcodeproj -scheme StickyTodos -configuration Debug build
```

## Features

### Sticky Note UI
- Floating windows that stay above other apps (toggleable pin)
- Classic sticky note look: rounded corners, warm yellow background, subtle drop shadow
- No traditional title bar — minimal chrome with close/minimize dots
- "Peel" shadow effect in the bottom-right corner
- Window position and size remembered between launches

### To-Do List
- Click "Add task" or press Enter to create new tasks inline
- Press Enter to confirm a task and immediately start a new one below
- Click the checkbox to mark complete (with strikethrough and fade)
- Swipe left to delete, or press Backspace on an empty task
- Drag to reorder tasks
- Keyboard navigation: arrow keys to move between tasks, Space to toggle

### Confetti Celebration
- Checking off a task triggers a multicolored confetti burst (7 colors)
- Accompanied by a satisfying pop sound effect
- Each completion gets its own independent burst — rapid checking triggers multiple explosions
- Animation runs ~1.5 seconds without blocking interaction
- Built with SpriteKit particle emitters

### Color Themes
- Right-click any sticky to choose from 6 preset colors: Yellow, Pink, Green, Blue, Purple, Orange
- **Custom color picker**: choose any color via the native macOS color panel
- Dark mode support with muted color variants
- Theme choice persists per sticky

### Multiple Stickies
- `Cmd+N` to create a new sticky note
- Each sticky has its own tasks, color theme, and window position
- All data persists to `~/Library/Application Support/StickyTodos/stickies.json`

### Menu Bar
- Menu bar icon (note icon) lists all open stickies with task counts
- Quick access to create new stickies or open Zapier settings
- App lives in the menu bar — no Dock icon

### Zapier Integration
- Connect task events to 5,000+ apps via Zapier webhooks
- Sends events for: task completed, task created, task deleted
- Configure webhook URLs in Settings (menu bar > "Zapier Integration...")
- Test button to verify webhook connectivity

**Setup:**
1. Create a Zap on [zapier.com](https://zapier.com)
2. Choose "Webhooks by Zapier" > "Catch Hook" as trigger
3. Copy the webhook URL
4. Paste it into StickyTodos settings
5. Tasks now flow to Todoist, Notion, Slack, Google Sheets, etc.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Cmd+N` | New sticky note |
| `Enter` | Confirm task, start new one |
| `Arrow Up/Down` | Navigate between tasks |
| `Space` | Toggle task completion |
| `Backspace` | Delete empty task |
| `Cmd+Q` | Quit |

## Project Structure

```
StickyTodos/
├── App/           — App entry point, AppDelegate, window management
├── Models/        — TodoItem, StickyNote, StickyColorTheme
├── Views/         — All SwiftUI views
├── Confetti/      — SpriteKit particle system
├── Audio/         — Sound manager (generates pop sound at runtime)
├── Persistence/   — JSON file storage
└── Integration/   — Zapier webhook service
```

## Tech Stack

- Pure Swift + SwiftUI (no third-party dependencies)
- SpriteKit for confetti particle effects
- AVFoundation for sound (with programmatic WAV generation fallback)
- URLSession for Zapier webhook integration
- JSON file persistence with atomic writes and debounced saving
