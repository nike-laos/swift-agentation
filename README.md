# DebugAnnotationKit

A drop-in visual annotation tool for iOS/iPadOS SwiftUI apps. Capture screenshots, place numbered pins on UI elements, add notes, and copy structured markdown reports to the clipboard. Built for faster bug reporting during development and TestFlight.

Inspired by [agentation.dev](https://agentation.dev).

All code is wrapped in `#if DEBUG && os(iOS)` — zero impact on release builds.

## What It Does

1. A tiny ant icon (0.3 opacity) floats in the bottom-left corner of your app
2. Tap it to freeze the current screen as a screenshot
3. Tap anywhere on the screenshot to place numbered red pins
4. Tap a pin to add a note describing the issue
5. Tap "Copy Report" to get structured markdown on the clipboard
6. Paste into GitHub issues, Slack, Notes, etc.

The report includes device info, pin coordinates, UIKit view class names, accessibility labels, frames, and your notes.

### Example Output

```
## Debug Report
**Device:** iPhone 16 Pro, iOS 18.2
**App State:** screen=Home, loggedIn=true
**Date:** 2026-02-12 14:30

### Annotations
1. (120, 340) — UILabel "Welcome"
   Frame: (100, 320, 200, 44)
   Traits: staticText
   Note: "Title font looks too large on small screens"

2. (200, 600) — _UIHostingView
   Frame: (16, 580, 358, 120)
   Traits: none
   Note: "Card clipping on left edge"
```

## Setup (2 minutes)

### Step 1: Add the files

Drag the 4 Swift files into your Xcode project:

- `DebugAnnotationState.swift`
- `DebugElementInspector.swift`
- `DebugMarkdownGenerator.swift`
- `DebugAnnotationOverlay.swift`

Make sure "Copy items if needed" is checked and they're added to your app target.

### Step 2: Add the modifier

In your root view (typically your `App` struct or main `ContentView`), add one modifier:

```swift
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
            #if DEBUG && os(iOS)
                .debugAnnotation()
            #endif
        }
    }
}
```

That's it. Build and run in Debug — the ant icon appears.

### Optional: Include App State

Pass a closure that returns key-value pairs describing your app's current state. These get included in the markdown report:

```swift
ContentView()
#if DEBUG && os(iOS)
    .debugAnnotation {
        [
            "screen": navigationState.currentScreen,
            "userId": authState.userId ?? "none",
            "darkMode": "\(colorScheme == .dark)"
        ]
    }
#endif
```

## How It Works

- **Screenshot capture:** Uses `UIGraphicsImageRenderer` to render the key window into an image before the overlay appears, so the UI is frozen in place while you annotate.
- **UIKit hit-testing:** Uses `UIApplication.shared.connectedScenes` to get the key window, then `hitTest(point:with:)` to identify which UIKit view (backing a SwiftUI view) lives at each pin location. Extracts the class name, accessibility label, frame, and traits.
- **Clipboard markdown:** Generates a structured report with device info, coordinates, element details, and your notes.
- **Compile-time removal:** Every file is wrapped in `#if DEBUG && os(iOS)`, so none of this code exists in your release binary.

## Requirements

- iOS 17.0+ (uses `@Observable`)
- SwiftUI
- Xcode 15+

## License

MIT. Use it however you want.
