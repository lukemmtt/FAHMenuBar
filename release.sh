#!/bin/bash
set -e

# Release script for FAH MenuBar
# Usage: ./release.sh [version] "What's new description"
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

# Check for required whatsnew parameter
if [ -z "$2" ] && [ -z "$1" ]; then
    echo "❌ Error: What's new description is required"
    echo "Usage: ./release.sh [version] \"What's new description\""
    echo "   or: ./release.sh \"What's new description\" (auto-bumps version)"
    exit 1
elif [ -z "$2" ] && [ -n "$1" ] && ! [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Single argument that's not a version number - treat as whatsnew
    WHATSNEW="$1"
    NEW_VERSION=""
elif [ -z "$2" ] && [ -n "$1" ] && [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Error: What's new description is required"
    echo "Usage: ./release.sh $1 \"What's new description\""
    exit 1
else
    # Two arguments - version and whatsnew
    NEW_VERSION="$1"
    WHATSNEW="$2"
fi

echo "📝 What's new: $WHATSNEW"

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
    echo "❌ Error: Must be on main branch (currently on $CURRENT_BRANCH)"
    echo "   Please switch to main branch before running release script"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "FAHMenuBar.xcworkspace/contents.xcworkspacedata" ]; then
    echo "❌ Error: Not in FAHMenuBar project root"
    exit 1
fi

# Handle version specification
if [ -n "$NEW_VERSION" ]; then
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

# Archive the app
echo "📦 Archiving app..."
xcodebuild -workspace FAHMenuBar.xcworkspace \
    -scheme FAHMenuBar \
    -configuration Release \
    -archivePath build/FAHMenuBar.xcarchive \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
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

# Generate Sparkle signature
echo "🔏 Generating Sparkle signature..."
SPARKLE_SIGNATURE=$(python3 sign_update.py "FAHMenuBar-$NEW_VERSION.zip" | tail -1 | cut -d' ' -f2)
if [ -z "$SPARKLE_SIGNATURE" ]; then
    echo "❌ Error: Failed to generate Sparkle signature"
    exit 1
fi
echo "✅ Signature generated: ${SPARKLE_SIGNATURE:0:20}..."

# Update appcast.xml
echo "📝 Updating appcast.xml..."
CURRENT_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

# Check if version already exists in appcast and remove ALL entries for this version
if grep -q "<title>FAH MenuBar $NEW_VERSION</title>" appcast.xml; then
    echo "⚠️  Version $NEW_VERSION already exists in appcast.xml, removing all entries..."
    # Remove ALL existing entries for this version (by title)
    perl -i -0pe "s|<item>.*?<title>FAH MenuBar $NEW_VERSION</title>.*?</item>||gs" appcast.xml
fi

# Parse bullet points from WHATSNEW (split on " - " and create separate <li> elements)
# Input:  "- Added feature A - Fixed bug B - Improved performance"
# Output: <li>Added feature A</li>
#         <li>Fixed bug B</li>
#         <li>Improved performance</li>
BULLET_ITEMS=""
if [[ "$WHATSNEW" == *" - "* ]]; then
    # Split on " - " and create <li> elements using sed and while loop
    echo "$WHATSNEW" | sed 's/ - /\n/g' | while read -r bullet; do
        # Skip empty bullets and trim leading/trailing whitespace
        bullet=$(echo "$bullet" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$bullet" ]; then
            # Remove leading dash if it exists
            bullet=$(echo "$bullet" | sed 's/^-[[:space:]]*//')
            echo "                    <li>$bullet</li>" >> /tmp/bullet_items.tmp
        fi
    done
    # Read the generated bullet items
    if [ -f /tmp/bullet_items.tmp ]; then
        BULLET_ITEMS=$(cat /tmp/bullet_items.tmp)
        rm -f /tmp/bullet_items.tmp
    fi
else
    # Single bullet point
    BULLET_ITEMS="                    <li>$WHATSNEW</li>"
fi

# Create temp file with new item
cat > appcast_item.tmp << EOF
        <item>
            <title>FAH MenuBar $NEW_VERSION</title>
            <description><![CDATA[
                <h3>What's New</h3>
                <ul>
$BULLET_ITEMS                </ul>
            ]]></description>
            <pubDate>$CURRENT_DATE</pubDate>
            <sparkle:version>$NEW_BUILD</sparkle:version>
            <sparkle:shortVersionString>$NEW_VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <enclosure 
                url="https://github.com/lukemmtt/FAHMenuBar/releases/download/$NEW_VERSION/FAHMenuBar-$NEW_VERSION.zip"
                length="$FILE_SIZE"
                type="application/octet-stream"
                sparkle:edSignature="$SPARKLE_SIGNATURE" />
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

# Validate appcast has the new build
if ! grep -q "<sparkle:version>$NEW_BUILD</sparkle:version>" appcast.xml; then
    echo "❌ Error: Failed to update appcast.xml with build $NEW_BUILD"
    exit 1
fi
echo "✅ appcast.xml updated successfully"

# Commit all release changes in one commit
echo "💾 Committing release changes..."
git add Config/Shared.xcconfig appcast.xml
git commit -m "Release $NEW_VERSION (build $NEW_BUILD)"

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

- $WHATSNEW

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