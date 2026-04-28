#!/bin/bash
echo "Checking plasmoid logs..."
echo ""
echo "=== Recent logs ==="
journalctl --user --since "5 minutes ago" | grep -i "sticky\|logic.js" | tail -20
echo ""
echo "=== Check if data is being saved ==="
journalctl --user --since "5 minutes ago" | grep -i "saved.*notes"
echo ""
echo "=== Check if data is being loaded ==="
journalctl --user --since "5 minutes ago" | grep -i "loaded.*notes"
