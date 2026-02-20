# Toolbox

macOS SwiftUI app that wraps CLI tools with a GUI. Tools are defined by JSON config files in `~/.toolbox/tools/` — the app auto-discovers them and renders forms with arguments, flags, and real-time streaming output.

## Build & Run

```bash
xcodebuild -project Toolbox.xcodeproj -scheme Toolbox -configuration Debug build
```

Or open `Toolbox.xcodeproj` in Xcode and hit Run. Requires macOS 14+. App Sandbox is disabled (needed to run `Process`).

## Project Structure

```
Toolbox/
  ToolboxApp.swift              — Entry point, injects ToolManager
  Models/
    Tool.swift                  — Tool, Argument, Flag (Codable structs)
    ToolRunState.swift          — @Observable: output lines, isRunning, exitCode
  Services/
    ToolManager.swift           — Loads JSON from ~/.toolbox/tools/, watches for FS changes
    CommandRunner.swift         — Runs Process + Pipe, streams stdout/stderr; runScript() helper for shell scripts
    KeychainHelper.swift        — Keychain read/write/delete/list for storing env var secrets
  Views/
    ContentView.swift           — NavigationSplitView (sidebar + detail), "+" menu with 3 add-tool options
    SidebarView.swift           — List of tools with icons
    ToolDetailView.swift        — Form fields + Run button + output panel
    CreateToolView.swift        — "Create with AI" sheet: describe a tool, Claude generates config
    AddFromFolderView.swift     — "Add from Folder" sheet: browse to a folder, Claude analyzes it
    AddFromGitHubView.swift     — "Add from GitHub" sheet: paste repo URL, clone + analyze
    ArgumentFieldView.swift     — Renders control per argument type
    OutputView.swift            — Monospaced scrolling terminal output
    SettingsView.swift          — Cmd+, Settings window for managing stored secrets
```

## Directory Layout

```
~/.toolbox/
    tools/       ← JSON configs (watched by ToolManager, auto-discovered)
    scripts/     ← Cloned repos managed by the app (created on first GitHub add)
        repo-name/
            script.sh
            README.md
```

## How Command Execution Works

CommandRunner builds the args array: **flags first** (e.g. `-m`), then **positional arguments** in the order defined in the config. Tilde expansion (`~/` → full path) is only applied to `directory` and `file` type arguments, never to `string` types (to avoid mangling URLs). PATH is augmented with `/opt/homebrew/bin` and `/usr/local/bin` since GUI apps don't inherit shell PATH.

## Adding a New Tool

When the user has a CLI script they want to integrate, create a JSON config file at `~/.toolbox/tools/<tool-name>.json`. The app watches this directory and picks up changes live.

### Config Schema

```json
{
  "name": "Display Name",
  "icon": "sf.symbol.name",
  "description": "Short description shown in sidebar",
  "command": "/absolute/path/to/executable",
  "arguments": [],
  "flags": [],
  "environment": []
}
```

- `name` (string, required) — Display name in the sidebar. Must be unique (used as ID).
- `icon` (string, required) — SF Symbol name (e.g. `arrow.down.circle`, `doc.text`, `terminal`). Browse at https://developer.apple.com/sf-symbols/
- `description` (string, required) — One-line description shown under the name.
- `command` (string, required) — Absolute path to the executable. No tilde, no relative paths.
- `arguments` (array, required) — Positional arguments passed after flags, in order.
- `flags` (array, required) — Boolean or string flags passed before arguments.
- `environment` (array, optional) — Environment variables needed by the tool (e.g. API keys). Values are stored in macOS Keychain and injected at runtime.

### Argument Object

```json
{
  "name": "arg_name",
  "label": "Human Label",
  "type": "string",
  "required": true,
  "placeholder": "hint text...",
  "default": "default value"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes | Internal key, must be unique within the tool |
| `label` | string | yes | Shown as form label |
| `type` | string | yes | One of: `string`, `directory`, `file`, `bool` |
| `required` | bool | yes | If true, Run button is disabled until filled |
| `placeholder` | string | no | Hint text in the text field |
| `default` | string | no | Pre-filled value. Use `~/` for paths (expanded automatically for directory/file types) |

Type → UI control mapping:
- `string` → TextField (value passed as-is, no path expansion)
- `directory` → TextField + Browse button (folder picker, tilde expanded)
- `file` → TextField + Browse button (file picker, tilde expanded)
- `bool` → Toggle

### Flag Object

```json
{
  "name": "flag_name",
  "flag": "-f",
  "label": "Human Label",
  "type": "bool",
  "default": false
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes | Internal key |
| `flag` | string | yes | The actual CLI flag string (e.g. `-m`, `--verbose`) |
| `label` | string | yes | Shown as toggle label |
| `type` | string | yes | `bool` or `string` |
| `default` | bool/string | no | Default value |

Bool flags: when toggled on, the `flag` string is included in the command. When off, it's omitted.

### Environment Object

```json
{
  "name": "ANTHROPIC_API_KEY",
  "label": "Anthropic API Key"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes | Environment variable name (e.g. `ANTHROPIC_API_KEY`) |
| `label` | string | yes | Human-readable label shown in the UI |

Values are entered via SecureFields in the tool detail view and stored in macOS Keychain (service: "Toolbox", account: "toolName.varName"). They are injected into the process environment at runtime. Manage all stored secrets via Cmd+, (Settings).

### Example: Full Config

```json
{
  "name": "YouTube Downloader",
  "icon": "arrow.down.circle",
  "description": "Download videos or audio from YouTube",
  "command": "/Users/jony.money/Documents/Dev/Explorations/ytdownloader/ytdl",
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
  ]
}
```

This produces the command: `ytdl -m https://youtube.com/watch?v=... /Users/jony.money/Downloads`

### Checklist for Adding a Tool

1. Figure out the CLI tool's usage: what flags and positional args it expects.
2. Create `~/.toolbox/tools/<name>.json` matching the schema above.
3. Use `"type": "string"` for URLs, text input, etc. Use `"directory"` / `"file"` only for filesystem paths.
4. Set `"command"` to the **absolute path** of the executable.
5. The app picks it up automatically — no restart needed.

## Adding Tools — Three Ways

The "+" button in the toolbar opens a dropdown menu with three options. All three use `create-tool.sh` with different modes.

### Create with AI (`create` mode)
```bash
./create-tool.sh create "description of the tool"
```
User types a natural language description. Claude generates the config from scratch.

### Add from Folder (`folder` mode)
```bash
./create-tool.sh folder /path/to/tool/folder
```
User browses to a folder containing a script or tool. Claude analyzes the folder contents, finds the executable, and generates a config pointing to it in its original location.

### Add from GitHub (`github` mode)
```bash
./create-tool.sh github https://github.com/user/repo
```
User pastes a GitHub repo URL. The script clones it to `~/.toolbox/scripts/<repo-name>/` (or `git pull` if it already exists), then Claude analyzes the clone and generates a config. Re-adding the same repo updates it instead of failing.

### How it works (all modes)
1. `create-tool.sh` dispatches based on the mode argument
2. The script calls `claude -p` with `--system-prompt` containing the full config schema and `--allowedTools Write,Read,Bash`
3. Claude reads/analyzes the relevant files, figures out the args/flags, and writes the JSON config to `~/.toolbox/tools/`
4. The FS watcher picks it up — the new tool appears in the sidebar immediately
