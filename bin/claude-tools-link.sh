#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_TOOLS_DIR="$(dirname "$SCRIPT_DIR")"
COMMANDS_SOURCE_DIR="$CLAUDE_TOOLS_DIR/commands"

# Get the current working directory (where the script is called from)
PROJECT_DIR="$(pwd)"
CLAUDE_DIR="$PROJECT_DIR/.claude"
COMMANDS_TARGET_DIR="$CLAUDE_DIR/commands"

echo "Initializing Claude project setup..."
echo "Source commands: $COMMANDS_SOURCE_DIR"
echo "Target location: $COMMANDS_TARGET_DIR"

# Create .claude directory if it doesn't exist
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Creating .claude directory..."
    mkdir -p "$CLAUDE_DIR"
fi

# Remove existing commands directory/symlink if it exists
if [ -e "$COMMANDS_TARGET_DIR" ]; then
    echo "Removing existing commands directory/symlink..."
    rm -rf "$COMMANDS_TARGET_DIR"
fi

# Create symlink to commands directory
if [ -d "$COMMANDS_SOURCE_DIR" ]; then
    echo "Creating symlink to commands directory..."
    ln -s "$COMMANDS_SOURCE_DIR" "$COMMANDS_TARGET_DIR"
    echo "✓ Commands symlinked successfully!"
    echo "Commands from claude-tools will now be available in this project"
    echo "New commands added to claude-tools will appear immediately"
else
    echo "Error: Commands directory not found at $COMMANDS_SOURCE_DIR"
    exit 1
fi