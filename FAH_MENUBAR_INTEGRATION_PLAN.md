# FAHMenuBar Integration Plan for Folding@home Client

## Executive Summary

This document outlines the plan to integrate FAHMenuBar into the official Folding@home client distribution as an embedded menu bar application for macOS, providing feature parity with Windows system tray functionality.

## Integration Strategy: Embedded App Bundle

FAHMenuBar will remain fundamentally unchanged as a Swift/SwiftUI application. The integration focuses on:
1. Thoughtful directory structure within fah-client-bastet
2. Build system integration (with flexibility for separate compilation)
3. Installer bundling to ensure seamless deployment

## Directory Structure

### Proposed Layout within fah-client-bastet
```
fah-client-bastet/
├── src/
│   ├── fah/
│   │   └── client/
│   │       ├── osx/
│   │       │   ├── OSXOSImpl.cpp         (existing)
│   │       │   ├── OSXOSImpl.h           (existing)
│   │       │   └── OSXMenuBarLauncher.h  (new - optional)
│   │       └── win/
│   │           └── WinOSImpl.cpp         (existing systray)
│   └── menubar/                          (new directory)
│       ├── FAHMenuBar.xcodeproj/
│       ├── FAHMenuBar/
│       │   ├── FAHMenuBarApp.swift
│       │   ├── Info.plist
│       │   └── Assets.xcassets/
│       ├── FAHMenuBarPackage/
│       │   ├── Package.swift
│       │   └── Sources/
│       └── README.md
├── install/
│   └── osx/
│       ├── Resources/
│       │   └── FAHMenuBar.app/           (built artifact)
│       └── scripts/
│           └── postinstall               (modified)
└── SConstruct                            (modified)
```

### Alternative: Git Submodule Approach
```
fah-client-bastet/
├── src/
│   └── menubar/                          (git submodule)
│       └── [FAHMenuBar repo contents]
├── .gitmodules
└── build/
    └── osx/
        └── FAHMenuBar.app/               (built artifact)
```

## Build System Integration

### Option A: Direct SCons Integration
Compile FAHMenuBar as part of the main client build process.

```python
# File: SConstruct
if env['PLATFORM'] == 'darwin':
    conf.RequireOSXFramework('SystemConfiguration')
    
    # Option to build menubar (default enabled for macOS)
    env.CBAddVariables(
        BoolVariable('build_menubar', 
                     'Build macOS menu bar app', 
                     env['PLATFORM'] == 'darwin'))

# File: src/menubar.scons (new)
Import('env')

if env.get('build_menubar'):
    # Build FAHMenuBar using xcodebuild
    menubar_build = env.Command(
        'FAHMenuBar.app',
        ['menubar/FAHMenuBar.xcodeproj/project.pbxproj',
         env.Glob('menubar/FAHMenuBar/*'),
         env.Glob('menubar/FAHMenuBarPackage/Sources/**/*')],
        [
            'cd ${SOURCE.dir.dir} && ' +
            'xcodebuild -project FAHMenuBar.xcodeproj ' +
            '-scheme FAHMenuBar -configuration Release ' +
            '-derivedDataPath ${TARGET.dir}/DerivedData ' +
            'SYMROOT=${TARGET.dir} ' +
            'CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY"'
        ]
    )
    
    # Install to package resources
    env.Install('$PACKAGE_RESOURCES/osx', menubar_build)
```

### Option B: External Build with Integration Script
Keep FAHMenuBar compilation separate but integrate at package time.

```bash
# File: build_scripts/build_menubar.sh
#!/bin/bash
set -e

MENUBAR_REPO=${1:-"https://github.com/FoldingAtHome/FAHMenuBar.git"}
MENUBAR_TAG=${2:-"main"}
OUTPUT_DIR=${3:-"build/osx/Resources"}

# Clone or update
if [ -d "temp/FAHMenuBar" ]; then
    cd temp/FAHMenuBar && git fetch && git checkout $MENUBAR_TAG
else
    git clone $MENUBAR_REPO temp/FAHMenuBar
    cd temp/FAHMenuBar && git checkout $MENUBAR_TAG
fi

# Build
xcodebuild -project FAHMenuBar.xcworkspace \
    -scheme FAHMenuBar \
    -configuration Release \
    -derivedDataPath DerivedData \
    CODE_SIGN_IDENTITY="$FAH_CODE_SIGN_IDENTITY"

# Copy to output
cp -R "DerivedData/Build/Products/Release/FAH MenuBar.app" "$OUTPUT_DIR/"
```

