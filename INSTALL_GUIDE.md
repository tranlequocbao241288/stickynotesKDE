# 📦 Hướng dẫn cài đặt KDE Sticky Notes

## 🚀 Cài đặt nhanh (All-in-One)

### Chỉ cần 1 lệnh duy nhất:

```bash
./dev-install.sh
```

Script sẽ hỏi bạn chọn **phương thức lưu trữ**:

### 1️⃣ **Local JSON File**
- ✅ Lưu trữ local trên máy
- ✅ Không cần internet
- ✅ Đơn giản, nhanh
- ⚠️ Mất dữ liệu khi format/reinstall OS

### 2️⃣ **Google Drive Sync**
- ✅ Tự động sync lên cloud
- ✅ Không mất dữ liệu khi restart
- ✅ Sync giữa nhiều máy
- ✅ Backup tự động
- ⚠️ Cần internet và Google account

**Thời gian**: 
- Local: ~1 phút
- Google Drive: ~5-10 phút (bao gồm authenticate)

---

## 📋 Chi tiết từng bước

### Bước 1: Chạy script cài đặt

```bash
./dev-install.sh
```

### Bước 2: Chọn phương thức lưu trữ

Script sẽ hỏi:

```
👉 Chọn phương thức (1 hoặc 2, mặc định 1):
```

#### Chọn 1: Local JSON File
- Dữ liệu lưu tại: `~/.config/plasma-org.kde.plasma.desktop-appletsrc`
- Không cần setup thêm
- Bỏ qua bước Google Drive

#### Chọn 2: Google Drive Sync
Script sẽ tự động:
1. Kiểm tra rclone
2. Hướng dẫn cấu hình Google Drive
3. Mount Drive tại `~/GoogleDrive`
4. Tạo systemd service auto-mount

Nếu setup Google Drive thất bại:
- Script sẽ hỏi fallback về Local JSON
- Hoặc hủy cài đặt

### Bước 3: Restart plasmashell (tùy chọn)

```
🔄 Restart plasmashell now? (y/N):
```

- **Nhấn y**: Restart desktop shell ngay (khuyến nghị)
- **Nhấn N** (hoặc Enter): Không restart, tự restart sau

### Bước 4: Thêm widget vào desktop

1. Right-click desktop → **Add Widget**
2. Tìm **"Sticky Notes"**
3. Kéo vào desktop

### Bước 5: Cấu hình (nếu chọn Google Drive)

1. Right-click widget → **Configure**
2. ✅ Bật **"Enable sync: Automatically sync notes to Google Drive"**
3. Đường dẫn: `~/GoogleDrive/StickyNotes` (đã điền sẵn)
4. Click **Apply**
5. Click **Check** → phải thấy 🟢 xanh

### Bước 6: Xong! 🎉

Bây giờ bạn có thể:
- ✅ Tạo notes
- ✅ Tự động lưu (local hoặc Drive)
- ✅ Không lo mất dữ liệu (nếu dùng Drive)

---

## 🔄 Chuyển đổi giữa Local và Google Drive

### Từ Local → Google Drive

1. Chạy setup Google Drive:
```bash
./setup-google-drive.sh
```

2. Bật sync trong Settings:
   - Right-click widget → Configure
   - ✅ Enable Google Drive Sync
   - Click Apply

3. Click nút ☁️ (upload) để sync dữ liệu hiện tại lên Drive

### Từ Google Drive → Local

1. Tắt sync trong Settings:
   - Right-click widget → Configure
   - ❌ Disable Google Drive Sync
   - Click Apply

2. Dữ liệu vẫn được lưu local, chỉ không sync lên Drive nữa

---

## ⚙️ Options nâng cao

### Bỏ qua setup Google Drive

Nếu đã setup Google Drive rồi, chỉ muốn cài lại plasmoid:

```bash
./dev-install.sh --skip-gdrive
```

### Setup Google Drive riêng

Nếu muốn setup Google Drive sau:

```bash
./setup-google-drive.sh
```

---

## 🔄 Cập nhật plasmoid

Khi có code mới, chỉ cần chạy lại:

```bash
./dev-install.sh --skip-gdrive
```

(Dùng `--skip-gdrive` vì đã setup rồi, không cần setup lại)

---

## 🐛 Troubleshooting

### ❌ "kpackagetool6: command not found"

**Nguyên nhân**: Chưa cài KDE Plasma 6

**Giải pháp**: Cài KDE Plasma 6 hoặc dùng `kpackagetool5` cho Plasma 5

### ❌ "rclone: command not found"

**Nguyên nhân**: Chưa cài rclone

**Giải pháp**:
```bash
sudo apt install rclone  # Ubuntu/Debian
# hoặc
sudo dnf install rclone  # Fedora
```

### ❌ Google Drive không mount

**Nguyên nhân**: Chưa cấu hình rclone đúng

**Giải pháp**:
```bash
# Cấu hình lại
rclone config

# Mount thủ công
rclone mount gdrive: ~/GoogleDrive --vfs-cache-mode writes --daemon
```

### ❌ Widget không hiển thị sau khi cài

**Nguyên nhân**: Plasmashell chưa restart

**Giải pháp**:
```bash
kquitapp6 plasmashell && kstart plasmashell
```

---

## 📚 Tài liệu thêm

- **Quick Start**: [`QUICK_START_SYNC.md`](QUICK_START_SYNC.md)
- **Full Guide**: [`GOOGLE_DRIVE_SYNC_GUIDE.md`](GOOGLE_DRIVE_SYNC_GUIDE.md)
- **Troubleshooting**: [`GOOGLE_DRIVE_SYNC_GUIDE.md`](GOOGLE_DRIVE_SYNC_GUIDE.md#troubleshooting)

---

## 🎯 Workflow khuyến nghị

### Lần đầu cài đặt:
```bash
./dev-install.sh
# → Chọn Y để setup Google Drive
# → Chọn y để restart plasmashell
# → Add widget vào desktop
# → Bật sync trong Settings
```

### Cập nhật code:
```bash
./dev-install.sh --skip-gdrive
# → Chọn y để restart plasmashell
```

### Gỡ cài đặt:
```bash
kpackagetool6 -t Plasma/Applet -r com.tranbao.stickynotes
```

---

## 💡 Tips

### Tip 1: Kiểm tra cài đặt thành công
```bash
# Kiểm tra plasmoid đã cài
kpackagetool6 -t Plasma/Applet -s stickynotes

# Kiểm tra Google Drive đã mount
mountpoint ~/GoogleDrive

# Kiểm tra file sync
cat ~/GoogleDrive/StickyNotes/sticky-notes-data.json
```

### Tip 2: Xem logs
```bash
# Logs plasmoid
journalctl --user -f | grep sticky

# Logs rclone
tail -f ~/.rclone-gdrive.log
```

### Tip 3: Backup dữ liệu
```bash
# Backup file JSON
cp ~/GoogleDrive/StickyNotes/sticky-notes-data.json \
   ~/GoogleDrive/StickyNotes/backup-$(date +%Y%m%d).json
```

---

## 🎉 Hoàn tất!

Bạn đã cài đặt thành công KDE Sticky Notes với Google Drive sync!

**Bắt đầu sử dụng ngay**: Tạo note đầu tiên và xem nó tự động sync lên Drive! 🚀
