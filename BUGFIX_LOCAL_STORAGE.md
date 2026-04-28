# 🐛 Bugfix: Local Storage không lưu dữ liệu

## Vấn đề

Khi chọn **Local JSON File** (option 1) trong `dev-install.sh`, dữ liệu notes **bị mất** sau khi restart máy.

## Nguyên nhân

Trong `logic.js`, code đang dùng sai cách truy cập configuration:

```javascript
// ❌ SAI
plasmoidItem.Plasmoid.configuration.notesData

// ✅ ĐÚNG
plasmoidItem.plasmoid.configuration.notesData
```

**Giải thích**:
- Trong QML, `plasmoid` là property (chữ thường)
- `Plasmoid` (chữ hoa) không tồn tại
- Dẫn đến save/load thất bại im lặng (không throw error)

## Các file bị ảnh hưởng

1. `package/contents/code/logic.js`:
   - `_doSave()` - Lưu dữ liệu
   - `loadFromConfig()` - Load dữ liệu
   - `_loadFromDrive()` - Load từ Drive
   - `_scheduleDriveSync()` - Schedule sync
   - `_doSyncToDrive()` - Sync to Drive
   - `checkGoogleDriveAvailable()` - Check Drive

2. `package/contents/ui/main.qml`:
   - Sync buttons visibility

## Fix đã áp dụng

### 1. Sửa `logic.js`

Thay tất cả `plasmoidItem.Plasmoid.configuration` thành `plasmoidItem.plasmoid.configuration`:

```javascript
// Trước
function _doSave(plasmoidItem, notes) {
    plasmoidItem.Plasmoid.configuration.notesData = jsonString;
}

// Sau
function _doSave(plasmoidItem, notes) {
    plasmoidItem.plasmoid.configuration.notesData = jsonString;
}
```

**Tổng cộng**: 6 functions đã sửa

### 2. Sửa `main.qml`

Thay `root.Plasmoid.configuration` thành `root.plasmoid.configuration`:

```qml
// Trước
visible: root.Plasmoid.configuration.enableGoogleDriveSync

// Sau
visible: root.plasmoid.configuration.enableGoogleDriveSync
```

**Tổng cộng**: 2 chỗ đã sửa

## Kiểm tra fix

### Test 1: Save dữ liệu
```bash
# 1. Cài lại plasmoid
./dev-install.sh --skip-gdrive

# 2. Tạo note mới
# 3. Kiểm tra logs
journalctl --user -f | grep "logic.js"

# Expected: "logic.js: Saved X notes to local config"
```

### Test 2: Load dữ liệu
```bash
# 1. Tạo vài notes
# 2. Restart plasmoid (remove + add widget)
# 3. Kiểm tra logs
journalctl --user -f | grep "logic.js"

# Expected: "logic.js: Loaded X notes from local config"
```

### Test 3: Restart máy
```bash
# 1. Tạo vài notes
# 2. Restart máy
# 3. Mở plasmoid
# 4. Kiểm tra notes vẫn còn

# Expected: Notes không bị mất
```

## Cách verify config đang lưu

### Kiểm tra config file:
```bash
# Tìm config file
find ~/.config -name "*plasma*" -type f | grep -i applet

# Hoặc
cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc | grep -A 5 "stickynotes"
```

### Kiểm tra trong QML console:
```qml
Component.onCompleted: {
    console.log("Config notesData:", plasmoid.configuration.notesData)
    console.log("Enable sync:", plasmoid.configuration.enableGoogleDriveSync)
}
```

## Impact

### Trước fix:
- ❌ Local storage không hoạt động
- ❌ Dữ liệu mất sau restart
- ❌ User phải dùng Google Drive bắt buộc

### Sau fix:
- ✅ Local storage hoạt động đúng
- ✅ Dữ liệu persist sau restart
- ✅ User có thể chọn Local hoặc Drive

## Lesson Learned

### 1. QML property naming
- QML properties luôn là **camelCase** (chữ thường đầu)
- `plasmoid`, `configuration`, `notesData`
- Không phải `Plasmoid`, `Configuration`

### 2. Silent failures
- Truy cập property không tồn tại → `undefined`
- Không throw error → khó debug
- Cần kiểm tra logs kỹ

### 3. Testing
- Phải test cả 2 phương thức (Local + Drive)
- Phải test restart để verify persistence
- Không chỉ test trong development session

## Checklist sau khi fix

- [x] Sửa tất cả `Plasmoid.configuration` → `plasmoid.configuration`
- [x] Test save dữ liệu
- [x] Test load dữ liệu
- [x] Test restart plasmoid
- [x] Test restart máy
- [x] Verify logs
- [x] Update documentation

## Files đã sửa

```
✏️ package/contents/code/logic.js (6 functions)
✏️ package/contents/ui/main.qml (2 chỗ)
🆕 BUGFIX_LOCAL_STORAGE.md (file này)
```

## Version

- **Before**: 2.1.0 (có bug)
- **After**: 2.1.1 (đã fix)

## Commit message

```
fix: Local storage not persisting data after restart

Fixed incorrect property access in logic.js:
- Changed Plasmoid.configuration → plasmoid.configuration
- Affected 6 functions in logic.js
- Affected 2 places in main.qml

This bug caused local storage to fail silently, resulting in
data loss after restart when using Local JSON option.

Fixes: Local storage persistence
Tested: Save, load, restart plasmoid, restart system
```

---

**Status**: ✅ Fixed
**Date**: 2026-04-28
**Version**: 2.1.1
