# Snippets

A native iOS clipboard manager for saving, organizing, and retrieving text snippets, URLs, and images — with a built-in Share Extension so you can save content from any app.

---

## Features

- **Save any content type** — text, URLs, and images
- **Share Extension** — save clips directly from Safari, Notes, Photos, and more
- **Filter by type** — quickly toggle between Text, URL, and Image categories
- **Folders** — organize clips into named folders
- **Tags** — label clips with color-coded tags
- **Search** — full-text search across clip titles and content
- **Pin clips** — keep important clips at the top of the list
- **Copy to clipboard** — one-tap copy with visual confirmation
- **Relative timestamps** — natural language time display ("2 minutes ago")

---

## Tech Stack

| Technology | Usage |
|---|---|
| **Swift 5** | Primary language |
| **SwiftUI** | Declarative UI framework |
| **SwiftData** | Persistent data storage |
| **UniformTypeIdentifiers** | Content type detection in Share Extension |
| **UIKit** | Share Extension view controller host |
| **App Groups** | Shared data between app and extension |
| **iOS 17+** | Minimum deployment target |

---

## Project Structure

```
Snippets/
├── Snippets/                       # Main app target
│   ├── SnippetsApp.swift           # App entry point, SwiftData container setup
│   ├── ContentView.swift           # Main UI: filter chips, search, clip list
│   ├── ClipDetailView.swift        # Detail view: edit, copy, tag, folder assign
│   ├── ClipItem.swift              # Data models: ClipItem, ClipFolder, ClipTag, ClipType
│   ├── FolderManagerView.swift     # Create and delete folders
│   ├── TagManagerView.swift        # Create and delete tags
│   ├── Assets.xcassets/            # App icon, accent color
│   ├── Info.plist                  # App configuration
│   └── Snippets.entitlements       # App Group entitlement
│
├── ShareExtension/                 # Share Extension target
│   ├── ShareViewController.swift   # UIViewController: detects and loads shared content
│   ├── ShareView.swift             # SwiftUI form: title, folder, tag selection
│   ├── Info.plist                  # Extension configuration
│   └── ShareExtension.entitlements # Extension entitlements
│
└── Snippets.xcodeproj/             # Xcode project
```

---

## Data Models

### `ClipType` (enum)
| Case | Raw Value | Icon |
|---|---|---|
| `.text` | `"Text"` | `doc.text` |
| `.url` | `"URL"` | `link` |
| `.image` | `"Image"` | `photo` |

### `ClipItem` (@Model)
| Property | Type | Description |
|---|---|---|
| `id` | `UUID` | Unique identifier |
| `title` | `String` | Display title |
| `content` | `String` | Text content or URL string |
| `imageData` | `Data?` | Binary image data (image clips only) |
| `clipType` | `String` | Stores `ClipType.rawValue` |
| `createdAt` | `Date` | Creation timestamp |
| `isPinned` | `Bool` | Pinned status |
| `folder` | `ClipFolder?` | Optional folder assignment |
| `tags` | `[ClipTag]` | Associated tags |

### `ClipFolder` (@Model)
| Property | Type | Description |
|---|---|---|
| `name` | `String` | Folder name |
| `createdAt` | `Date` | Creation timestamp |
| `clips` | `[ClipItem]` | Clips in this folder (nullify on delete) |

### `ClipTag` (@Model)
| Property | Type | Description |
|---|---|---|
| `name` | `String` | Tag name |
| `colorHex` | `String` | Hex color string (default: `#007AFF`) |
| `clips` | `[ClipItem]` | Clips with this tag (nullify on delete) |

---

## Architecture

- **Pattern**: MVVM-adjacent using SwiftUI's `@Environment` and `@Query`
- **State**: `@State` for local UI state; SwiftData for persistent state
- **Navigation**: `NavigationStack` with sheet-based modals for details
- **Data sharing**: App Group container (`group.com.devohn.snippets`) shared between the main app and Share Extension
- **Relationships**: Folders and tags use `.nullify` delete rules — deleting a folder or tag does not delete its clips
- **Filtering**: Clips support simultaneous filtering by type, folder, tags, and search text

### Share Extension Flow
1. User taps **Share** in any app and selects **Snippets**
2. `ShareViewController` detects content type (image → URL → text, in priority order)
3. `ShareView` presents a form pre-filled with detected content and a suggested title
4. On save, the clip is written to the shared SwiftData store via the App Group container

---

## Getting Started

### Requirements
- Xcode 16 or later
- iOS 17.0+ device or simulator
- Apple Developer account (for code signing)

### Build & Run
1. Clone the repository
2. Open `Snippets.xcodeproj` in Xcode
3. Select your development team in **Signing & Capabilities** for both the `Snippets` and `ShareExtension` targets
4. Select a simulator or connected device
5. Press **⌘R** to build and run

### Testing the Share Extension
1. Run the main app once to register the extension
2. Open Safari (or any app), share a URL, and select **Snippets** from the share sheet
3. Fill in the title and optional folder/tags, then tap **Save**
4. Open the Snippets app to see the saved clip

---

## Configuration

| Setting | Value |
|---|---|
| App Group | `group.com.devohn.snippets` |
| Main App Bundle ID | `DeVohn-Jackson.Snippets` |
| Share Extension Bundle ID | `DeVohn-Jackson.Snippets.ShareExtension` |

The App Group identifier must match in both `Snippets.entitlements` and `ShareExtension.entitlements` for data sharing to work.
