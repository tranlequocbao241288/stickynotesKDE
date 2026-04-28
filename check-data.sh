#!/bin/bash

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Check Notes Data Location                             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 1. Check local config
echo "1️⃣  Local Config (KDE Plasma):"
echo "─────────────────────────────────────────────────────"
CONFIG_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

if [ -f "$CONFIG_FILE" ]; then
    echo "✅ File exists: $CONFIG_FILE"
    
    # Extract notesData
    NOTES_DATA=$(grep "notesData=" "$CONFIG_FILE" | sed 's/notesData=//')
    
    if [ -n "$NOTES_DATA" ]; then
        echo "✅ Notes data found"
        echo "📊 Data length: ${#NOTES_DATA} characters"
        
        # Try to parse JSON and count notes
        if command -v python3 &> /dev/null; then
            NOTE_COUNT=$(echo "$NOTES_DATA" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(f'📝 Notes count: {len(data)}')
    for i, note in enumerate(data):
        items_count = len(note.get('items', []))
        print(f'   Note {i+1}: \"{note.get(\"title\", \"Untitled\")}\" - {items_count} todos')
except:
    print('❌ Invalid JSON')
" 2>/dev/null)
            echo "$NOTE_COUNT"
        fi
    else
        echo "❌ No notes data found"
    fi
else
    echo "❌ Config file not found"
fi

echo ""

# 2. Check Google Drive
echo "2️⃣  Google Drive:"
echo "─────────────────────────────────────────────────────"
DRIVE_FILE="$HOME/GoogleDrive/StickyNotes/sticky-notes-data.json"

if [ -f "$DRIVE_FILE" ]; then
    echo "✅ File exists: $DRIVE_FILE"
    echo "📊 File size: $(stat -c%s "$DRIVE_FILE") bytes"
    
    if command -v python3 &> /dev/null; then
        python3 -c "
import json
try:
    with open('$DRIVE_FILE', 'r') as f:
        data = json.load(f)
    print(f'📝 Notes count: {len(data)}')
    for i, note in enumerate(data):
        items_count = len(note.get('items', []))
        print(f'   Note {i+1}: \"{note.get(\"title\", \"Untitled\")}\" - {items_count} todos')
except Exception as e:
    print(f'❌ Error reading file: {e}')
" 2>/dev/null
    fi
else
    echo "❌ Google Drive file not found"
    echo "   Expected: $DRIVE_FILE"
    
    # Check if Google Drive is mounted
    if mountpoint -q "$HOME/GoogleDrive" 2>/dev/null; then
        echo "✅ Google Drive is mounted"
    else
        echo "❌ Google Drive is not mounted"
    fi
fi

echo ""

# 3. Summary
echo "3️⃣  Summary:"
echo "─────────────────────────────────────────────────────"
if [ -f "$CONFIG_FILE" ] && grep -q "notesData=" "$CONFIG_FILE"; then
    echo "✅ Local storage: ACTIVE"
else
    echo "❌ Local storage: INACTIVE"
fi

if [ -f "$DRIVE_FILE" ]; then
    echo "✅ Google Drive sync: ACTIVE"
else
    echo "❌ Google Drive sync: INACTIVE"
fi

echo ""
echo "💡 Tips:"
echo "   • View local data: cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc | grep notesData"
echo "   • View Drive data: cat ~/GoogleDrive/StickyNotes/sticky-notes-data.json"
echo "   • Pretty print: ... | python3 -m json.tool"