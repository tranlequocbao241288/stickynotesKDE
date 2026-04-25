#!/bin/bash
# ─────────────────────────────────────────────────────────
# dev-install.sh — Script cập nhật plasmoid nhanh khi phát triển
#
# Cách dùng: ./dev-install.sh
#
# Script này sẽ:
# 1. Gỡ bản cài cũ
# 2. Cài lại từ source code mới nhất
# 3. (Tùy chọn) Restart plasmashell để thấy thay đổi
#
# LƯU Ý: Sau khi chạy, bạn cần thêm lại widget vào desktop
#         nếu đã restart plasmashell
# ─────────────────────────────────────────────────────────

PACKAGE_DIR="$(cd "$(dirname "$0")/package" && pwd)"
PLUGIN_ID="com.tranbao.stickynotes"

echo "🔄 Updating plasmoid from: $PACKAGE_DIR"
echo ""

# Gỡ bản cũ (bỏ qua lỗi nếu chưa cài)
echo "1️⃣  Removing old version..."
kpackagetool6 -t Plasma/Applet -r "$PLUGIN_ID" 2>/dev/null

# Cài bản mới
echo "2️⃣  Installing new version..."
kpackagetool6 -t Plasma/Applet -i "$PACKAGE_DIR"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Plasmoid installed successfully!"
    echo ""
    echo "📌 To see changes, you can either:"
    echo "   a) Remove and re-add the widget on desktop"
    echo "   b) Run: kquitapp6 plasmashell && kstart plasmashell"
    echo "      (This will restart the desktop shell)"
    echo ""
    
    # Hỏi có muốn restart plasmashell không
    read -p "🔄 Restart plasmashell now? (y/N): " answer
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        echo "Restarting plasmashell..."
        kquitapp6 plasmashell && kstart plasmashell &
        echo "Done! Wait a few seconds for desktop to reload."
    fi
else
    echo ""
    echo "❌ Installation failed!"
    echo "   Check if package/ directory structure is correct."
fi
