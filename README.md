# FAH MenuBar – macOS Menubar Control for Folding\@home

*A lightweight, native macOS utility for monitoring and managing *[*Folding@home*](https://foldingathome.org)* directly from your menubar.*

**Not officially affiliated with Folding\@home.**

<img width="324" height="361" alt="Screenshot 2025-07-25 at 1 17 06 PM" src="https://github.com/user-attachments/assets/dea19233-68dd-4772-84db-35004a73a472" />

---

## What is FAH MenuBar?

FAH MenuBar is a convenient macOS app that provides instant, native access to your Folding\@home status and controls—no browser required. Track your contributions to disease research effortlessly from your Mac’s menubar.


## Features

- ✅ **Instant Status:** View real-time folding status directly from your menubar.
- ✅ **Quick Controls:** Pause/resume folding with a single click.
- ✅ **Progress Tracking:** Visual progress bar with percentage and estimated completion time.
- ✅ **Native macOS Design:** Blends seamlessly with your macOS interface.
- ✅ **Resource-Friendly:** Minimal CPU and memory usage.
- ✅ **Auto Updates:** Keeps itself up-to-date automatically via Sparkle.
- ✅ **Privacy & Security:** No external data collection. No modification to your Folding@home installation.


## Why Use FAH MenuBar?

Folding\@home typically runs as a background process with a web-based interface. FAH MenuBar makes folding more accessible by providing:

- **Easy Monitoring:** Instantly see your work unit's progress.
- **Convenience:** No need to open browsers or remember web addresses.
- **Improved Engagement:** Making folding visible encourages ongoing participation.

## Getting Started

### Requirements

- macOS 14.0 (Sonoma) or later
- Folding\@home v8 client installed ([Download here](https://foldingathome.org/start-folding/))
- Intel or Apple Silicon Mac

### Installation

**Option 1: Pre-built App (Recommended)**

1. Download the latest release from the [Releases page](https://github.com/lukemmtt/FAHMenuBar/releases).
2. Unzip and move `FAH MenuBar.app` to your Applications folder.
3. Launch the app—it will appear in your menubar.

**Option 2: Build from Source**

```bash
git clone https://github.com/lukemmtt/FAHMenuBar.git
cd FAHMenuBar
open FAHMenuBar.xcworkspace
# Build and run via Xcode
```

## Usage

- Ensure Folding\@home v8 is running.
- Click the cube icon in your menubar to view status and controls.
- Pause or resume folding directly from the dropdown.

## How It Works

FAH MenuBar connects to Folding\@home v8's official WebSocket API (from [FAH's own open source client repository](https://github.com/FoldingAtHome/fah-client-bastet)) to display real-time updates and manage your folding status.

## Contributing

This is an open-source project—your input is welcome!

- Report issues or request features via [GitHub Issues](https://github.com/lukemmtt/FAHMenuBar/issues).
- Submit code improvements via Pull Requests.

## License

MIT License – see [LICENSE](LICENSE).

## About Folding\@home

Folding\@home is a distributed computing project aiding scientists in understanding diseases by simulating protein folding. Learn more at [foldingathome.org](https://foldingathome.org).

---

⭐ **Enjoying FAH MenuBar?** Star it on GitHub and share with fellow folders!

🤝 **Official Adoption:** This project is MIT licensed and open for official Folding\@home adoption.

Created by [Luke Memet](https://github.com/lukemmtt).

