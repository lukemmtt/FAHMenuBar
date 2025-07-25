# FAH MenuBar - macOS Menubar App

A native macOS menubar app for Folding@home v8 that provides quick access to folding status and commands directly from your menu bar.

**What is Folding@home?** Folding@home is a distributed computing project that simulates protein folding to help research diseases like Alzheimer's, Huntington's, Parkinson's, and many cancers. Learn more at [foldingathome.org](https://foldingathome.org).

**⚠️ Disclaimer:** This utility and its author are **not affiliated with** the Folding@home project. This is an independent community tool.

**FAH MenuBar Screenshot**

<img width="341" height="374" alt="screenshot" src="https://github.com/user-attachments/assets/79a6b673-7e38-4ff3-91c2-bc8cbb9ddf8d" />

## What is this?

Folding@home for macOS only provides a web interface. This menubar app gives you quick native access to:

- **View folding status** - See if you're actively folding or paused
- **Pause/resume folding** - One-click folding commands
- **Monitor progress** - Real-time progress bar and ETA for current work units
- **Native macOS integration** - Lives in your menubar like other system tools

## Features

- ✅ **Real-time status** - Shows current folding state and progress
- ✅ **One-click commands** - Pause/resume folding instantly
- ✅ **Progress tracking** - Visual progress bar with percentage and ETA
- ✅ **Native design** - Matches macOS design language
- ✅ **Lightweight** - Minimal resource usage
- ✅ **Auto-updates** - Built-in Sparkle framework for easy updates

## Requirements

- macOS 14.0 (Sonoma) or later
- Folding@home v8 client installed and running
- Intel or Apple Silicon Mac

## Installation

### Option 1: Download Pre-built App (Recommended)

1. **Download** the latest release from the [Releases page](https://github.com/lukemmtt/FAHMenuBar/releases)
2. **Unzip** the downloaded file
3. **Move** `FAH MenuBar.app` to your Applications folder
4. **Launch** the app - it will appear in your menubar

### Option 2: Build from Source

```bash
git clone https://github.com/lukemmtt/FAHMenuBar.git
cd FAHMenuBar
open FAHMenuBar.xcworkspace
# Build and run from Xcode
```

## Usage

1. **Ensure Folding@home is running** - The menubar app connects to your local FAH client
2. **Click the cube icon** in your menubar
3. **View status** - See if you're folding, paused, or stopped
4. **Use commands** - Click "Pause" or "Fold" to change your status
5. **Monitor progress** - Watch the progress bar and ETA for current work units

## How it Works

This app connects to Folding@home v8's official WebSocket API to:
- Retrieve real-time folding status and work unit information
- Send pause/resume/fold commands
- Monitor progress and display updates in the menubar

It does NOT:
- Send data to external servers
- Modify your FAH configuration files
- Interfere with the normal operation of Folding@home

## Troubleshooting

**App shows "Disconnected"**
- Ensure Folding@home v8 is installed and running
- Check that FAH is accessible at http://localhost:7396 in your browser

**Commands don't work**
- Make sure you're running Folding@home v8 (not v7)
- Restart both the FAH client and this menubar app

## Contributing

This is an open-source community project. Contributions welcome!

- **Report bugs** - Use GitHub Issues
- **Request features** - Open a GitHub Issue with your idea
- **Submit code** - Fork, make changes, and submit a Pull Request

## License

MIT License - See [LICENSE](LICENSE) file for details.

## About

Created by [Luke Memet](https://github.com/lukemmtt) to provide macOS users with native Folding@home menubar access.

**This tool is not affiliated with Folding@home**, but uses their official v8 API.

---

⭐ **Found this useful?** Give it a star on GitHub and share with other folders!

🤝 **Want FAH to adopt this officially?** The code is MIT licensed with permissions for official adoption.
