# Feature Catalog

> Last updated: 2026-02-20
> Total features: 8

## Table of Contents
- [Tool Management](#tool-management)
- [User Interface](#user-interface)
- [Security & Secrets](#security--secrets)
- [Execution Engine](#execution-engine)
- [Tool Discovery & Creation](#tool-discovery--creation)

---

## Tool Management

### JSON-Based Tool Configuration
- **Status**: Active
- **Added**: Initial release
- **Summary**: Define any CLI tool as a simple JSON file and Toolbox gives it a full graphical interface automatically.
- **Description**: Each tool is defined by a JSON config file in `~/.toolbox/tools/`. The config declares the tool's display name, icon (SF Symbols), description, executable path, positional arguments, flags, and environment variables. The app auto-discovers configs and renders a complete form-based GUI for each tool.
- **Technical Details**: Uses Swift `Codable` structs (`Tool`, `Argument`, `Flag`, `EnvironmentVar`) to decode JSON configs. Supports argument types: `string`, `directory`, `file`, `bool`. Flag types: `bool`, `string`. The `environment` array is optional.
- **Key Capabilities**:
  - Declarative JSON schema for defining CLI tools
  - Support for positional arguments with type-specific UI controls (text fields, file/folder pickers, toggles)
  - Boolean and string flags with configurable CLI flag strings
  - Optional environment variable declarations for API keys and secrets
  - Default values and placeholder text for arguments
  - Required field validation
- **Tags**: configuration, JSON, CLI, tools, schema

### Live Tool Auto-Discovery
- **Status**: Active
- **Added**: Initial release
- **Summary**: Add or update tools by dropping a JSON file into a folder -- no restart needed.
- **Description**: Toolbox watches the `~/.toolbox/tools/` directory for filesystem changes. When a new JSON config is added, modified, or removed, the sidebar updates automatically. Users never need to restart the app to pick up changes.
- **Technical Details**: `ToolManager` uses filesystem observation to monitor `~/.toolbox/tools/`. Tools are identified by their `name` field, which also serves as their unique ID.
- **Key Capabilities**:
  - Real-time filesystem watching of the tools directory
  - Automatic sidebar refresh on config changes
  - No app restart required for tool updates
- **Tags**: auto-discovery, file-watching, live-reload

---

## User Interface

### Tool Detail Form
- **Status**: Active
- **Added**: Initial release
- **Summary**: Every tool gets a polished, auto-generated form with arguments, options, and a one-click Run button.
- **Description**: Selecting a tool in the sidebar presents a detail view with a header (icon, name, description), grouped form sections for arguments, flags, and environment variables, a Run button (Cmd+Return), and a streaming output panel. Required fields are marked with a red asterisk, and the Run button is disabled until all required fields are filled.
- **Technical Details**: Built with SwiftUI `NavigationSplitView`. Uses `GroupBox` sections for Arguments, Options, and Environment. `ArgumentFieldView` renders type-appropriate controls: `TextField` for strings, `TextField` + folder/file picker for `directory`/`file`, and `Toggle` for `bool`. The output panel uses a monospaced scrolling view with color-coded stdout/stderr.
- **Key Capabilities**:
  - Auto-generated form fields based on tool config
  - Type-specific input controls (text, file picker, folder picker, toggle)
  - Required field validation with visual indicators
  - Cmd+Return keyboard shortcut to run
  - Clear button to reset output
  - Tilde expansion for directory and file paths
- **Tags**: UI, forms, SwiftUI, detail-view

### Settings Window
- **Status**: Active
- **Added**: 2026-02-20
- **Summary**: Manage all your stored API keys and secrets in one place with the standard macOS Settings window.
- **Description**: Accessible via Cmd+, (the standard macOS Settings shortcut), the Settings window lists all stored secrets grouped by tool name. Users can see which environment variables are set, edit values inline via secure input fields, or delete them from the Keychain. Only tools that declare environment variables in their config appear in the list.
- **Technical Details**: Implemented as a SwiftUI `Settings` scene in `ToolboxApp.swift`. Uses `SettingsView` with a `List` grouped by `Section` per tool. Reads stored keys via `KeychainHelper.allStoredKeys()`. Inline editing uses `SecureField` with save/cancel controls. Fixed window size of 500x350.
- **Key Capabilities**:
  - Standard macOS Cmd+, Settings access
  - All secrets listed in one centralized view, grouped by tool
  - Inline editing of secret values via SecureField
  - Delete individual secrets with a single click
  - Shows "Not set" indicator for unconfigured variables
  - Only shows tools that have environment variables defined
- **Tags**: settings, preferences, secrets, UI, macOS

### Streaming Terminal Output
- **Status**: Active
- **Added**: Initial release
- **Summary**: See your tool's output in real time with color-coded stdout and stderr streams.
- **Description**: When a tool runs, its output streams live into a terminal-like panel at the bottom of the detail view. Standard output and standard error are displayed with distinct styling so users can quickly distinguish normal output from errors. The panel includes a running indicator and shows the exit code when the process completes.
- **Technical Details**: `CommandRunner` uses `Pipe` for both stdout and stderr with `readabilityHandler` for async streaming. Output is dispatched to the main queue for UI updates via `ToolRunState` (an `@Observable` class). `OutputView` renders lines in a monospaced font.
- **Key Capabilities**:
  - Real-time streaming of stdout and stderr
  - Color-coded output (normal vs. error)
  - Exit code display on completion
  - Monospaced terminal-style rendering
- **Tags**: output, terminal, streaming, real-time

---

## Security & Secrets

### Secure Secret Storage (macOS Keychain)
- **Status**: Active
- **Added**: 2026-02-20
- **Summary**: API keys and sensitive values are stored securely in the macOS Keychain, never in plain text config files.
- **Description**: Toolbox uses the macOS Keychain to store environment variable values such as API keys, tokens, and other secrets. Values are never written to disk in plain text -- they are managed entirely through the system's native credential store. Each secret is stored under the "Toolbox" service with a composite account key of `toolName.varName` for unique identification.
- **Technical Details**: `KeychainHelper` is a static enum wrapping the macOS Security framework (`SecItemAdd`, `SecItemCopyMatching`, `SecItemDelete`). All items use `kSecClassGenericPassword` with `kSecAttrService` set to "Toolbox". The `allStoredKeys()` method queries all items for the service and parses the `tool.key` composite account string. Save operations delete-then-add to handle updates cleanly.
- **Key Capabilities**:
  - Secure storage using the native macOS Keychain
  - CRUD operations: save, read, delete, and list all stored secrets
  - Composite key scheme (`toolName.varName`) for per-tool secret isolation
  - No plain text secret storage anywhere in the app
- **Tags**: security, keychain, secrets, API-keys, macOS

### Environment Variable Configuration
- **Status**: Active
- **Added**: 2026-02-20
- **Summary**: Declare the API keys and environment variables your tool needs, and Toolbox handles secure storage and injection automatically.
- **Description**: Tools can declare required environment variables (such as API keys) in their JSON config via an `environment` array. When a tool has environment variables, an "Environment" section appears in the tool detail form with secure input fields for each variable. A green checkmark indicates when a value is stored. Values are loaded from Keychain on view appear and saved on submit. At runtime, all declared environment variables are automatically read from the Keychain and injected into the tool's process environment.
- **Technical Details**: The `environment` field is an optional array of `EnvironmentVar` structs (with `name` and `label` properties) on the `Tool` model. The `ToolDetailView` renders `SecureField` inputs within an "Environment" `GroupBox` and persists values via `KeychainHelper`. `CommandRunner.run()` iterates over `tool.environment`, reads each value from Keychain, and injects it into the process `environment` dictionary before launch.
- **Key Capabilities**:
  - Declarative environment variable definitions in tool JSON config
  - SecureField input with masked values in the UI
  - Visual confirmation (green checkmark) when a value is stored
  - Automatic Keychain persistence on submit
  - Automatic env var injection into tool subprocess at runtime
  - Values saved before each run to capture last-minute changes
- **Tags**: environment-variables, secrets, configuration, runtime, API-keys

---

## Execution Engine

### CLI Tool Execution with Process Management
- **Status**: Active
- **Added**: Initial release
- **Summary**: Run any command-line tool directly from the GUI with proper argument ordering, path expansion, and environment setup.
- **Description**: Toolbox launches CLI tools as native macOS processes with full control over argument construction, environment variables, and output streaming. Flags are placed before positional arguments in the command, directory and file paths undergo tilde expansion, and the PATH is augmented with common Homebrew locations so that tools installed via Homebrew are found automatically.
- **Technical Details**: `CommandRunner.run()` uses `Foundation.Process` with `Pipe` for stdout/stderr. Argument order: flags first (bool flags included only when enabled), then positional arguments in config order. Tilde expansion via `NSString.expandingTildeInPath` is applied only to `directory` and `file` type arguments. PATH is prepended with `/opt/homebrew/bin` and `/usr/local/bin`. A separate `runScript()` method supports running shell scripts via `/bin/bash`.
- **Key Capabilities**:
  - Native macOS Process execution
  - Correct flag-before-arguments ordering
  - Tilde expansion for filesystem path arguments only
  - Homebrew PATH augmentation for GUI app compatibility
  - Environment variable injection from Keychain
  - Separate shell script execution mode
- **Tags**: execution, process, CLI, runtime, PATH

---

## Tool Discovery & Creation

### AI-Powered Tool Creation
- **Status**: Active
- **Added**: Initial release
- **Summary**: Describe what you want in plain English, point to a folder, or paste a GitHub URL -- and AI generates the tool config for you.
- **Description**: Toolbox offers three ways to add tools, all powered by Claude AI. "Create with AI" generates a config from a natural language description. "Add from Folder" analyzes an existing script folder and generates a config pointing to the executable. "Add from GitHub" clones a repository to `~/.toolbox/scripts/` and generates a config from the cloned code. All three methods write the resulting JSON config to `~/.toolbox/tools/` where it is auto-discovered.
- **Technical Details**: All three modes invoke `create-tool.sh` with mode arguments (`create`, `folder`, `github`). The script calls `claude -p` with `--system-prompt` containing the full config schema and `--allowedTools Write,Read,Bash`. GitHub mode clones to `~/.toolbox/scripts/<repo-name>/` and uses `git pull` for re-adds.
- **Key Capabilities**:
  - Natural language tool creation via AI
  - Automatic folder analysis to detect executables and generate configs
  - GitHub repo cloning with automatic config generation
  - Re-adding a GitHub repo updates the existing clone instead of failing
  - Generated configs appear in the sidebar immediately via filesystem watching
- **Tags**: AI, tool-creation, GitHub, automation, Claude
