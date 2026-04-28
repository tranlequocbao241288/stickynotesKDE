#!/bin/bash

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Force Reinstall - Clear Cache                         ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PLUGIN_ID="com.tranbao.stickynotes"

echo "1️⃣  Removing old installation..."
kpackagetool6 -t Plasma/Applet -r "$PLUGIN_ID" 2>/dev/null

echo ""
echo "2️⃣  Clearing cache..."
rm -rf ~/.cache/plasmashell/qmlcache/*stickynotes* 2>/dev/null
rm -rf ~/.cache/plasma* 2>/dev/null

echo ""
echo "3️⃣  Installing fresh..."
./dev-install.sh --skip-gdrive

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  ✅ Done! Now add widget to desktop                    ║"
echo "╚════════════════════════════════════════════════════════╝"
