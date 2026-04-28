#!/bin/bash

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Debug Storage - KDE Sticky Notes                      ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 1. Cài lại plasmoid với debug logging
echo "1️⃣  Reinstalling plasmoid with debug logging..."
./dev-install.sh --skip-gdrive

echo ""
echo "2️⃣  Plasmoid installed. Now:"
echo "   a) Add widget to desktop"
echo "   b) Create a note with title 'Test'"
echo "   c) Add 2 todos"
echo ""
read -p "Press Enter when done..."

echo ""
echo "3️⃣  Checking logs for SAVE operation..."
echo "─────────────────────────────────────────────────────"
journalctl --user --since "2 minutes ago" | grep -E "logic.js.*Saving|logic.js.*Saved|logic.js.*items:" | tail -20

echo ""
echo "4️⃣  Now restart plasmoid (remove + add widget)"
echo ""
read -p "Press Enter when done..."

echo ""
echo "5️⃣  Checking logs for LOAD operation..."
echo "─────────────────────────────────────────────────────"
journalctl --user --since "1 minute ago" | grep -E "logic.js.*Loading|logic.js.*Loaded|logic.js.*Parsed|logic.js.*items:" | tail -20

echo ""
echo "6️⃣  Checking config file directly..."
echo "─────────────────────────────────────────────────────"
CONFIG_FILE=$(find ~/.config -name "*plasma*appletsrc" 2>/dev/null | head -1)
if [ -f "$CONFIG_FILE" ]; then
    echo "Config file: $CONFIG_FILE"
    echo ""
    echo "Searching for notesData..."
    grep -A 5 "notesData" "$CONFIG_FILE" | head -20
else
    echo "Config file not found!"
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Debug Complete                                        ║"
echo "╚════════════════════════════════════════════════════════╝"
