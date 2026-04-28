# ✅ Test Checklist - Google Drive Sync

## Pre-requisites

- [ ] rclone đã cài đặt: `rclone --version`
- [ ] Google Drive đã cấu hình: `rclone listremotes | grep gdrive`
- [ ] Google Drive đã mount: `mountpoint ~/GoogleDrive`

---

## Setup Tests

### Test 1: Chạy setup script
```bash
./setup-google-drive.sh
```
- [ ] Script chạy không lỗi
- [ ] Thư mục `~/GoogleDrive` được tạo
- [ ] Thư mục `~/GoogleDrive/StickyNotes` được tạo
- [ ] Google Drive được mount thành công
- [ ] Systemd service được tạo và enable

### Test 2: Cài plasmoid
```bash
./dev-install.sh
```
- [ ] Plasmoid cài thành công
- [ ] Không có lỗi QML khi load
- [ ] Widget hiển thị bình thường

---

## Configuration Tests

### Test 3: Mở Settings
- [ ] Right-click widget → Configure → dialog mở
- [ ] Tab "General" có section "Google Drive Sync"
- [ ] Checkbox "Enable sync" có thể bật/tắt
- [ ] TextField "Drive path" hiển thị đúng default
- [ ] TextField "File name" hiển thị đúng default
- [ ] Help text và links hiển thị

### Test 4: Enable sync
- [ ] Bật checkbox "Enable sync"
- [ ] Click "Apply" → không crash
- [ ] Click "Check" → status indicator chuyển 🟢 xanh
- [ ] Nếu Drive chưa mount → status 🔴 đỏ

---

## Auto Sync Tests

### Test 5: Tạo note mới
1. Click nút "+ New Note"
2. Đợi 1 giây
3. Kiểm tra file:
```bash
cat ~/GoogleDrive/StickyNotes/sticky-notes-data.json
```
- [ ] File được tạo
- [ ] File chứa JSON hợp lệ
- [ ] JSON có note vừa tạo

### Test 6: Sửa note
1. Sửa title của note
2. Đợi 1 giây
3. Kiểm tra file JSON
- [ ] File được cập nhật
- [ ] Title mới có trong JSON

### Test 7: Thêm todo
1. Thêm todo vào note
2. Đợi 1 giây
3. Kiểm tra file JSON
- [ ] Todo mới có trong JSON

### Test 8: Xóa note
1. Xóa note (confirm dialog)
2. Đợi 1 giây
3. Kiểm tra file JSON
- [ ] Note đã bị xóa khỏi JSON

---

## Manual Sync Tests

### Test 9: Manual sync to Drive
1. Tạo note mới
2. Click nút ☁️ (cloud-upload) ngay lập tức
3. Kiểm tra:
- [ ] Notification "Synced to Google Drive!" hiện ra
- [ ] File JSON được cập nhật ngay (không đợi 1s)

### Test 10: Manual load from Drive
1. Sửa file JSON trực tiếp:
```bash
nano ~/GoogleDrive/StickyNotes/sticky-notes-data.json
# Thêm note mới vào JSON
```
2. Click nút ☁️ (cloud-download)
3. Kiểm tra:
- [ ] Notification "Loaded from Google Drive!" hiện ra
- [ ] Note mới từ JSON xuất hiện trong widget

---

## Fallback Tests

### Test 11: Drive unavailable
1. Unmount Drive:
```bash
fusermount -u ~/GoogleDrive
```
2. Restart plasmoid
3. Kiểm tra:
- [ ] Plasmoid không crash
- [ ] Load từ local config thành công
- [ ] Log warning về Drive unavailable

### Test 12: Invalid JSON on Drive
1. Ghi JSON lỗi vào file:
```bash
echo "invalid json" > ~/GoogleDrive/StickyNotes/sticky-notes-data.json
```
2. Restart plasmoid
3. Kiểm tra:
- [ ] Plasmoid không crash
- [ ] Fallback về local config
- [ ] Log error về JSON parse

### Test 13: Drive path không tồn tại
1. Đổi Drive path trong Settings thành path không tồn tại
2. Click Apply
3. Tạo note mới
4. Kiểm tra:
- [ ] Plasmoid không crash
- [ ] Thư mục được tạo tự động (nếu có quyền)
- [ ] Hoặc log error nếu không tạo được

---

## Restart Tests

### Test 14: Restart plasmoid
1. Tạo vài notes
2. Đợi sync xong
3. Restart plasmoid (remove + add widget)
4. Kiểm tra:
- [ ] Notes được load từ Drive
- [ ] Tất cả notes hiển thị đúng
- [ ] Không mất dữ liệu

### Test 15: Restart máy
1. Tạo vài notes
2. Đợi sync xong
3. Restart máy
4. Mở plasmoid
5. Kiểm tra:
- [ ] Google Drive tự động mount (systemd service)
- [ ] Notes được load từ Drive
- [ ] Không mất dữ liệu

