#!/bin/bash
# ─────────────────────────────────────────────────────────
# dev-install.sh — Script cập nhật plasmoid nhanh khi phát triển
#
# Cách dùng: ./dev-install.sh [--skip-gdrive]
#
# Script này sẽ:
# 0. (Tùy chọn) Setup Google Drive sync
# 1. Gỡ bản cài cũ
# 2. Cài lại từ source code mới nhất
# 3. (Tùy chọn) Restart plasmashell để thấy thay đổi
#
# Options:
#   --skip-gdrive    Bỏ qua setup Google Drive (nếu đã setup rồi)
#
# LƯU Ý: Sau khi chạy, bạn cần thêm lại widget vào desktop
#         nếu đã restart plasmashell
# ─────────────────────────────────────────────────────────

PACKAGE_DIR="$(cd "$(dirname "$0")/package" && pwd)"
PLUGIN_ID="com.tranbao.stickynotes"
SKIP_GDRIVE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --skip-gdrive)
            SKIP_GDRIVE=true
            shift
            ;;
    esac
done

echo "╔════════════════════════════════════════════════════════╗"
echo "║  KDE Sticky Notes - Development Install               ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# ─── Bước 0: Chọn phương thức lưu trữ ──────────────────────
if [ "$SKIP_GDRIVE" = false ]; then
    echo "📦 Step 0: Storage Configuration"
    echo "─────────────────────────────────────────────────────"
    echo ""
    echo "Chọn phương thức lưu trữ dữ liệu notes:"
    echo ""
    echo "  1️⃣  Local JSON File"
    echo "     • Lưu trữ local trên máy"
    echo "     • Không cần internet"
    echo "     • Đơn giản, nhanh"
    echo "     ⚠️  Mất dữ liệu khi format/reinstall OS"
    echo ""
    echo "  2️⃣  Google Drive Sync"
    echo "     • Tự động sync lên cloud"
    echo "     • Không mất dữ liệu khi restart"
    echo "     • Sync giữa nhiều máy"
    echo "     • Backup tự động"
    echo "     ⚠️  Cần internet và Google account"
    echo ""
    read -p "👉 Chọn phương thức (1 hoặc 2, mặc định 1): " storage_choice
    
    # Default to 1 if empty
    if [ -z "$storage_choice" ]; then
        storage_choice="1"
    fi
    
    case $storage_choice in
        1)
            echo ""
            echo "✅ Đã chọn: Local JSON File"
            echo ""
            echo "📝 Dữ liệu sẽ được lưu tại:"
            echo "   ~/.config/plasma-org.kde.plasma.desktop-appletsrc"
            echo ""
            echo "💡 Lưu ý:"
            echo "   • Dữ liệu chỉ tồn tại trên máy này"
            echo "   • Nên backup thường xuyên nếu dữ liệu quan trọng"
            echo "   • Có thể chuyển sang Google Drive sau bằng cách:"
            echo "     ./setup-google-drive.sh"
            echo ""
            ENABLE_GDRIVE_SYNC=false
            ;;
        2)
            echo ""
            echo "✅ Đã chọn: Google Drive Sync"
            echo ""
            
            if [ -f "./setup-google-drive.sh" ]; then
                echo "Running setup-google-drive.sh..."
                echo ""
                bash ./setup-google-drive.sh
                
                if [ $? -eq 0 ]; then
                    echo ""
                    echo "✅ Google Drive setup completed!"
                    ENABLE_GDRIVE_SYNC=true
                else
                    echo ""
                    echo "❌ Google Drive setup failed!"
                    echo ""
                    read -p "Fallback về Local JSON? (Y/n): " fallback
                    if [ "$fallback" != "n" ] && [ "$fallback" != "N" ]; then
                        echo "✅ Sẽ dùng Local JSON thay thế"
                        ENABLE_GDRIVE_SYNC=false
                    else
                        echo "❌ Hủy cài đặt"
                        exit 1
                    fi
                fi
            else
                echo ""
                echo "❌ setup-google-drive.sh not found!"
                echo "   Fallback về Local JSON"
                ENABLE_GDRIVE_SYNC=false
            fi
            ;;
        *)
            echo ""
            echo "❌ Lựa chọn không hợp lệ! Dùng mặc định: Local JSON"
            ENABLE_GDRIVE_SYNC=false
            ;;
    esac
    
    echo ""
    echo "─────────────────────────────────────────────────────"
    echo ""
else
    echo "⏭️  Skipping storage configuration (--skip-gdrive flag)"
    echo ""
    ENABLE_GDRIVE_SYNC=false
fi

# ─── Bước 1-3: Cài đặt plasmoid ─────────────────────────────
echo "🔄 Installing plasmoid from: $PACKAGE_DIR"
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
    
    # Hiển thị hướng dẫn theo phương thức lưu trữ đã chọn
    if [ "$ENABLE_GDRIVE_SYNC" = true ]; then
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║  📝 Next Steps: Enable Google Drive Sync              ║"
        echo "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "1. Add widget to desktop (right-click desktop → Add Widget)"
        echo "2. Right-click widget → Configure"
        echo "3. ✅ Enable 'Automatically sync notes to Google Drive'"
        echo "4. Set path: ~/GoogleDrive/StickyNotes"
        echo "5. Click Apply"
        echo ""
        echo "🎉 Done! Your notes will sync automatically to Google Drive!"
        echo ""
    else
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║  📝 Next Steps: Start Using Local Storage             ║"
        echo "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "1. Add widget to desktop (right-click desktop → Add Widget)"
        echo "2. Start creating notes!"
        echo ""
        echo "📁 Data location:"
        echo "   ~/.config/plasma-org.kde.plasma.desktop-appletsrc"
        echo ""
        echo "💡 Tip: Muốn chuyển sang Google Drive sau?"
        echo "   1. Run: ./setup-google-drive.sh"
        echo "   2. Right-click widget → Configure"
        echo "   3. Enable Google Drive Sync"
        echo ""
    fi
    
    echo "─────────────────────────────────────────────────────"
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
