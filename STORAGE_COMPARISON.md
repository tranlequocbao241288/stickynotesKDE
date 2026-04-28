# 📊 So sánh phương thức lưu trữ

## Tổng quan

KDE Sticky Notes hỗ trợ **2 phương thức lưu trữ**:

1. **Local JSON File** - Lưu trữ local
2. **Google Drive Sync** - Đồng bộ cloud

---

## 📋 Bảng so sánh

| Tiêu chí | Local JSON | Google Drive Sync |
|----------|------------|-------------------|
| **Setup** | ✅ Rất đơn giản (1 phút) | ⚠️ Cần setup (5-10 phút) |
| **Internet** | ✅ Không cần | ❌ Cần để sync |
| **Tốc độ** | ✅ Rất nhanh | ⚠️ Phụ thuộc mạng |
| **Backup** | ❌ Không tự động | ✅ Tự động |
| **Multi-device** | ❌ Không | ✅ Có |
| **Mất dữ liệu khi format** | ❌ Có | ✅ Không |
| **Privacy** | ✅ 100% local | ⚠️ Lưu trên Google |
| **Dung lượng** | ✅ Không giới hạn | ⚠️ 15GB free |
| **Phụ thuộc** | ✅ Không | ⚠️ rclone + Google |

---

## 1️⃣ Local JSON File

### ✅ Ưu điểm

#### Đơn giản
- Không cần setup phức tạp
- Không cần account ngoài
- Không cần internet

#### Nhanh
- Lưu/load tức thì
- Không có delay network
- Không có debounce sync

#### Privacy
- Dữ liệu 100% local
- Không lưu trên cloud
- Không chia sẻ với bên thứ 3

#### Không giới hạn
- Không giới hạn số notes
- Không giới hạn dung lượng
- Không phụ thuộc quota

### ❌ Nhược điểm

#### Không backup
- Mất dữ liệu khi format OS
- Mất dữ liệu khi ổ cứng hỏng
- Phải backup thủ công

#### Không multi-device
- Chỉ dùng trên 1 máy
- Không sync giữa máy
- Không truy cập từ xa

#### Rủi ro mất dữ liệu
- Xóa nhầm file config
- Reinstall OS
- Hardware failure

### 📁 Vị trí lưu trữ

```
~/.config/plasma-org.kde.plasma.desktop-appletsrc
```

### 💾 Backup thủ công

```bash
# Backup config file
cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc \
   ~/backup-sticky-notes-$(date +%Y%m%d).bak

# Restore
cp ~/backup-sticky-notes-20260428.bak \
   ~/.config/plasma-org.kde.plasma.desktop-appletsrc
```

### 🎯 Phù hợp với

- ✅ Người dùng cá nhân, 1 máy
- ✅ Dữ liệu không quan trọng
- ✅ Không cần backup tự động
- ✅ Ưu tiên privacy
- ✅ Không có internet ổn định

---

## 2️⃣ Google Drive Sync

### ✅ Ưu điểm

#### Backup tự động
- Tự động sync lên cloud
- Không mất dữ liệu khi format
- An toàn với hardware failure

#### Multi-device
- Sync giữa nhiều máy
- Truy cập từ web (Google Drive)
- Làm việc mọi nơi

#### Không lo mất dữ liệu
- Dữ liệu luôn có trên cloud
- Có thể restore bất cứ lúc nào
- Google Drive có version history

#### Tiện lợi
- Sync tự động (debounce 1s)
- Manual sync/load buttons
- Status indicator

### ❌ Nhược điểm

#### Setup phức tạp
- Cần cài rclone
- Cần cấu hình Google Drive
- Cần authenticate

#### Cần internet
- Không sync khi offline
- Phụ thuộc tốc độ mạng
- Có delay sync (1s debounce)

#### Privacy
- Dữ liệu lưu trên Google
- Google có thể truy cập
- Không phù hợp dữ liệu nhạy cảm

#### Giới hạn
- 15GB free (Google Drive)
- Phụ thuộc Google account
- Cần rclone hoạt động

