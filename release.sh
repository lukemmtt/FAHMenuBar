#!/bin/bash
set -e

# Release script for FAH MenuBar
# This script:
# 1. Validates clean working directory
# 2. Bumps the patch version (1.0.x -> 1.0.x+1) or uses specified version
# 3. Cleans up any existing releases/tags if recreating
# 4. Updates Xcode project version
# 5. Archives and exports the app
# 6. Notarizes with Apple
# 7. Creates a zip for distribution
# 8. Updates and validates appcast.xml
# 9. Creates GitHub release

echo "🚀 FAH MenuBar Release Script"

# Get script directory and cd to project root FIRST
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Pre-flight checks
echo "🔍 Running pre-flight checks..."

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "❌ Error: Working directory has uncommitted changes"
    echo "   Please commit or stash all changes before running release script"
    git status --short
    exit 1
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️  Warning: Not on main branch (currently on $CURRENT_BRANCH)"
    echo "   Continuing anyway..."
fi

# Check if we're in the right directory
if [ ! -f "FAHMenuBar.xcworkspace/contents.xcworkspacedata" ]; then
    echo "❌ Error: Not in FAHMenuBar project root"
    exit 1
fi

# Allow version override via command line
if [ -n "$1" ]; then
    NEW_VERSION="$1"
    echo "📌 Using specified version: $NEW_VERSION"
    
    # Validate version format
    if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "❌ Error: Invalid version format. Use X.Y.Z (e.g., 1.0.1)"
        exit 1
    fi
else
    # Get latest release version from GitHub
    echo "🔍 Checking latest GitHub release..."
    LATEST_RELEASE=$(gh release list --limit 1 | awk '{print $3}')
    if [ -z "$LATEST_RELEASE" ]; then
        echo "⚠️  No releases found on GitHub, using version from Shared.xcconfig"
        CURRENT_VERSION=$(grep "MARKETING_VERSION" Config/Shared.xcconfig | cut -d'=' -f2 | xargs)
    else
        # Strip 'v' prefix if present
        CURRENT_VERSION="${LATEST_RELEASE#v}"
        echo "📌 Latest GitHub release: $CURRENT_VERSION"
    fi
    
    # Parse version components
    IFS='.' read -r -a version_parts <<< "$CURRENT_VERSION"
    MAJOR="${version_parts[0]}"
    MINOR="${version_parts[1]}"
    PATCH="${version_parts[2]:-0}"
    
    # Bump patch version
    NEW_PATCH=$((PATCH + 1))
    NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
    echo "📈 New version: $NEW_VERSION"
fi

# Check if this version already exists and clean up if needed
CLEANUP_NEEDED=false
if gh release view "$NEW_VERSION" &>/dev/null; then
    echo "⚠️  Warning: Release $NEW_VERSION already exists on GitHub"
    CLEANUP_NEEDED=true
fi

if git tag -l | grep -q "^${NEW_VERSION}$"; then
    echo "⚠️  Warning: Tag $NEW_VERSION already exists locally"
    CLEANUP_NEEDED=true
fi

if [ "$CLEANUP_NEEDED" = true ]; then
    echo "🧹 Cleaning up existing release artifacts..."
    
    # Delete GitHub release if it exists
    if gh release view "$NEW_VERSION" &>/dev/null; then
        echo "   - Deleting GitHub release $NEW_VERSION"
        gh release delete "$NEW_VERSION" --yes || true
    fi
    
    # Delete local tag if it exists
    if git tag -l | grep -q "^${NEW_VERSION}$"; then
        echo "   - Deleting local tag $NEW_VERSION"
        git tag -d "$NEW_VERSION" || true
    fi
    
    # Delete remote tag if it exists
    if git ls-remote --tags origin | grep -q "refs/tags/${NEW_VERSION}$"; then
        echo "   - Deleting remote tag $NEW_VERSION"
        git push origin --delete "refs/tags/$NEW_VERSION" || true
    fi
    
    echo "✅ Cleanup complete"
fi

# Get current build number and increment it
CURRENT_BUILD=$(grep "CURRENT_PROJECT_VERSION" Config/Shared.xcconfig | cut -d'=' -f2 | xargs)
if [ -z "$CURRENT_BUILD" ] || [ "$CURRENT_BUILD" -lt 5 ]; then
    NEW_BUILD=5
else
    NEW_BUILD=$((CURRENT_BUILD + 1))
fi

# Update version in Shared.xcconfig
sed -i '' "s/MARKETING_VERSION = .*/MARKETING_VERSION = $NEW_VERSION/" Config/Shared.xcconfig
sed -i '' "s/CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = $NEW_BUILD/" Config/Shared.xcconfig

echo "✅ Updated version numbers (v$NEW_VERSION build $NEW_BUILD)"

# Commit version changes immediately
echo "💾 Committing version bump..."
git add Config/Shared.xcconfig
git commit -m "Bump version to $NEW_VERSION build $NEW_BUILD"

# Archive the app
echo "📦 Archiving app..."
xcodebuild -workspace FAHMenuBar.xcworkspace \
    -scheme FAHMenuBar \
    -configuration Release \
    -archivePath build/FAHMenuBar.xcarchive \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM=Z7YQK9S6SZ \
    CODE_SIGN_IDENTITY="Developer ID Application: TimeFinder, LLC (Z7YQK9S6SZ)" \
    PROVISIONING_PROFILE_SPECIFIER="" \
    archive

