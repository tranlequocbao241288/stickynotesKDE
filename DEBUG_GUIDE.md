# 🔍 Hướng dẫn Debug - Storage Issue

## Vấn đề hiện tại

Notes được lưu nhưng **todos bị mất** sau khi restart.

## Các khả năng

### 1. Todos không được save
- `notesModel` không chứa todos
- `items` array bị rỗng khi save
- JSON.stringify không serialize đúng

### 2. Todos được save nhưng không load
- JSON parse lỗi
- `validateNote()` xóa todos
- Config không persist đúng

### 3. Todos bị ghi đè
- Load trước khi save hoàn tất
- Race condition
- Multiple instances

## Debug Steps

### Bước 1: Cài lại với debug logging

```bash
./debug-storage.sh
```

Script sẽ:
1. Cài lại plasmoid với debug logs
2. Hướng dẫn tạo test data
3. Kiểm tra logs save
4. Kiểm tra logs load
5. Kiểm tra config file

### Bước 2: Manual debug

#### A. Kiểm tra logs realtime

```bash
# Terminal 1: Watch logs
journalctl --user -f | grep "logic.js"

# Terminal 2: Thao tác với widget
# - Tạo note
# - Add todos
# - Xem logs trong Terminal 1
```

#### B. Kiểm tra config file

```bash
# Tìm config file
find ~/.config -name "*plasma*appletsrc"

# Xem nội dung
cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc | grep -A 10 "notesData"
```

#### C. Kiểm tra JSON

```bash
# Extract JSON từ config
cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc | \
  grep "notesData=" | \
  sed 's/notesData=//' | \
  python3 -m json.tool
```

### Bước 3: Test từng function

#### Test save

```javascript
// Trong QML console hoặc thêm vào Component.onCompleted
console.log("Before save:", JSON.stringify(root.notesModel))
Logic.scheduleSave(root, root.notesModel)
```

#### Test load

```javascript
// Trong Component.onCompleted
var loaded = Logic.loadFromConfig(root)
console.log("Loaded:", JSON.stringify(loaded))
```

## Expected Logs

### Khi save (đúng):

```
logic.js: Saving notes: 1
  Note 0 : tranbao - items: 2
logic.js: Saved 1 notes to local config
logic.js: JSON length: 456 chars
```

### Khi load (đúng):

```
logic.js: Loading from local config, JSON length: 456
logic.js: Parsed 1 notes from JSON
  Note 0 : tranbao - items: 2
logic.js: Loaded 1 notes from local config
```

### Nếu todos bị mất:

```
logic.js: Saving notes: 1
  Note 0 : tranbao - items: 0  ← ❌ items = 0!
```

Hoặc:

```
logic.js: Parsed 1 notes from JSON
  Note 0 : tranbao - items: 0  ← ❌ items = 0 sau parse!
```

## Common Issues

### Issue 1: items không được thêm vào notesModel

**Nguyên nhân**: Signal không được emit đúng

**Fix**: Kiểm tra `onTodoAdded` trong NoteCard.qml

### Issue 2: notesModel không immutable

**Nguyên nhân**: Sửa trực tiếp object thay vì tạo mới

**Fix**: Dùng `Logic.addTodoToNote()` đúng cách

### Issue 3: Save trước khi add todo hoàn tất

**Nguyên nhân**: Race condition

**Fix**: Đảm bảo `scheduleSave` được gọi SAU khi update `notesModel`

## Quick Fixes

### Fix 1: Force save sau mỗi thao tác

Thêm vào main.qml:

```qml
onNotesModelChanged: {
    console.log("notesModel changed, saving...")
    Logic.scheduleSave(root, root.notesModel)
}
```

### Fix 2: Verify data trước khi save

Thêm vào logic.js `_doSave()`:

```javascript
// Verify items exist
for (var i = 0; i < notes.length; i++) {
    if (!notes[i].items || !Array.isArray(notes[i].items)) {
        console.error("Note", i, "has invalid items!");
        notes[i].items = [];
    }
}
```

### Fix 3: Deep clone khi update

Trong main.qml:

```qml
onTodoAdded: function(noteId, content) {
    var newTodo = Logic.createTodo(noteId, root.notesModel)
    if (content) {
        newTodo.content = content
    }
    
    // Deep clone notesModel
    var newModel = JSON.parse(JSON.stringify(root.notesModel))
    newModel = Logic.addTodoToNote(newModel, noteId, newTodo)
    root.notesModel = newModel
    
    Logic.scheduleSave(root, root.notesModel)
}
```

## Test Checklist

- [ ] Tạo note → Check logs → Verify save
- [ ] Add todo → Check logs → Verify save with items
- [ ] Restart plasmoid → Check logs → Verify load with items
- [ ] Check config file → Verify JSON contains items
- [ ] Restart máy → Verify todos vẫn còn

## Scripts

### debug-storage.sh
Automated debug workflow

### check-logs.sh
Quick log check

### Manual commands

```bash
# Watch logs
journalctl --user -f | grep "logic.js"

# Check config
cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc | grep "notesData"

# Pretty print JSON
cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc | \
  grep "notesData=" | \
  sed 's/notesData=//' | \
  python3 -m json.tool
```

## Next Steps

1. Chạy `./debug-storage.sh`
2. Xem logs để xác định vấn đề
3. Apply fix tương ứng
4. Test lại

---

**Mục tiêu**: Tìm ra tại sao `items` array bị rỗng hoặc bị mất.