### 📁 Vị trí lưu trữ

```
Local:  ~/.config/plasma-org.kde.plasma.desktop-appletsrc
Cloud:  ~/GoogleDrive/StickyNotes/sticky-notes-data.json
```

### 🔄 Cách hoạt động

```
Tạo/Sửa Note
     ↓
Save Local (ngay lập tức)
     ↓
Debounce 1s
     ↓
Sync to Google Drive
```

### 🎯 Phù hợp với

- ✅ Làm việc trên nhiều máy
- ✅ Dữ liệu quan trọng
- ✅ Cần backup tự động
- ✅ Có internet ổn định
- ✅ Đã có Google account

---

## 🔄 Chuyển đổi giữa 2 phương thức

### Local → Google Drive

```bash
# 1. Setup Google Drive
./setup-google-drive.sh

# 2. Bật sync trong Settings
# Right-click widget → Configure → Enable sync

# 3. Sync dữ liệu hiện tại lên Drive
# Click nút ☁️ (upload)
```

### Google Drive → Local

```bash
# 1. Tắt sync trong Settings
# Right-click widget → Configure → Disable sync

# 2. Dữ liệu vẫn lưu local
# Chỉ không sync lên Drive nữa
```

---

## 💡 Khuyến nghị

### Dùng Local JSON nếu:
- ✅ Chỉ dùng 1 máy
- ✅ Dữ liệu không quan trọng
- ✅ Ưu tiên đơn giản
- ✅ Ưu tiên privacy
- ✅ Không có internet

### Dùng Google Drive nếu:
- ✅ Dùng nhiều máy
- ✅ Dữ liệu quan trọng
- ✅ Cần backup tự động
- ✅ Có internet ổn định
- ✅ Đã quen Google Drive

### Hybrid (khuyến nghị):
1. Bắt đầu với **Local JSON** (đơn giản)
2. Khi cần backup → chuyển sang **Google Drive**
3. Hoặc dùng cả 2:
   - Local: lưu nhanh
   - Drive: backup tự động

---

## 🔐 Bảo mật

### Local JSON
- ✅ Dữ liệu 100% local
- ✅ Không chia sẻ với ai
- ⚠️ Không mã hóa (plain text trong config)
- ⚠️ Ai có quyền đọc file config đều đọc được

### Google Drive
- ✅ HTTPS encryption (in transit)
- ✅ Google Drive encryption at rest
- ⚠️ JSON file không mã hóa end-to-end
- ⚠️ Google có thể truy cập dữ liệu

### Khuyến nghị bảo mật:
- 🔒 Không lưu thông tin nhạy cảm (passwords, credit cards)
- 🔒 Bật 2FA cho Google account (nếu dùng Drive)
- 🔒 Giới hạn quyền truy cập thư mục Drive
- 🔒 Backup định kỳ (cả 2 phương thức)

---

## 📊 Performance

### Local JSON
- **Save**: ~5ms
- **Load**: ~10ms
- **Total**: ~15ms

### Google Drive Sync
- **Save local**: ~5ms
- **Debounce**: 1000ms
- **Sync to Drive**: ~50-200ms
- **Total**: ~1055-1205ms

**Kết luận**: Local nhanh hơn ~70x, nhưng không có backup.

---

## 🎯 Kết luận

### Không có phương thức nào "tốt nhất"

Mỗi phương thức phù hợp với use case khác nhau:

- **Local JSON**: Đơn giản, nhanh, privacy
- **Google Drive**: Backup, multi-device, an toàn

### Lựa chọn của bạn phụ thuộc vào:
1. Số máy tính bạn dùng
2. Tầm quan trọng của dữ liệu
3. Có internet ổn định không
4. Ưu tiên privacy hay convenience

### Bạn luôn có thể chuyển đổi sau!

Bắt đầu với Local, chuyển sang Drive khi cần. Hoặc ngược lại.

---

## 🚀 Bắt đầu

```bash
./dev-install.sh
```

Chọn phương thức phù hợp với bạn! 🎉
