#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_NAME="com.stevenavery.journal_sync.plist"
PLIST_PATH="$SCRIPT_DIR/$PLIST_NAME"
WFLOW_PATH="$SCRIPT_DIR/script-wrapper.app/Contents/document.wflow"
CONFIG_PATH="$SCRIPT_DIR/config.txt"
LAUNCHAGENTS_DIR="$HOME/Library/LaunchAgents"

echo "Journal Sync Installer"
echo "======================"
echo ""

# Check for Homebrew rsync
echo "Checking for Homebrew rsync..."
if [ -x "/opt/homebrew/bin/rsync" ]; then
    echo "  ✓ Homebrew rsync found"
elif command -v brew &> /dev/null; then
    echo "  Homebrew rsync not found. Installing..."
    brew install rsync
    echo "  ✓ Homebrew rsync installed"
else
    echo "  ✗ Homebrew not found. Please install Homebrew first:"
    echo "    https://brew.sh"
    exit 1
fi

# Update paths in plist
echo ""
echo "Updating plist WorkingDirectory..."
sed -i '' "s|<string>/Users/[^<]*/dev/[^<]*</string>|<string>$SCRIPT_DIR</string>|" "$PLIST_PATH"
# More precise replacement for WorkingDirectory
sed -i '' "/<key>WorkingDirectory<\/key>/{ n; s|<string>[^<]*</string>|<string>$SCRIPT_DIR</string>|; }" "$PLIST_PATH"
echo "  ✓ Updated to: $SCRIPT_DIR"

# Update paths in Automator workflow
echo ""
echo "Updating Automator workflow path..."
sed -i '' "s|cd ~/dev/[^;]*/|cd $SCRIPT_DIR/|g" "$WFLOW_PATH"
echo "  ✓ Updated to: $SCRIPT_DIR"

# Configure NAS settings
echo ""
echo "NAS Configuration"
echo "-----------------"

# Copy example config if no config exists
if [ ! -f "$CONFIG_PATH" ] && [ -f "$CONFIG_PATH.example" ]; then
    cp "$CONFIG_PATH.example" "$CONFIG_PATH"
fi

# Load existing config if present
if [ -f "$CONFIG_PATH" ]; then
    source "$CONFIG_PATH"
fi

read -p "NAS hostname [$host]: " input_host
host="${input_host:-$host}"

read -p "NAS username [$user]: " input_user
user="${input_user:-$user}"

read -p "Local directory [$localdir]: " input_localdir
localdir="${input_localdir:-$localdir}"

read -p "Remote directory [$remotedir]: " input_remotedir
remotedir="${input_remotedir:-$remotedir}"

# Write config
cat > "$CONFIG_PATH" << EOF
# Admin user on the NAS. Make sure rsync service is enabled
user=$user
host=$host

localdir='$localdir'
# Must be full path, and must exist before running
remotedir='$remotedir'
EOF

echo ""
echo "  ✓ Config saved"

# Install LaunchAgent
echo ""
echo "Installing LaunchAgent..."
mkdir -p "$LAUNCHAGENTS_DIR"

# Unload if already loaded
if launchctl list | grep -q "$PLIST_NAME" 2>/dev/null; then
    launchctl unload "$LAUNCHAGENTS_DIR/$PLIST_NAME" 2>/dev/null || true
fi

cp "$PLIST_PATH" "$LAUNCHAGENTS_DIR/"
launchctl load "$LAUNCHAGENTS_DIR/$PLIST_NAME"
echo "  ✓ LaunchAgent installed and loaded"

echo ""
echo "Installation complete!"
echo ""
echo "The sync will run daily at 3:00 AM."
echo "To run manually:  $SCRIPT_DIR/sync.sh"
echo "To test:          $SCRIPT_DIR/sync.sh --dry-run"
