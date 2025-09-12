#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_TOOLS_DIR="$(dirname "$SCRIPT_DIR")"
CT_SOURCE_DIR="$CLAUDE_TOOLS_DIR/commands/ct"

# Get the current working directory (where the script is called from)
PROJECT_DIR="$(pwd)"
CLAUDE_DIR="$PROJECT_DIR/.claude"
CT_TARGET_DIR="$CLAUDE_DIR/ct"

echo "Initializing Claude project setup..."
echo "Source commands: $CT_SOURCE_DIR"
echo "Target location: $CT_TARGET_DIR"

# Create .claude directory if it doesn't exist
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Creating .claude directory..."
    mkdir -p "$CLAUDE_DIR"
fi

# Remove existing ct directory/symlink if it exists
if [ -e "$CT_TARGET_DIR" ]; then
    echo "Removing existing ct directory/symlink..."
    rm -rf "$CT_TARGET_DIR"
fi

# Create symlink to ct directory
if [ -d "$CT_SOURCE_DIR" ]; then
    echo "Creating symlink to ct directory..."
    ln -s "$CT_SOURCE_DIR" "$CT_TARGET_DIR"
    echo "✓ Claude Tools commands symlinked successfully!"
    echo "CT commands from claude-tools will now be available in this project"
    echo "New commands added to claude-tools will appear immediately"
else
    echo "Error: CT commands directory not found at $CT_SOURCE_DIR"
    exit 1
fi