---

## Multi-Device Tests (nếu có 2 máy)

### Test 16: Sync giữa 2 máy
**Máy A:**
1. Tạo note "Test from A"
2. Đợi sync xong

**Máy B:**
1. Click nút load from Drive
2. Kiểm tra:
- [ ] Note "Test from A" xuất hiện

**Máy B:**
1. Tạo note "Test from B"
2. Đợi sync xong

**Máy A:**
1. Click nút load from Drive
2. Kiểm tra:
- [ ] Note "Test from B" xuất hiện

### Test 17: Conflict (sửa cùng lúc)
**Máy A:**
1. Sửa note X thành "Version A"
2. Đợi sync

**Máy B:**
1. Sửa note X thành "Version B"
2. Đợi sync

**Máy A:**
1. Load from Drive
2. Kiểm tra:
- [ ] Note X có nội dung "Version B" (last-write-wins)

---

## Performance Tests

### Test 18: Large dataset
1. Tạo 100 notes (có thể dùng script)
2. Đợi sync xong
3. Kiểm tra:
- [ ] Sync hoàn tất trong < 5 giây
- [ ] File JSON < 1MB
- [ ] UI không lag

### Test 19: Rapid changes
1. Tạo/sửa/xóa notes liên tục trong 10 giây
2. Đợi sync xong
3. Kiểm tra:
- [ ] Chỉ sync 1 lần (debounce hoạt động)
- [ ] Dữ liệu cuối cùng đúng

---

## Error Handling Tests

### Test 20: Disk full (Drive)
1. Giả lập disk full (khó test thực tế)
2. Tạo note mới
3. Kiểm tra:
- [ ] Plasmoid không crash
- [ ] Log error rõ ràng
- [ ] Local config vẫn được lưu

### Test 21: Permission denied
1. Chmod 000 thư mục Drive:
```bash
chmod 000 ~/GoogleDrive/StickyNotes
```
2. Tạo note mới
3. Kiểm tra:
- [ ] Plasmoid không crash
- [ ] Log error về permission
- [ ] Local config vẫn được lưu
4. Restore permission:
```bash
chmod 755 ~/GoogleDrive/StickyNotes
```

---

## UI Tests

### Test 22: Sync buttons visibility
- [ ] Khi sync disabled → buttons ẩn
- [ ] Khi sync enabled → buttons hiện
- [ ] Tooltips hiển thị đúng khi hover

### Test 23: Notification
- [ ] Notification hiện đúng vị trí (bottom center)
- [ ] Notification tự động ẩn sau 3 giây
- [ ] Notification có màu xanh (positive)

### Test 24: Settings dialog
- [ ] Status indicator cập nhật khi click "Check"
- [ ] Help text và links có thể click
- [ ] Apply/OK/Cancel buttons hoạt động đúng

---

## Logs Tests

### Test 25: Check logs
```bash
# Plasmoid logs
journalctl --user -f | grep sticky

# rclone logs
tail -f ~/.rclone-gdrive.log
```
- [ ] Logs hiển thị sync events
- [ ] Logs hiển thị errors (nếu có)
- [ ] Logs không spam quá nhiều

---

## Cleanup Tests

### Test 26: Disable sync
1. Tắt checkbox "Enable sync"
2. Click Apply
3. Tạo note mới
4. Kiểm tra:
- [ ] File JSON không được cập nhật
- [ ] Local config vẫn được lưu
- [ ] Sync buttons ẩn

### Test 27: Uninstall
1. Remove widget
2. Kiểm tra:
- [ ] File JSON vẫn còn trên Drive (không bị xóa)
- [ ] Local config vẫn còn
- [ ] Có thể cài lại và load dữ liệu

---

## Summary

### Critical Tests (phải pass):
- [ ] Test 5: Tạo note → auto-sync
- [ ] Test 14: Restart plasmoid → load từ Drive
- [ ] Test 15: Restart máy → không mất dữ liệu
- [ ] Test 11: Drive unavailable → fallback local

### Important Tests (nên pass):
- [ ] Test 9: Manual sync
- [ ] Test 10: Manual load
- [ ] Test 12: Invalid JSON → không crash
- [ ] Test 18: Large dataset → performance OK

### Nice-to-have Tests (có thể skip):
- [ ] Test 16-17: Multi-device sync
- [ ] Test 20-21: Error handling edge cases

---

## Test Results

**Date**: ___________
**Tester**: ___________
**Version**: 2.0.0

**Overall Status**: ⬜ Pass / ⬜ Fail / ⬜ Partial

**Notes**:
_______________________________________
_______________________________________
_______________________________________

**Issues Found**:
1. _______________________________________
2. _______________________________________
3. _______________________________________
