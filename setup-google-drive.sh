#!/bin/bash

# ============================================================
# Setup Google Drive Sync cho KDE Sticky Notes
# ============================================================
# Script này hướng dẫn cài đặt và cấu hình rclone để mount
# Google Drive vào hệ thống Linux.

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════╗"
echo "║  KDE Sticky Notes - Google Drive Setup                ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# ─── Bước 1: Kiểm tra rclone ───────────────────────────────
echo "📦 Checking if rclone is installed..."
if command -v rclone &> /dev/null; then
    echo "✅ rclone is already installed: $(rclone --version | head -n1)"
else
    echo "❌ rclone is not installed"
    echo ""
    echo "Please install rclone first:"
    echo "  • Ubuntu/Debian: sudo apt install rclone"
    echo "  • Fedora: sudo dnf install rclone"
    echo "  • Arch: sudo pacman -S rclone"
    echo "  • Or visit: https://rclone.org/install/"
    echo ""
    read -p "Press Enter to continue after installing rclone..."
fi

# ─── Bước 2: Cấu hình rclone với Google Drive ──────────────
echo ""
echo "🔧 Configuring rclone for Google Drive..."
echo ""
echo "If you haven't configured Google Drive yet, run:"
echo "  rclone config"
echo ""
echo "Follow these steps:"
echo "  1. Choose 'n' for new remote"
echo "  2. Name it 'gdrive' (or any name you like)"
echo "  3. Choose 'drive' for Google Drive"
echo "  4. Leave client_id and client_secret blank (press Enter)"
echo "  5. Choose '1' for full access"
echo "  6. Leave root_folder_id blank"
echo "  7. Leave service_account_file blank"
echo "  8. Choose 'n' for advanced config"
echo "  9. Choose 'y' to auto config (will open browser)"
echo "  10. Authenticate with your Google account"
echo "  11. Choose 'y' to confirm"
echo ""

# Kiểm tra xem đã có remote 'gdrive' chưa
if rclone listremotes | grep -q "gdrive:"; then
    echo "✅ Found existing 'gdrive' remote"
else
    echo "⚠️  No 'gdrive' remote found"
    read -p "Do you want to configure it now? (y/n): " configure_now
    if [ "$configure_now" = "y" ]; then
        rclone config
    fi
fi

# ─── Bước 3: Tạo thư mục mount point ───────────────────────
echo ""
echo "📁 Setting up mount point..."
MOUNT_POINT="$HOME/GoogleDrive"

if [ ! -d "$MOUNT_POINT" ]; then
    mkdir -p "$MOUNT_POINT"
    echo "✅ Created mount point: $MOUNT_POINT"
else
    echo "✅ Mount point already exists: $MOUNT_POINT"
fi

# Tạo thư mục StickyNotes trong Google Drive
STICKY_NOTES_DIR="$MOUNT_POINT/StickyNotes"
mkdir -p "$STICKY_NOTES_DIR"
echo "✅ Created StickyNotes directory: $STICKY_NOTES_DIR"

# ─── Bước 4: Mount Google Drive ────────────────────────────
echo ""
echo "🔗 Mounting Google Drive..."
echo ""

# Kiểm tra xem đã mount chưa
if mountpoint -q "$MOUNT_POINT"; then
    echo "✅ Google Drive is already mounted at $MOUNT_POINT"
else
    echo "Mounting Google Drive..."
    rclone mount gdrive: "$MOUNT_POINT" \
        --vfs-cache-mode writes \
        --daemon \
        --log-file="$HOME/.rclone-gdrive.log"
    
    sleep 2  # Đợi mount hoàn tất
    
    if mountpoint -q "$MOUNT_POINT"; then
        echo "✅ Successfully mounted Google Drive at $MOUNT_POINT"
    else
        echo "❌ Failed to mount Google Drive"
        echo "Check log file: $HOME/.rclone-gdrive.log"
        exit 1
    fi
fi

# ─── Bước 5: Tạo systemd service (auto-mount khi boot) ─────
echo ""
echo "⚙️  Setting up auto-mount on boot..."
echo ""

SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SYSTEMD_DIR/rclone-gdrive.service"

mkdir -p "$SYSTEMD_DIR"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=RClone mount for Google Drive
After=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount gdrive: $MOUNT_POINT \\
    --vfs-cache-mode writes \\
    --log-file=$HOME/.rclone-gdrive.log
ExecStop=/bin/fusermount -u $MOUNT_POINT
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

echo "✅ Created systemd service: $SERVICE_FILE"

# Enable và start service
systemctl --user daemon-reload
systemctl --user enable rclone-gdrive.service
systemctl --user start rclone-gdrive.service

echo "✅ Auto-mount enabled (will start on boot)"

# ─── Bước 6: Kiểm tra kết nối ──────────────────────────────
echo ""
echo "🧪 Testing connection..."
echo ""

if [ -d "$MOUNT_POINT" ] && [ "$(ls -A $MOUNT_POINT 2>/dev/null)" ]; then
    echo "✅ Google Drive is accessible!"
    echo ""
    echo "Files in your Google Drive:"
    ls -lh "$MOUNT_POINT" | head -n 10
else
    echo "⚠️  Google Drive appears to be empty or not accessible"
fi

# ─── Hoàn tất ──────────────────────────────────────────────
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  ✅ Setup Complete!                                    ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "📝 Next steps:"
echo "  1. Open KDE Sticky Notes widget"
echo "  2. Right-click → Configure"
echo "  3. Enable 'Google Drive Sync'"
echo "  4. Set path to: $STICKY_NOTES_DIR"
echo "  5. Click 'Apply'"
echo ""
echo "🔄 Your notes will now automatically sync to Google Drive!"
echo ""
echo "📌 Useful commands:"
echo "  • Check mount status: mountpoint $MOUNT_POINT"
echo "  • View logs: tail -f $HOME/.rclone-gdrive.log"
echo "  • Restart service: systemctl --user restart rclone-gdrive.service"
echo "  • Stop service: systemctl --user stop rclone-gdrive.service"
echo ""
