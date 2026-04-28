# 🚀 Quick Start - Google Drive Sync

## Bắt đầu trong 5 phút!

### Bước 1: Cài đặt rclone (1 phút)
```bash
# Ubuntu/Debian
sudo apt install rclone

# Hoặc script chính thức
curl https://rclone.org/install.sh | sudo bash
```

### Bước 2: Chạy script tự động (2 phút)
```bash
./setup-google-drive.sh
```

Script sẽ:
- ✅ Hướng dẫn cấu hình Google Drive
- ✅ Mount Drive tại `~/GoogleDrive`
- ✅ Tạo thư mục `~/GoogleDrive/StickyNotes`
- ✅ Setup auto-mount khi boot

### Bước 3: Cài lại plasmoid (30 giây)
```bash
./dev-install.sh
```

### Bước 4: Bật sync trong Settings (1 phút)
1. Right-click widget → **Configure**
2. ✅ Bật **"Enable sync"**
3. Đường dẫn: `~/GoogleDrive/StickyNotes`
4. Click **Apply**
5. Click **Check** → phải thấy 🟢 xanh

### Bước 5: Test! (30 giây)
1. Tạo note mới
2. Đợi 1 giây
3. Kiểm tra file:
```bash
cat ~/GoogleDrive/StickyNotes/sticky-notes-data.json
```

**Thấy dữ liệu JSON → Thành công! 🎉**

---

## Troubleshooting nhanh

### ❌ "Google Drive path not found"
```bash
# Kiểm tra mount
mountpoint ~/GoogleDrive

# Nếu chưa mount:
rclone mount gdrive: ~/GoogleDrive --vfs-cache-mode writes --daemon
```

### ❌ "rclone: command not found"
```bash
# Cài rclone
sudo apt install rclone
```

### ❌ File không sync
```bash
# Kiểm tra logs
tail -f ~/.rclone-gdrive.log

# Sync thủ công
# Click nút ☁️ (cloud-upload) trên widget
```

---

## Xong! 🎊

Giờ notes của bạn sẽ:
- ✅ Tự động sync lên Drive sau mỗi thay đổi
- ✅ Không mất khi restart máy
- ✅ Có thể truy cập từ nhiều máy

**Đọc thêm**: `GOOGLE_DRIVE_SYNC_GUIDE.md` để biết chi tiết
