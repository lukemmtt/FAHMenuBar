# FAH MenuBar - Native macOS Control for Folding@home

*This is an independent utility, not affiliated with Folding@home.*

**Monitor and manage your [Folding@home](https://foldingathome.org) contributions directly from your menubar.** This lightweight native app provides instant access to your folding status, work unit progress, and quick controls - all without opening a web browser. See real-time updates, pause/resume with one click, and track your points per day right from macOS's menubar.

A more convenient way to keep tabs on your contributions to disease research. Works seamlessly with your existing Folding@home v8 installation.

<img width="340" height="324" alt="470631464-6df35bef-8a1b-4de8-84ea-22942d2e448d" src="https://github.com/user-attachments/assets/5f4f123a-e738-46f1-ac78-703fc9704a69" />

## Why FAH MenuBar?

Folding@home runs as a background service with a web-based control panel. FAH MenuBar provides a native macOS alternative that's always one click away in your menubar:

- **Instant Access** - No need to open a browser or remember URLs
- **Real-time Monitoring** - See live updates of your work unit progress
- **Quick Controls** - Pause/resume folding without leaving your current app
- **Native Experience** - Designed to feel like part of macOS

Everything you need to monitor and control Folding@home, right where you'd expect it on a Mac.

## Background

Folding@home has been moving away from native desktop applications in favor of their web-based interface across all platforms. While this approach has benefits, I believe the easier these tools are to use, the more likely people are to keep folding. The client software is [open source](https://github.com/FoldingAtHome/fah-client-bastet) and runs as a background service.

FAH MenuBar provides native macOS menubar integration for this modern Folding@home setup - bringing the convenience that helps keep people engaged with the project.

## Why I Built This

I created FAH MenuBar because I believe Folding@home offers a simple but meaningful way for people to contribute their unused computing power to important medical research. When your computer would otherwise be idle, it can help scientists understand diseases and develop new treatments. This tool makes it easier to participate in that effort on macOS.

---

*New to Folding@home? It's a distributed computing project helping researchers understand protein folding to develop new therapeutics for diseases. Learn more at [foldingathome.org](https://foldingathome.org). The project is open source and uses frameworks like [GROMACS](https://gromacs.org) and [OpenMM](https://openmm.org/) for simulations.*

## Features

- ✅ **Real-time status** - Shows current folding state and progress
- ✅ **One-click commands** - Pause/resume folding instantly
- ✅ **Progress tracking** - Visual progress bar with percentage and ETA
- ✅ **Native design** - Matches macOS design language
- ✅ **Lightweight** - Minimal resource usage
- ✅ **Auto-updates** - Built-in Sparkle framework for easy updates

## Requirements

- macOS 14.0 (Sonoma) or later
- Folding@home v8 client installed and running (download from [foldingathome.org/start-folding](https://foldingathome.org/start-folding/))
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

1. **Ensure Folding@home is installed and running** - Download from [foldingathome.org/start-folding](https://foldingathome.org/start-folding/) if you haven't already
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

**App shows "Connection Failed"**
- Ensure Folding@home v8 is installed and running - get it from [foldingathome.org/start-folding](https://foldingathome.org/start-folding/)
- The FAH client must be running before launching this menubar app

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

**This tool is not affiliated with Folding@home**, but uses their [official v8 API](https://github.com/FoldingAtHome/fah-client-bastet/discussions/215).

---

⭐ **Found this useful?** Give it a star on GitHub and share with other folders!

🤝 **Want FAH to adopt this officially?** The code is MIT licensed with permissions for official adoption.
