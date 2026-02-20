# ShareToolBox

A native macOS app that wraps CLI tools with a graphical interface. Define tools with JSON configs, and ShareToolBox auto-generates forms with arguments, flags, and real-time streaming output. Each run is saved as a persistent session you can revisit anytime.

## Features

- **Session-based workflow** — Each tool run creates a persistent session. Inputs and output are saved to disk and restored on relaunch. Switch between sessions without losing state.
- **Auto-generated forms** — Declare arguments, flags, and environment variables in JSON. ShareToolBox renders the appropriate controls (text fields, file/folder pickers, toggles, secure fields).
- **Real-time streaming output** — stdout and stderr stream live into a terminal-style output panel with color-coded error lines.
- **Secure secret storage** — API keys and tokens are stored in the macOS Keychain and injected at runtime. Never saved to disk in plaintext.
- **Live auto-discovery** — Drop a JSON config into `~/.sharetoolbox/tools/` and it appears instantly. No restart needed.
- **AI-powered tool creation** — Create tool configs from a description, analyze a local folder, or clone a GitHub repo. Claude generates the JSON config automatically.
- **Session history** — Sidebar groups sessions by date (Today, Yesterday, This Week, Older) with live run indicators and completion status.

## Requirements

- macOS 14+
- Xcode 15+ (to build)

## Build & Run

```bash
xcodebuild -project ShareToolBox.xcodeproj -scheme ShareToolBox -configuration Debug build
```

Or open `ShareToolBox.xcodeproj` in Xcode and press Run.

## Quick Start

1. Build and launch ShareToolBox
2. Create a JSON config file at `~/.sharetoolbox/tools/my-tool.json`
3. The tool appears in the home screen grid
4. Click it to create a session, fill in the form, and hit Run

## Tool Config Schema

Tools are defined by JSON files in `~/.sharetoolbox/tools/`. Each file describes a CLI tool's interface:

```json
{
  "name": "YouTube Downloader",
  "icon": "arrow.down.circle",
  "description": "Download videos or audio from YouTube",
  "command": "/usr/local/bin/ytdl",
  "arguments": [
    {
      "name": "url",
      "label": "YouTube URL",
      "type": "string",
      "required": true,
      "placeholder": "https://youtube.com/watch?v=..."
    },
    {
      "name": "output_dir",
      "label": "Output Directory",
      "type": "directory",
      "required": false,
      "default": "~/Downloads"
    }
  ],
  "flags": [
    {
      "name": "music_only",
      "flag": "-m",
      "label": "Audio only (MP3)",
      "type": "bool",
      "default": false
    }
  ],
  "environment": [
    {
      "name": "API_KEY",
      "label": "Service API Key"
    }
  ]
}
```

### Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Display name (must be unique) |
| `icon` | string | yes | [SF Symbol](https://developer.apple.com/sf-symbols/) name |
| `description` | string | yes | One-line description |
| `command` | string | yes | Absolute path to the executable |
| `arguments` | array | yes | Positional arguments |
| `flags` | array | yes | Boolean or string flags |
| `environment` | array | no | Environment variables (stored in Keychain) |

### Argument Types

| Type | UI Control | Notes |
|---|---|---|
| `string` | Text field | Value passed as-is |
| `directory` | Text field + Browse | Tilde expanded |
| `file` | Text field + Browse | Tilde expanded |
| `bool` | Toggle | — |

### Adding Tools via the App

Click the **Add Tool** card on the home screen:

- **Create with AI** — Describe what you want and Claude generates the config
- **Add from Folder** — Point to a local folder with a script; Claude analyzes it
- **Add from GitHub** — Paste a repo URL; the app clones it and generates a config

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Cmd+N | New session (back to tool picker) |
| Cmd+Return | Run the current tool |
| Cmd+, | Settings (manage stored secrets) |

## Directory Layout

```
~/.sharetoolbox/
    tools/       JSON tool configs (auto-discovered)
    sessions/    Persisted session data (inputs + output)
    scripts/     Cloned GitHub repositories
```

## License

MIT