### Option C: Git Submodule Approach
Most flexible - allows independent development while ensuring consistent builds.

```bash
# Initial setup
git submodule add https://github.com/FoldingAtHome/FAHMenuBar.git src/menubar
git submodule update --init --recursive

# .gitmodules
[submodule "src/menubar"]
    path = src/menubar
    url = https://github.com/FoldingAtHome/FAHMenuBar.git
    branch = release/v8-integration
```

```python
# SConstruct modification
if env['PLATFORM'] == 'darwin' and os.path.exists('src/menubar'):
    SConscript('src/menubar.scons', exports='env')
```

### Package Structure
The installer package structure mirrors the approach used for other macOS resources:

```
fah-client_8.x.x_universal.pkg/
├── Contents/
│   ├── Resources/
│   │   ├── FAHMenuBar.app/           # Built menu bar app
│   │   ├── en.lproj/
│   │   └── ...
│   └── MacOS/
│       └── fah-client
```

### Installation Approach
The menu bar app is installed alongside the main client but remains independent:

```bash
# File: install/osx/scripts/postinstall (modification)

# Install FAHMenuBar to /Applications
if [ -f "$RESOURCES_PATH/FAHMenuBar.app/Contents/MacOS/FAH MenuBar" ]; then
    cp -R "$RESOURCES_PATH/FAHMenuBar.app" "/Applications/FAH MenuBar.app"
    
    # Set proper permissions
    chmod -R 755 "/Applications/FAH MenuBar.app"
    
    # Add to login items for current user
    if [ "$USER" != "root" ] && [ -n "$USER" ]; then
        osascript <<EOF
tell application "System Events"
    make login item at end with properties {path:"/Applications/FAH MenuBar.app", hidden:false}
end tell
EOF
        
        # Launch immediately for current user
        sudo -u "$USER" open "/Applications/FAH MenuBar.app"
    fi
fi
```

### Uninstaller Considerations
```bash
# File: install/osx/scripts/uninstall (modification)

# Remove FAHMenuBar
rm -rf "/Applications/FAH MenuBar.app"

# Remove from login items
osascript <<EOF
tell application "System Events"
    delete login item "FAH MenuBar"
end tell
EOF

# Kill running instance
pkill -f "FAH MenuBar"
```

## Minimal Code Changes

### FAHMenuBar Side
The application requires minimal changes - primarily adding detection for bundled mode:

```swift
// File: FAHMenuBarApp.swift
func applicationDidFinishLaunching(_ notification: Notification) {
    // Existing code...
    
    // Check if we're bundled with official client
    if isBundledWithClient() {
        // Disable Sparkle auto-updates
        updaterController.automaticallyChecksForUpdates = false
    }
}

private func isBundledWithClient() -> Bool {
    // Check for presence of FAH client or specific marker file
    return FileManager.default.fileExists(atPath: "/Library/Application Support/FAHClient/.bundled")
}
```

### Client Side (Optional)
The client doesn't need to manage the menu bar app directly, but could optionally provide a launcher:

```cpp
// File: src/fah/client/osx/OSXOSImpl.cpp (optional addition)
void OSXOSImpl::notifyMenuBar(const std::string& message) {
    // Send distributed notification that menu bar can listen for
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDistributedCenter(),
        CFSTR("org.foldingathome.client.status"),
        NULL, NULL, true);
}
```

## Build System Recommendations

**Recommended Approach: Option C (Git Submodule)**

This provides the best balance of:
- Independent development and versioning
- Consistent builds with specific versions
- Easy updates by changing submodule commit
- Clear separation of Swift and C++ codebases

Implementation:
1. FAH team forks FAHMenuBar to their GitHub
2. Add as submodule in fah-client-bastet
3. Build script compiles it during package creation
4. No changes needed to core client build

## Summary

This integration plan keeps FAHMenuBar fundamentally unchanged while thoughtfully integrating it into the FAH client distribution. The key principles:

1. **Minimal Changes**: FAHMenuBar works as-is, just needs bundling
2. **Clean Separation**: Swift UI code stays separate from C++ core
3. **User Experience**: Seamless installation and launch
4. **Maintainability**: Easy to update independently
5. **Flexibility**: Multiple build options to suit FAH team preferences

The existing WebSocket API means no integration code is needed - the menu bar app already knows how to talk to the client. This is purely a packaging and distribution exercise.