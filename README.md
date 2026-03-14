# Darkside

![license MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-brightgreen?logo=apple)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift)

Black out a secondary monitor on macOS with a global hotkey.

Runs as an invisible background process — no menu bar icon, no Dock icon. Press **Cmd+Option+B** to toggle a black overlay that completely covers a secondary display and blocks all interaction on it.

## Requirements

- macOS 13+
- Swift 5.9+
- A secondary monitor

## Install

```sh
make install
```

This builds the binary, copies it to `/usr/local/bin`, and sets up a Launch Agent that starts Darkside on login.

## Uninstall

```sh
make uninstall
```

## Usage

Darkside runs in the background after installation. The default hotkey is **Cmd+Option+B**.

| Hotkey | Action |
|---|---|
| **Cmd+Option+B** | Toggle blackout on/off |
| **Cmd+Option+Q** | Quit Darkside |

### Monitor targeting

By default, Darkside blacks out the **non-active** screen — whichever monitor doesn't have the cursor. This means the hotkey always darkens "the other screen," regardless of where you're working.

You can also pin it to a specific monitor. Use the interactive picker:

```sh
darkside config --set-monitor
```

This shows a list of all connected monitors with arrow key navigation.

### Persist configuration

```sh
darkside config --set-hotkey "cmd+shift+x"
darkside config --set-monitor
darkside config --show
```

Config is saved to `~/.config/darkside/config.json`. Changes are picked up automatically — no restart needed.

### Override at launch

```sh
darkside --hotkey "cmd+shift+x" --monitor 1
```

### Behavior

- **Toggle on:** Blacks out the target monitor, blocks all mouse interaction
- **Toggle off:** Removes the overlay, restores normal use
- **No secondary monitor:** Plays a system beep, no crash

## Privacy & Security

Darkside is designed to be minimal and trustworthy:

- **No network access** — no networking code, no URL requests, no sockets; audit the source to verify
- **No accessibility permissions** — the global hotkey uses Carbon `RegisterEventHotKey`, which only delivers the specific registered key combo, not all keystrokes
- **No data collection** — no analytics, no telemetry
- **No persistent overlay** — the black panel only exists while the blackout is active; toggling off or quitting removes it entirely
- **Open source** — audit the code yourself

## Build from source

```sh
swift build -c release
# Binary at .build/release/Darkside
```

## License

MIT
