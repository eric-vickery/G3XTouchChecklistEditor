# G3X Touch Checklist Editor

A SwiftUI app for macOS and iOS/iPadOS that creates and edits checklist files (`.ace`) for the Garmin G3X Touch avionics system.

## Features

- Open, edit, save, and duplicate G3X checklist files (`.ace`)
- Organize checklists into groups, and checklists into entries
- Entry types: Text, Note, Subtitle, Warning, Caution, and Challenge
- Text justification options: left, indent levels 1–4, and centered
- Blank-line entries and checklist file properties editing
- Cut, copy, paste, and undo support for entries
- Handles the G3X file format, including CRC calculation (via [CrcSwift](https://github.com/ivanesik/CrcSwift))

## Requirements

- Xcode 
- macOS 13.0+ or iOS 16.0+

## Building

1. Open `G3X Checklist Editor.xcodeproj` in Xcode.
2. Let Swift Package Manager resolve the `CrcSwift` dependency.
3. Select the `G3XChecklistEditor` scheme and a macOS or iOS destination.
4. Build and run.

## Project layout

| Path | Contents |
| --- | --- |
| `G3XChecklistEditor/Models/` | `ChecklistFile`, `Group`, `Checklist`, and `Entry` models, plus file parsing and serialization |
| `G3XChecklistEditor/*View.swift` | SwiftUI views for groups, checklists, entries, and their edit sheets |
| `G3XChecklistEditor/Store.swift` | StoreKit product fetching and purchasing |
| `G3XChecklistEditor/Todos.txt` | Outstanding work items |
| `G3XChecklistEditorTests/`, `G3XChecklistEditorUITests/` | Unit and UI test targets |

## Known issues / roadmap

See [`Todos.txt`](G3XChecklistEditor/Todos.txt). Highlights:

- Undo of cut/delete does not restore items to their original position
- iOS cannot load files directly from an SD card
- `.ace` extension is not always added on save/duplicate

## Disclaimer

This is an independent project and is not affiliated with or endorsed by Garmin. Always verify checklists on your avionics before flight.
