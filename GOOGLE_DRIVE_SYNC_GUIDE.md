# 🔄 Google Drive Sync - Hướng dẫn sử dụng

## Tổng quan

KDE Sticky Notes giờ đây hỗ trợ **đồng bộ tự động với Google Drive**, giúp bạn:
- ✅ Không mất dữ liệu khi restart máy
- ✅ Truy cập notes từ nhiều máy tính
- ✅ Backup tự động lên cloud
- ✅ Sync realtime khi có thay đổi (debounce 1 giây)

## Cách hoạt động

```
┌─────────────┐         ┌──────────────┐         ┌──────────────┐
│  KDE Sticky │ ──────> │ Local Config │         │ Google Drive │
│    Notes    │         │  (fallback)  │ <────>  │   (primary)  │
└─────────────┘         └──────────────┘         └──────────────┘
      │                                                   │
      └───────────────── Auto Sync (1s) ─────────────────┘
```

- **Khi khởi động**: Load từ Google Drive trước, fallback về local config nếu Drive không có
- **Khi thay đổi**: Lưu local ngay lập tức, sync lên Drive sau 1 giây (debounce)
- **Khi có conflict**: Last-write-wins (ghi đè mới nhất)

---

## 📦 Bước 1: Cài đặt rclone

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install rclone
```

### Fedora
```bash
sudo dnf install rclone
```

### Arch Linux
```bash
sudo pacman -S rclone
```

### Hoặc cài từ script chính thức
```bash
curl https://rclone.org/install.sh | sudo bash
```

---

## 🔧 Bước 2: Chạy script tự động setup

Chúng tôi đã chuẩn bị script tự động setup mọi thứ:

```bash
./setup-google-drive.sh
```

Script sẽ:
1. ✅ Kiểm tra rclone đã cài chưa
2. ✅ Hướng dẫn cấu hình Google Drive remote
3. ✅ Tạo mount point tại `~/GoogleDrive`
4. ✅ Mount Google Drive
5. ✅ Tạo systemd service để auto-mount khi boot
6. ✅ Tạo thư mục `~/GoogleDrive/StickyNotes`

---

## ⚙️ Bước 3: Cấu hình trong KDE Sticky Notes

1. **Mở widget** → Right-click → **Configure**
2. Trong tab **General**:
   - ✅ Bật **"Enable sync: Automatically sync notes to Google Drive"**
   - 📁 Đặt **Drive path**: `~/GoogleDrive/StickyNotes`
   - 📄 Đặt **File name**: `sticky-notes-data.json` (hoặc tên bạn thích)
3. Click **Apply**
4. Click nút **"Check"** để kiểm tra kết nối
   - 🟢 Xanh = OK
   - 🔴 Đỏ = Có vấn đề

---

## 🎯 Cách sử dụng

### Sync tự động (mặc định)
- Mọi thay đổi (tạo/sửa/xóa note/todo) sẽ **tự động sync** sau 1 giây
- Không cần làm gì cả!

### Sync thủ công
Nếu muốn sync ngay lập tức:
1. Click nút **☁️ (cloud-upload)** trên toolbar
2. Thông báo "Synced to Google Drive!" sẽ hiện ra

### Tải lại từ Drive
Nếu muốn tải lại dữ liệu từ Drive (ví dụ: sau khi sửa trên máy khác):
1. Click nút **☁️ (cloud-download)** trên toolbar
2. Tất cả notes sẽ được thay thế bằng dữ liệu từ Drive

---

## 🔍 Kiểm tra trạng thái

### Kiểm tra Google Drive đã mount chưa
```bash
mountpoint ~/GoogleDrive
```
- Kết quả: `~/GoogleDrive is a mountpoint` → OK ✅
- Kết quả: `~/GoogleDrive is not a mountpoint` → Chưa mount ❌

### Xem file sync
```bash
cat ~/GoogleDrive/StickyNotes/sticky-notes-data.json
```

### Xem logs rclone
```bash
tail -f ~/.rclone-gdrive.log
```

---

## 🛠️ Troubleshooting

### ❌ Lỗi: "Google Drive path not found"

**Nguyên nhân**: Google Drive chưa được mount

**Giải pháp**:
```bash
# Kiểm tra rclone remote
rclone listremotes

# Nếu không có 'gdrive:', cấu hình lại
rclone config

# Mount thủ công
rclone mount gdrive: ~/GoogleDrive --vfs-cache-mode writes --daemon
```

### ❌ Lỗi: "Failed to sync to Google Drive"

**Nguyên nhân**: Không có quyền ghi vào thư mục

**Giải pháp**:
```bash
# Tạo thư mục nếu chưa có
mkdir -p ~/GoogleDrive/StickyNotes

