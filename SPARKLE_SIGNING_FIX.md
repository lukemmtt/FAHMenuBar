# Sparkle Framework Signing Fix

## Problem Summary
When creating releases of FAHMenuBar, the Sparkle framework was causing code signing validation failures:
- Extended attributes (specifically `com.apple.provenance`) were being added during Xcode export
- These attributes get converted to "._" files when zipped, breaking the seal
- Removing the attributes with `xattr -cr` wasn't working on macOS Ventura+

## Root Cause
1. Xcode's `-exportArchive` adds `com.apple.provenance` extended attributes to track file origin
2. These attributes cannot be removed with standard `xattr` commands on newer macOS
3. When zipping, these attributes create "._" resource fork files that break code signatures

## Solution
The fix is much simpler than initially thought:

1. **Use ditto with --norsrc flag**:
```bash
ditto -c -k --norsrc --keepParent "FAHMenuBar.app" "FAHMenuBar.zip"
```

2. **Key flags explained**:
   - `-c` - Create an archive
   - `-k` - Create PKZip format (instead of CPIO)
   - `--norsrc` - Do not preserve resource forks and extended attributes
   - `--keepParent` - Keep the parent directory in the archive

3. **Why this works**:
   - The `--norsrc` flag prevents ditto from creating AppleDouble (._) files
   - Extended attributes like `com.apple.provenance` are simply excluded
   - The app's code signature remains valid because we're not modifying the app
   - No need to remove attributes or re-sign - just zip correctly

## Verification
After implementing this fix:
- ✅ No "._" files in the zip archive
- ✅ Code signature validates: `codesign -vvv` passes
- ✅ Only fails `spctl` due to notarization (expected before notarizing)

## Implementation
The fix has been integrated into `release.sh` and will be applied automatically in future releases.