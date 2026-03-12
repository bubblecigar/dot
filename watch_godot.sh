#!/bin/bash
# Godot auto-restart on file changes (macOS/Linux)
# Requires: fswatch (brew install fswatch)

PROJECT_PATH="$(dirname "$0")"
GODOT_CMD="godot"

# Only restart Godot after it exits, and allow clean Ctrl+C termination
echo "Watching for changes... (Press Ctrl+C to stop)"

while true; do
    fswatch -1 "$PROJECT_PATH/client" "$PROJECT_PATH/shared" "$PROJECT_PATH/server"
    echo "Change detected. Restarting Godot..."
    "$GODOT_CMD"
done