# Kiểm tra quyền
ls -la ~/GoogleDrive/StickyNotes
```

### ❌ Lỗi: Mount bị mất sau khi restart

**Nguyên nhân**: Systemd service chưa được enable

**Giải pháp**:
```bash
# Enable service
systemctl --user enable rclone-gdrive.service

# Start service
systemctl --user start rclone-gdrive.service

# Kiểm tra status
systemctl --user status rclone-gdrive.service
```

### ❌ Lỗi: Sync chậm hoặc không sync

**Nguyên nhân**: Debounce timer chưa hết

**Giải pháp**:
- Đợi 1 giây sau thao tác cuối
- Hoặc click nút sync thủ công (☁️)

---

## 🔐 Bảo mật

### Dữ liệu được lưu ở đâu?

1. **Local**: `~/.config/plasma-org.kde.plasma.desktop-appletsrc` (KDE config)
2. **Google Drive**: `~/GoogleDrive/StickyNotes/sticky-notes-data.json`

### Dữ liệu có được mã hóa không?

- ❌ Không mã hóa trong file JSON (plain text)
- ✅ Google Drive tự động mã hóa khi lưu trữ (encryption at rest)
- ✅ Kết nối rclone dùng HTTPS (encryption in transit)

### Khuyến nghị bảo mật

- 🔒 Không lưu thông tin nhạy cảm (mật khẩu, số thẻ) trong notes
- 🔒 Bật 2FA cho Google account
- 🔒 Giới hạn quyền truy cập thư mục Google Drive

---

## 📊 So sánh với Google Keep

| Tính năng | KDE Sticky Notes | Google Keep |
|-----------|------------------|-------------|
| Sync tự động | ✅ (1s debounce) | ✅ (realtime) |
| Offline mode | ✅ | ✅ |
| Desktop widget | ✅ | ❌ |
| Mobile app | ❌ | ✅ |
| Drag & drop | ✅ | ❌ |
| Deadline tracking | ✅ | ⚠️ (reminders only) |
| Open source | ✅ | ❌ |
| Privacy | ✅ (self-hosted) | ⚠️ (Google servers) |

---

## 🚀 Nâng cao

### Sync nhiều máy tính

1. Cài đặt rclone trên tất cả máy
2. Cấu hình cùng Google account
3. Dùng cùng đường dẫn `~/GoogleDrive/StickyNotes`
4. Mỗi máy sẽ tự động sync với nhau

### Backup thủ công

```bash
# Backup file JSON
cp ~/GoogleDrive/StickyNotes/sticky-notes-data.json \
   ~/GoogleDrive/StickyNotes/backup-$(date +%Y%m%d).json

# Hoặc dùng rclone copy
rclone copy ~/GoogleDrive/StickyNotes gdrive:StickyNotes-Backup
```

### Thay đổi thư mục sync

1. Right-click widget → Configure
2. Đổi **Drive path** thành đường dẫn mới
3. Click Apply
4. Click nút sync để upload dữ liệu lên thư mục mới

---

## 📝 Lưu ý quan trọng

⚠️ **Conflict resolution**: Nếu sửa notes trên 2 máy cùng lúc, máy sync sau sẽ **ghi đè** máy sync trước (last-write-wins). Để tránh mất dữ liệu:
- Chỉ sửa trên 1 máy tại 1 thời điểm
- Hoặc click nút "Load from Drive" trước khi sửa

⚠️ **Giới hạn kích thước**: Google Drive free có giới hạn 15GB. File JSON thường rất nhỏ (<1MB cho hàng nghìn notes), nên không lo hết dung lượng.

⚠️ **Tốc độ sync**: Phụ thuộc vào tốc độ internet. Với file <1MB, sync thường mất <1 giây.

---

## 🆘 Hỗ trợ

Nếu gặp vấn đề:
1. Kiểm tra logs: `tail -f ~/.rclone-gdrive.log`
2. Kiểm tra plasmoid logs: `journalctl --user -f | grep sticky`
3. Mở issue trên GitHub (nếu có)

---

## 📚 Tài liệu tham khảo

- [rclone Documentation](https://rclone.org/docs/)
- [rclone Google Drive Setup](https://rclone.org/drive/)
- [KDE Plasmoid Development](https://develop.kde.org/docs/plasma/)

---

**Chúc bạn sử dụng vui vẻ! 🎉**