# Export the app
echo "📤 Exporting app..."
cat > build/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>Z7YQK9S6SZ</string>
    <key>signingCertificate</key>
    <string>Developer ID Application: TimeFinder, LLC</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.lukememet.FAHmenuBar</key>
        <string></string>
    </dict>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath build/FAHMenuBar.xcarchive \
    -exportPath build/export \
    -exportOptionsPlist build/ExportOptions.plist

# Create a timestamped folder for notarization
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
NOTARIZE_PATH="build/notarize_$TIMESTAMP"
mkdir -p "$NOTARIZE_PATH"
cp -R "build/export/FAHMenuBar.app" "$NOTARIZE_PATH/"

# Create zip for notarization
echo "🤐 Creating zip for notarization..."
cd "$NOTARIZE_PATH"
ditto -c -k --keepParent "FAHMenuBar.app" "../FAHMenuBar-$NEW_VERSION.zip"
cd - > /dev/null

# Notarize
echo "🔏 Notarizing app..."
echo "💡 Tip: Store your app-specific password in keychain with:"
echo "   xcrun notarytool store-credentials --apple-id lukememet@gmail.com --team-id Z7YQK9S6SZ"
echo ""

# Try to use stored credentials first, fall back to prompting
if xcrun notarytool submit "build/FAHMenuBar-$NEW_VERSION.zip" \
    --keychain-profile "notarytool-password" \
    --wait 2>/dev/null; then
    echo "✅ Used stored credentials"
else
    echo "⚠️  No stored credentials found, prompting for app-specific password..."
    echo "Please enter your app-specific password (not your Apple ID password)"
    xcrun notarytool submit "build/FAHMenuBar-$NEW_VERSION.zip" \
        --apple-id lukememet@gmail.com \
        --team-id Z7YQK9S6SZ \
        --wait
fi

# Staple the notarization
echo "📎 Stapling notarization..."
xcrun stapler staple "$NOTARIZE_PATH/FAHMenuBar.app"

# Create final distribution zip
echo "📦 Creating distribution zip..."
cd "$NOTARIZE_PATH"
ditto -c -k --keepParent "FAHMenuBar.app" "../../FAHMenuBar-$NEW_VERSION.zip"
cd - > /dev/null

# Get file size for appcast
FILE_SIZE=$(stat -f%z "FAHMenuBar-$NEW_VERSION.zip")
echo "📏 File size: $FILE_SIZE bytes"

# Update appcast.xml
echo "📝 Updating appcast.xml..."
CURRENT_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

# Check if version already exists in appcast
if grep -q "<sparkle:version>$NEW_VERSION</sparkle:version>" appcast.xml; then
    echo "⚠️  Version $NEW_VERSION already exists in appcast.xml, removing old entry..."
    # Remove the existing entry for this version
    perl -i -0pe "s|<item>.*?<sparkle:version>$NEW_VERSION</sparkle:version>.*?</item>||gs" appcast.xml
fi

# Create temp file with new item
cat > appcast_item.tmp << EOF
        <item>
            <title>FAH MenuBar $NEW_VERSION</title>
            <description><![CDATA[
                <h3>Bug Fixes and Improvements</h3>
                <ul>
                    <li>Fixed Sparkle auto-update configuration</li>
                </ul>
            ]]></description>
            <pubDate>$CURRENT_DATE</pubDate>
            <sparkle:version>$NEW_VERSION</sparkle:version>
            <sparkle:shortVersionString>$NEW_VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <enclosure 
                url="https://github.com/lukemmtt/FAHMenuBar/releases/download/$NEW_VERSION/FAHMenuBar-$NEW_VERSION.zip"
                length="$FILE_SIZE"
                type="application/octet-stream" />
        </item>
EOF

# Insert new item after lastBuildDate
perl -i -pe 'if (/<lastBuildDate>/) { 
    print; 
    print "\n"; 
    open(ITEM, "appcast_item.tmp"); 
    print while <ITEM>; 
    close(ITEM); 
    $_ = ""; 
}' appcast.xml

# Update lastBuildDate
sed -i '' "s|<lastBuildDate>.*</lastBuildDate>|<lastBuildDate>$CURRENT_DATE</lastBuildDate>|" appcast.xml

# Clean up temp file
rm -f appcast_item.tmp

# Validate appcast has the new version
if ! grep -q "<sparkle:version>$NEW_VERSION</sparkle:version>" appcast.xml; then
    echo "❌ Error: Failed to update appcast.xml with version $NEW_VERSION"
    exit 1
fi
echo "✅ appcast.xml updated successfully"

# Commit appcast changes
echo "💾 Committing appcast update..."
git add appcast.xml
git commit -m "Update appcast.xml for release $NEW_VERSION"

# Create and push tag
echo "🏷️  Creating tag..."
git tag -a "$NEW_VERSION" -m "Version $NEW_VERSION"
git push origin main
git push origin "$NEW_VERSION"

# Create GitHub release
echo "🚀 Creating GitHub release..."
gh release create "$NEW_VERSION" \
    --title "FAH MenuBar $NEW_VERSION" \
    --notes "## What's New

- Minor bug fixes and performance improvements

## Requirements
- macOS 14.0 or later
- Folding@home v8 client installed and running

*This is an independent utility, not affiliated with Folding@home.*" \
    "FAHMenuBar-$NEW_VERSION.zip" \
    --draft=false

echo "✅ Release $NEW_VERSION complete!"
echo ""
echo "📋 Summary:"
echo "  - Version bumped from $CURRENT_VERSION to $NEW_VERSION"
echo "  - App archived, exported, and notarized"
echo "  - appcast.xml updated"
echo "  - GitHub release created with download"
echo ""
echo "🎉 Users will now receive the update automatically!"