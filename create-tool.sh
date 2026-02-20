#!/bin/bash
# Creates a Toolbox tool config via Claude Code CLI
# Usage: ./create-tool.sh <mode> <arg>
#   Modes:
#     create <description>    — Generate config from natural language description
#     folder <path>           — Analyze an existing folder/script and generate config
#     github <repo-url>       — Clone a GitHub repo and generate config

MODE="$1"
ARG="$2"
TOOLS_DIR="$HOME/.toolbox/tools"
SCRIPTS_DIR="$HOME/.toolbox/scripts"

if [ -z "$MODE" ] || [ -z "$ARG" ]; then
    echo "Usage: create-tool.sh <mode> <arg>"
    echo "  Modes: create, folder, github, continue"
    exit 1
fi

SYSTEM_PROMPT='You are a Toolbox config generator. Toolbox is a macOS app that wraps CLI tools with a GUI.
Your job: analyze the given tool/script and create ONLY the JSON config file at ~/.toolbox/tools/<tool-name>.json.

CONFIG SCHEMA:
{
  "name": "Display Name",
  "icon": "sf.symbol.name",
  "description": "Short description",
  "command": "/absolute/path/to/executable",
  "arguments": [
    {
      "name": "arg_name",
      "label": "Human Label",
      "type": "string | directory | file | bool",
      "required": true,
      "placeholder": "hint text...",
      "default": "optional default"
    }
  ],
  "flags": [
    {
      "name": "flag_name",
      "flag": "-f",
      "label": "Human Label",
      "type": "bool",
      "default": false
    }
  ]
}

RULES:
- Use the Write tool to write the JSON file to ~/.toolbox/tools/<tool-name>.json
- "command" MUST be an absolute path. Use the Bash tool with "which" or "find" to locate the executable if needed.
- Use "type": "string" for URLs, text, etc. Use "directory"/"file" only for filesystem paths.
- Pick an appropriate SF Symbol for "icon" (e.g. arrow.down.circle, doc.text, terminal, network, photo, music.note, video, gear, hammer)
- "arguments" are positional — order matters, they are passed to the command in array order
- "flags" are passed before arguments. Bool flags are included when toggled on, omitted when off.
- If the user mentions a script, use the Bash tool to read it and understand its usage before generating the config.
- Keep it minimal — only include arguments and flags the tool actually uses.
- Print a short summary of what you created when done.'

case "$MODE" in
    create)
        printf '%s' "$ARG" | /opt/homebrew/bin/claude -p \
            --system-prompt "$SYSTEM_PROMPT" \
            --allowedTools "Write,Read,Bash" \
            --add-dir "$HOME/.toolbox"
        ;;
    folder)
        if [ ! -d "$ARG" ]; then
            echo "Error: '$ARG' is not a directory"
            exit 1
        fi
        FOLDER_PATH="$(cd "$ARG" && pwd)"
        printf '%s' "Analyze the tool/scripts in this folder: $FOLDER_PATH — find the main executable, understand its usage, and generate a Toolbox config. The command in the config should point to the script in its original location." | /opt/homebrew/bin/claude -p \
            --system-prompt "$SYSTEM_PROMPT" \
            --allowedTools "Write,Read,Bash" \
            --add-dir "$HOME/.toolbox" \
            --add-dir "$FOLDER_PATH"
        ;;
    github)
        REPO_URL="$ARG"
        # Extract repo name from URL (last path component, strip .git)
        REPO_NAME=$(basename "$REPO_URL" .git)
        CLONE_DIR="$SCRIPTS_DIR/$REPO_NAME"

        # Ensure scripts directory exists
        mkdir -p "$SCRIPTS_DIR"

        if [ -d "$CLONE_DIR/.git" ]; then
            echo "Repository already exists at $CLONE_DIR — pulling latest changes..."
            git -C "$CLONE_DIR" pull
        else
            echo "Cloning $REPO_URL into $CLONE_DIR..."
            git clone "$REPO_URL" "$CLONE_DIR"
        fi

        if [ $? -ne 0 ]; then
            echo "Error: git operation failed"
            exit 1
        fi

        # Make scripts executable
        find "$CLONE_DIR" -name "*.sh" -exec chmod +x {} \;

        printf '%s' "Analyze the cloned repository at $CLONE_DIR — find the main executable or script, chmod +x if needed, understand its usage, and generate a Toolbox config. The command in the config must point into the clone directory at $CLONE_DIR." | /opt/homebrew/bin/claude -p \
            --system-prompt "$SYSTEM_PROMPT" \
            --allowedTools "Write,Read,Bash" \
            --add-dir "$HOME/.toolbox" \
            --add-dir "$CLONE_DIR"
        ;;
    continue)
        printf '%s' "$ARG" | /opt/homebrew/bin/claude -p -c \
            --allowedTools "Write,Read,Bash" \
            --add-dir "$HOME/.toolbox"
        ;;
    *)
        echo "Error: Unknown mode '$MODE'. Use: create, folder, github, continue"
        exit 1
        ;;
esac
