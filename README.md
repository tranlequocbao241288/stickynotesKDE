# 📝 KDE Sticky Notes

Một plasmoid (desktop widget) cho KDE Plasma để ghi chú nhanh với tính năng đồng bộ Google Drive.

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![KDE Plasma](https://img.shields.io/badge/KDE%20Plasma-5%20%7C%206-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## ✨ Tính năng

### 📌 Quản lý Notes
- ✅ Tạo/sửa/xóa notes dễ dàng
- ✅ Drag & drop để di chuyển notes
- ✅ Resize notes tùy ý
- ✅ 6 màu preset đẹp mắt
- ✅ Tự động lưu mọi thay đổi

### ✅ Todo Lists
- ✅ Thêm/sửa/xóa todo items
- ✅ Checkbox đánh dấu hoàn thành
- ✅ Deadline tracking với màu cảnh báo
- ✅ Reorder todos bằng drag & drop
- ✅ Relative time display ("2 hours ago")

### 🔍 Tìm kiếm & Lọc
- ✅ Search realtime (debounce 300ms)
- ✅ Highlight từ khóa tìm kiếm
- ✅ Filter: All / Active / Completed / Overdue
- ✅ Keyboard shortcut: Ctrl+F

### ☁️ Google Drive Sync (NEW!)
- ✅ **Tự động sync** lên Google Drive
- ✅ **Không mất dữ liệu** khi restart máy
- ✅ **Sync giữa nhiều máy** tính
- ✅ **Backup tự động** lên cloud
- ✅ **Manual sync/load** buttons
- ✅ **Fallback** về local nếu Drive offline

---

## 🚀 Cài đặt nhanh

### Chỉ cần 1 lệnh:

```bash
./dev-install.sh
```

Script sẽ hỏi bạn chọn **phương thức lưu trữ**:

#### 1️⃣ Local JSON File
- Lưu trữ local trên máy
- Không cần internet
- Đơn giản, nhanh
- ⚠️ Mất dữ liệu khi format OS

#### 2️⃣ Google Drive Sync
- Tự động sync lên cloud
- Không mất dữ liệu khi restart
- Sync giữa nhiều máy
- Backup tự động
- ⚠️ Cần internet + Google account

**Thời gian**: 
- Local: ~1 phút
- Google Drive: ~5-10 phút

📖 **Chi tiết**: Xem [`INSTALL_GUIDE.md`](INSTALL_GUIDE.md)

---

## 📸 Screenshots

```
┌─────────────────────────────────────────┐
│  📝 Sticky Notes        [+] [☁️] [☁️]   │
├─────────────────────────────────────────┤
│  🔍 Search...                           │
│  [All] [Active] [Completed] [Overdue]  │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────┐             │
│  │ 📝 Shopping List  [🎨][✕]│           │
│  ├───────────────────────┤             │
│  │ ☐ Buy milk            │             │
│  │   ⚠️ Due in 2 hours    │             │
│  │                       │             │
│  │ ☑ Buy eggs (done)     │             │
│  │   ✓ Completed         │             │
│  │                       │             │
│  │ [+ Add item...]       │             │
│  └───────────────────────┘             │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🎯 Use Cases

### 📝 Ghi chú nhanh
- Ghi ý tưởng đột xuất
- Note meeting points
- Lưu links/commands cần dùng

### ✅ Todo lists
- Shopping list
- Daily tasks
- Project checklist

### 📅 Deadline tracking
- Theo dõi deadlines
- Cảnh báo quá hạn
- Ưu tiên tasks

### ☁️ Multi-device
- Làm việc trên nhiều máy
- Sync tự động
- Backup an toàn

---

## 📋 Yêu cầu hệ thống

### Bắt buộc:
- **KDE Plasma**: 5.x hoặc 6.x
- **Qt**: 5.15+ hoặc 6.x
- **Linux**: Ubuntu, Fedora, Arch, etc.

### Tùy chọn (cho Google Drive sync):
- **rclone**: Để mount Google Drive
- **Google Drive account**: Free 15GB
- **Internet**: Để sync

---

## 🔧 Cấu hình

### Bật Google Drive Sync:

1. Right-click widget → **Configure**
2. ✅ Bật **"Enable sync"**
3. Đường dẫn: `~/GoogleDrive/StickyNotes`
4. Click **Apply**

### Tùy chỉnh:
- **Màu notes**: Click icon 🎨
- **Deadline**: Click vào due date
- **Thứ tự todos**: Drag & drop

---

## 📚 Documentation

### User Guides:
- 📖 [**Install Guide**](INSTALL_GUIDE.md) - Hướng dẫn cài đặt chi tiết
- 🚀 [**Quick Start**](QUICK_START_SYNC.md) - Bắt đầu trong 5 phút
- 📘 [**Full Guide**](GOOGLE_DRIVE_SYNC_GUIDE.md) - Hướng dẫn đầy đủ
- 📝 [**Tutorial**](TUTORIAL_KDE_StickyNotes.md) - Tutorial học tập

### Developer Docs:
- 🏗️ [**SRS**](SRS_KDE_StickyNotes.md) - Software Requirements Specification
- 📋 [**Implementation Plan**](IMPLEMENTATION_PLAN_KDE_StickyNotes.md) - Kế hoạch triển khai
- 🔄 [**Changelog**](CHANGELOG_GOOGLE_DRIVE_SYNC.md) - Chi tiết thay đổi
- 📊 [**Implementation Summary**](IMPLEMENTATION_SUMMARY.md) - Tóm tắt implementation
- ✅ [**Test Checklist**](TEST_CHECKLIST.md) - Checklist test

### Index:
- 📚 [**Documentation Index**](INDEX_GOOGLE_DRIVE_SYNC.md) - Danh mục tất cả tài liệu

---

## 🛠️ Development

### Setup môi trường:

```bash
# Clone repo
git clone <repo-url>
cd sticknotesKDE

# Cài đặt (bao gồm Google Drive setup)
./dev-install.sh
```

### Cập nhật code:

```bash
# Sửa code trong package/contents/...

# Cài lại (skip Google Drive setup)
./dev-install.sh --skip-gdrive
```

### Cấu trúc project:

```
sticknotesKDE/
├── package/
│   └── contents/
│       ├── code/
│       │   └── logic.js          # Business logic
│       ├── config/
│       │   └── main.xml           # Configuration
│       └── ui/
│           ├── main.qml           # Main UI
│           ├── NoteCard.qml       # Note component
│           ├── TodoItem.qml       # Todo component
│           ├── ConfigGeneral.qml  # Settings dialog
│           └── Executable.qml     # Shell helper
│
├── dev-install.sh                 # Install script
├── setup-google-drive.sh          # Google Drive setup
└── docs/                          # Documentation
```

---

## 🧪 Testing

### Chạy tests:

```bash
# Test logic
node test_logic.js

# Test manual theo checklist
# Xem TEST_CHECKLIST.md
```

### Test Google Drive sync:

```bash
# Tạo note
# Đợi 1 giây
# Kiểm tra file
cat ~/GoogleDrive/StickyNotes/sticky-notes-data.json
```

---

## 🐛 Troubleshooting

### ❌ Widget không hiển thị
```bash
kquitapp6 plasmashell && kstart plasmashell
```

### ❌ Google Drive không sync
```bash
# Kiểm tra mount
mountpoint ~/GoogleDrive

# Xem logs
tail -f ~/.rclone-gdrive.log
```

### ❌ Mất dữ liệu
```bash
# Dữ liệu vẫn còn trên Drive
cat ~/GoogleDrive/StickyNotes/sticky-notes-data.json

# Load lại
# Click nút ☁️ (cloud-download) trên widget
```

📖 **Chi tiết**: Xem [`GOOGLE_DRIVE_SYNC_GUIDE.md`](GOOGLE_DRIVE_SYNC_GUIDE.md#troubleshooting)

---

## 🤝 Contributing

Contributions are welcome! 

### Workflow:
1. Fork repo
2. Tạo branch: `git checkout -b feature/amazing-feature`
3. Commit: `git commit -m 'Add amazing feature'`
4. Push: `git push origin feature/amazing-feature`
5. Tạo Pull Request

### Guidelines:
- Follow existing code style
- Test thoroughly (xem `TEST_CHECKLIST.md`)
- Update documentation
- Write clear commit messages

---

## 📝 License

MIT License - xem file [LICENSE](LICENSE) để biết chi tiết.

---

## 🙏 Credits

### Tác giả:
- **tranbao** - Initial work

### Công nghệ:
- **KDE Plasma** - Desktop environment
- **Qt/QML** - UI framework
- **rclone** - Google Drive sync

### Cảm ơn:
- KDE Community
- rclone developers
- All contributors

---

## 📞 Support

### Gặp vấn đề?
1. Đọc [Troubleshooting](GOOGLE_DRIVE_SYNC_GUIDE.md#troubleshooting)
2. Kiểm tra [Issues](https://github.com/yourusername/sticknotesKDE/issues)
3. Tạo issue mới nếu chưa có

### Liên hệ:
- GitHub: [@yourusername](https://github.com/yourusername)
- Email: your.email@example.com

---

## 🗺️ Roadmap

### Version 2.1 (Q2 2026):
- [ ] Conflict resolution thông minh
- [ ] Sync history
- [ ] Offline queue
- [ ] Progress indicator

### Version 3.0 (Q3 2026):
- [ ] End-to-end encryption
- [ ] Selective sync
- [ ] Multiple destinations (Dropbox, OneDrive)
- [ ] Mobile app companion

### Version 4.0 (Q4 2026):
- [ ] Realtime sync (WebSocket)
- [ ] Collaborative editing
- [ ] Version control
- [ ] API for third-party integrations

---

## ⭐ Star History

Nếu project này hữu ích, hãy cho một ⭐ trên GitHub!

---

## 📊 Stats

- **Version**: 2.0.0
- **Lines of Code**: ~1,500
- **Files**: 15+
- **Documentation**: 40KB+
- **Features**: 20+
- **Tests**: 27 test cases

---

**Made with ❤️ by tranbao**

**Enjoy using KDE Sticky Notes! 🎉**
