# FAHMenuBar - macOS App

A modern macOS application using a **workspace + SPM package** architecture for clean separation between app shell and feature code.

## Project Architecture

```
FAHMenuBar/
├── FAHMenuBar.xcworkspace/              # Open this file in Xcode
├── FAHMenuBar.xcodeproj/                # App shell project
├── FAHMenuBar/                          # App target (minimal)
│   ├── Assets.xcassets/                # App-level assets (icons, colors)
│   ├── FAHMenuBarApp.swift              # App entry point
│   ├── FAHMenuBar.entitlements          # App sandbox settings
│   └── FAHMenuBar.xctestplan            # Test configuration
├── FAHMenuBarPackage/                   # 🚀 Primary development area
│   ├── Package.swift                   # Package configuration
│   ├── Sources/FAHMenuBarFeature/       # Your feature code
│   └── Tests/FAHMenuBarFeatureTests/    # Unit tests
└── FAHMenuBarUITests/                   # UI automation tests
```

## Key Architecture Points

### Workspace + SPM Structure
- **App Shell**: `FAHMenuBar/` contains minimal app lifecycle code
- **Feature Code**: `FAHMenuBarPackage/Sources/FAHMenuBarFeature/` is where most development happens
- **Separation**: Business logic lives in the SPM package, app target just imports and displays it

### Buildable Folders (Xcode 16)
- Files added to the filesystem automatically appear in Xcode
- No need to manually add files to project targets
- Reduces project file conflicts in teams

### App Sandbox
The app is sandboxed by default with basic file access permissions. Modify `FAHMenuBar.entitlements` to add capabilities as needed.

## Development Notes

### Code Organization
Most development happens in `FAHMenuBarPackage/Sources/FAHMenuBarFeature/` - organize your code as you prefer.

### Public API Requirements
Types exposed to the app target need `public` access:
```swift
public struct SettingsView: View {
    public init() {}
    
    public var body: some View {
        // Your view code
    }
}
```

### Adding Dependencies
Edit `FAHMenuBarPackage/Package.swift` to add SPM dependencies:
```swift
dependencies: [
    .package(url: "https://github.com/example/SomePackage", from: "1.0.0")
],
targets: [
    .target(
        name: "FAHMenuBarFeature",
        dependencies: ["SomePackage"]
    ),
]
```

### Test Structure
- **Unit Tests**: `FAHMenuBarPackage/Tests/FAHMenuBarFeatureTests/` (Swift Testing framework)
- **UI Tests**: `FAHMenuBarUITests/` (XCUITest framework)
- **Test Plan**: `FAHMenuBar.xctestplan` coordinates all tests

## Configuration

### XCConfig Build Settings
Build settings are managed through **XCConfig files** in `Config/`:
- `Config/Shared.xcconfig` - Common settings (bundle ID, versions, deployment target)
- `Config/Debug.xcconfig` - Debug-specific settings  
- `Config/Release.xcconfig` - Release-specific settings
- `Config/Tests.xcconfig` - Test-specific settings

### App Sandbox & Entitlements
The app is sandboxed by default with basic file access. Edit `FAHMenuBar/FAHMenuBar.entitlements` to add capabilities:
```xml
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<!-- Add other entitlements as needed -->
```

## macOS-Specific Features

### Window Management
Add multiple windows and settings panels:
```swift
@main
struct FAHMenuBarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        Settings {
            SettingsView()
        }
    }
}
```

### Asset Management
- **App-Level Assets**: `FAHMenuBar/Assets.xcassets/` (app icon with multiple sizes, accent color)
- **Feature Assets**: Add `Resources/` folder to SPM package if needed

### SPM Package Resources
To include assets in your feature package:
```swift
.target(
    name: "FAHMenuBarFeature",
    dependencies: [],
    resources: [.process("Resources")]
)
```

## Notes

### Generated with XcodeBuildMCP
This project was scaffolded using [XcodeBuildMCP](https://github.com/cameroncooke/XcodeBuildMCP), which provides tools for AI-assisted macOS development workflows.