# SRS — KDE Sticky Notes Plasmoid
**Phiên bản:** 1.0.0  
**Ngày:** 2026-04-24  
**Tác giả:** tranbao  
**Trạng thái:** Draft  

---

## Mục lục

1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Định nghĩa thuật ngữ](#2-định-nghĩa-thuật-ngữ)
3. [Actors & Use Cases](#3-actors--use-cases)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-functional Requirements](#5-non-functional-requirements)
6. [Data Model](#6-data-model)
7. [Business Logic](#7-business-logic)
8. [UI Design](#8-ui-design)
9. [Component Mapping (QML)](#9-component-mapping-qml)
10. [Storage Strategy](#10-storage-strategy)
11. [Error Handling](#11-error-handling)
12. [Đánh giá & Bổ sung đề xuất](#12-đánh-giá--bổ-sung-đề-xuất)
13. [Milestones](#13-milestones)
14. [AI Agent Prompts](#14-ai-agent-prompts)

---

## 1. Tổng quan dự án

### 1.1 Mục tiêu

Xây dựng một **plasmoid (desktop widget)** cho KDE Plasma cho phép:

- Ghi chú nhanh dạng sticky note trên desktop
- Quản lý danh sách todo theo từng note
- Theo dõi thời gian tạo (`createdAt`) và thời hạn (`dueDate`)
- Lưu trữ dữ liệu local, không mất khi restart Plasma

### 1.2 Phạm vi

| Hạng mục | Chi tiết |
|---|---|
| Môi trường | KDE Plasma (Linux) |
| Ngôn ngữ | QML + JavaScript |
| Lưu trữ | `plasmoid.configuration` hoặc JSON file local |
| Phụ thuộc ngoài | Không (pure QML/JS) |

### 1.3 Ngoài phạm vi (Out of Scope)

- Sync cloud (để Phase 3+)
- Notification hệ thống (để Phase 3+)
- Markdown render (để Phase 3+)
- Multi-user / shared notes

---

## 2. Định nghĩa thuật ngữ

| Thuật ngữ | Mô tả |
|---|---|
| **Note** | Một khối ghi chú, chứa tiêu đề, màu nền và danh sách todo |
| **Todo Item** | Một task cụ thể bên trong một Note |
| **createdAt** | Thời điểm tạo Note hoặc Todo, định dạng ISO 8601 |
| **dueDate** | Thời hạn hoàn thành Todo, định dạng ISO 8601 |
| **completed** | Trạng thái hoàn thành của Todo (boolean) |
| **Plasmoid** | Widget chạy trong môi trường KDE Plasma |
| **Status** | Trạng thái deadline: `normal`, `warning`, `overdue`, `done` |

---

## 3. Actors & Use Cases

### 3.1 Actor

- **User** — người dùng duy nhất, tương tác trực tiếp qua desktop widget

### 3.2 Use Case tổng quan

```
User
 ├── Quản lý Note
 │    ├── UC-01: Tạo Note mới
 │    ├── UC-02: Xóa Note
 │    ├── UC-03: Chỉnh sửa Note (title, màu)
 │    └── UC-04: Resize / Drag Note
 │
 ├── Quản lý Todo
 │    ├── UC-05: Thêm Todo vào Note
 │    ├── UC-06: Chỉnh sửa nội dung Todo
 │    ├── UC-07: Chỉnh sửa dueDate
 │    ├── UC-08: Đánh dấu hoàn thành
 │    ├── UC-09: Xóa Todo
 │    └── UC-10: Reorder Todo (drag & drop)
 │
 └── Tìm kiếm & Lọc
      ├── UC-11: Tìm kiếm theo text
      └── UC-12: Lọc theo trạng thái
```

---

## 4. Functional Requirements

### 4.1 Quản lý Note

#### FR-01: Tạo Note mới
- **Mô tả:** User tạo một Note mới xuất hiện trên desktop
- **Trigger:** Click nút `[+]` trên panel hoặc right-click desktop → "New Note"
- **Default values:**
  - `title`: `"New Note"`
  - `color`: `#fff59d` (vàng nhạt)
  - `createdAt`: thời điểm hiện tại (ISO 8601)
  - `items`: `[]`
- **Output:** Note mới hiển thị trên desktop, title đang ở trạng thái edit

#### FR-02: Xóa Note
- **Mô tả:** User xóa một Note khỏi desktop
- **Trigger:** Click icon xóa trên Note
- **Điều kiện:** Phải hiển thị confirm dialog trước khi xóa
- **Confirm message:** `"Xóa note này? Tất cả todo bên trong sẽ bị mất."`
- **Output:** Note biến mất, dữ liệu bị xóa khỏi storage

#### FR-03: Chỉnh sửa Note
- **Mô tả:** User chỉnh sửa thông tin của Note
- **Các trường có thể sửa:**
  - `title`: click vào title để edit inline
  - `color`: chọn từ bảng màu preset (tối thiểu 6 màu)
- **Auto-save:** lưu ngay khi mất focus

#### FR-04: Resize & Drag
- **Mô tả:** User có thể thay đổi kích thước và vị trí Note trên desktop
- **Resize:** kéo góc/cạnh của Note
- **Drag:** kéo phần header của Note
- **Lưu trạng thái:** `x`, `y`, `width`, `height` được lưu vào config

### 4.2 Quản lý Todo

#### FR-05: Thêm Todo
- **Mô tả:** User thêm todo item mới vào Note
- **Trigger:** Nhấn `Enter` hoặc click `[+ Add item]`
- **Default values khi tạo:**

```js
{
  id: generateId(),        // UUID
  content: "",             // rỗng, focus ngay vào input
  createdAt: now,          // ISO 8601
  dueDate: now,            // mặc định = ngay hôm nay
  completed: false
}
```

- **Ràng buộc:** không cho save nếu `content` rỗng

#### FR-06: Chỉnh sửa Todo
- **Mô tả:** User sửa nội dung hoặc deadline của todo
- **Các trường có thể sửa:**
  - `content`: click vào text để edit inline
  - `dueDate`: click vào date để mở DatePicker
- **Auto-save:** lưu ngay khi mất focus

#### FR-07: Đánh dấu hoàn thành
- **Mô tả:** User toggle trạng thái hoàn thành của todo
- **Trigger:** Click vào checkbox
- **Khi `completed = true`:**
  - Text bị gạch ngang (`text-decoration: line-through`)
  - Màu text chuyển xám (`#9e9e9e`)
  - `status` = `"done"`
- **Khi `completed = false`:** hoàn nguyên về trạng thái cũ

#### FR-08: Xóa Todo
- **Mô tả:** User xóa một todo item
- **Trigger:** Click icon xóa trên todo item (hiện khi hover)
- **Không cần confirm** (khác với xóa Note)

#### FR-09 (bổ sung): Reorder Todo
- **Mô tả:** User kéo thả để sắp xếp lại thứ tự todo
- **Trigger:** Giữ và kéo todo item
- **Visual:** hiển thị placeholder khi đang kéo

### 4.3 Hiển thị thời gian

#### FR-10: Hiển thị thời gian tạo (relative time)
- **Mô tả:** Hiển thị thời gian tạo dưới dạng tương đối
- **Format:**

| Điều kiện | Hiển thị |
|---|---|
| < 1 phút | `"Just now"` |
| < 60 phút | `"X minutes ago"` |
| < 24 giờ | `"X hours ago"` |
| ≥ 1 ngày | `"X days ago"` |
| ≥ 7 ngày | `"dd/MM/yyyy"` |

#### FR-11: Hiển thị deadline
- **Mô tả:** Hiển thị dueDate dưới dạng dễ đọc
- **Format:**

| Điều kiện | Hiển thị |
|---|---|
| Hôm nay | `"Due today"` |
| Quá hạn | `"Overdue X days"` |
| Trong vòng 24h | `"Due in X hours"` |
| Trong vòng 7 ngày | `"Due in X days"` |
| Xa hơn | `"Due on dd/MM/yyyy"` |

#### FR-12: Highlight trạng thái deadline

| Status | Màu text | Màu nền badge |
|---|---|---|
| `normal` | mặc định | trong suốt |
| `warning` | `#f57f17` (cam) | `#fff9c4` |
| `overdue` | `#c62828` (đỏ) | `#ffebee` |
| `done` | `#9e9e9e` (xám) | trong suốt |

### 4.4 Tìm kiếm & Lọc

#### FR-13: Search
- **Mô tả:** Tìm kiếm todo theo text
- **Phạm vi tìm:** `title` của Note + `content` của Todo
- **Trigger:** Nhập vào ô search phía trên danh sách Note
- **Real-time:** lọc ngay khi gõ (debounce 300ms)
- **Highlight:** highlight từ khớp trong kết quả

#### FR-14: Filter
- **Mô tả:** Lọc todo theo trạng thái
- **Các filter:**
  - `All` — hiển thị tất cả
  - `Active` — chỉ todo chưa hoàn thành
  - `Completed` — chỉ todo đã hoàn thành
  - `Overdue` — chỉ todo quá hạn

---

## 5. Non-functional Requirements

### 5.1 Hiệu năng

| Tiêu chí | Yêu cầu |
|---|---|
| Thời gian load plasmoid | < 200ms |
| Scroll danh sách todo | Mượt với ≥ 100 items |
| Debounce search | 300ms |
| Autosave | Sau mỗi thao tác, delay 500ms |

### 5.2 Độ tin cậy

- Không mất dữ liệu khi restart KDE Plasma
- Autosave sau mỗi thao tác
- Không crash khi `dueDate` hoặc `createdAt` bị invalid

### 5.3 Usability

- Tạo todo trong ≤ 2 click
- UI tối giản, không rối mắt
- Hỗ trợ keyboard shortcut cơ bản (`Enter` để thêm, `Esc` để hủy)

### 5.4 Tương thích

- KDE Plasma 5.x và 6.x
- Qt 5.15+ / Qt 6.x
- Không yêu cầu thư viện ngoài

---

## 6. Data Model

### 6.1 Schema JSON đầy đủ

```json
{
  "notes": [
    {
      "id": "string (UUID)",
      "title": "string",
      "color": "string (hex color)",
      "createdAt": "string (ISO 8601)",
      "position": {
        "x": "number",
        "y": "number"
      },
      "size": {
        "width": "number",
        "height": "number"
      },
      "items": [
        {
          "id": "string (UUID)",
          "content": "string",
          "createdAt": "string (ISO 8601)",
          "dueDate": "string (ISO 8601)",
          "completed": "boolean",
          "order": "number"
        }
      ]
    }
  ],
  "settings": {
    "defaultColor": "#fff59d",
    "theme": "light | dark | auto"
  }
}
```

### 6.2 Validation Rules

| Field | Rule |
|---|---|
| `id` | UUID v4, unique toàn hệ thống |
| `title` | string, max 100 ký tự, không được rỗng |
| `color` | hex color hợp lệ, trong danh sách preset |
| `createdAt` | ISO 8601, không được null |
| `dueDate` | ISO 8601, nếu invalid → reset về `now` |
| `content` | string, max 500 ký tự, không được save nếu rỗng |
| `order` | integer ≥ 0, unique trong cùng note |

---

## 7. Business Logic

### 7.1 Tạo Note

```js
function createNote() {
  const now = new Date().toISOString()
  return {
    id: generateUUID(),
    title: "New Note",
    color: "#fff59d",
    createdAt: now,
    position: { x: 100, y: 100 },
    size: { width: 280, height: 380 },
    items: []
  }
}
```

### 7.2 Tạo Todo

```js
function createTodo(noteId) {
  const now = new Date().toISOString()
  return {
    id: generateUUID(),
    content: "",
    createdAt: now,
    dueDate: now,
    completed: false,
    order: getNextOrder(noteId)
  }
}
```

### 7.3 Xác định trạng thái deadline

```js
function getStatus(todo) {
  if (todo.completed) return "done"

  const now = new Date()
  const due = new Date(todo.dueDate)

  if (isNaN(due.getTime())) return "normal"  // invalid date fallback
  if (due < now) return "overdue"

  const diff = due - now
  if (diff < 86400000) return "warning"  // < 24 giờ

  return "normal"
}
```

### 7.4 Format thời gian tương đối

```js
function formatRelativeTime(isoString) {
  const now = new Date()
  const date = new Date(isoString)
  const diff = now - date  // ms

  if (diff < 60000)      return "Just now"
  if (diff < 3600000)    return `${Math.floor(diff / 60000)} minutes ago`
  if (diff < 86400000)   return `${Math.floor(diff / 3600000)} hours ago`
  if (diff < 604800000)  return `${Math.floor(diff / 86400000)} days ago`

  return date.toLocaleDateString("vi-VN")
}
```

### 7.5 Autosave

```js
// Debounced save — chỉ gọi sau 500ms kể từ thao tác cuối
let saveTimer = null
function scheduleSave(data) {
  clearTimeout(saveTimer)
  saveTimer = setTimeout(() => saveToStorage(data), 500)
}
```

### 7.6 Generate UUID

```js
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
    const r = Math.random() * 16 | 0
    return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16)
  })
}
```

---

## 8. UI Design

### 8.1 Layout tổng thể

```
+----------------------------------+
|  🔍 Search...        [+ New Note]|
+----------------------------------+
| [All] [Active] [Completed] [Over]|  ← Filter bar
+----------------------------------+
|                                  |
|  +----------------------------+  |
|  | 📝 Title Note    [🎨][✕]   |  |
|  |----------------------------|  |
|  | ☐ Todo item 1              |  |
|  |   Created 2h ago           |  |
|  |   ⚠ Due in 3 hours         |  |
|  |                            |  |
|  | ☑ Todo item 2 (done)       |  |  ← gạch ngang, xám
|  |   ✓ Completed              |  |
|  |                            |  |
|  | [+ Add item...]            |  |
|  +----------------------------+  |
|                                  |
+----------------------------------+
```

### 8.2 Todo Item Layout

```
[ checkbox ] [ content text              ] [ 🗑 ]
             Created: 2 hours ago
             Due: ⚠ Due in 3 hours
```

### 8.3 Color Palette cho Note

| Tên | Hex |
|---|---|
| Vàng (default) | `#fff59d` |
| Xanh lá | `#c8e6c9` |
| Xanh dương | `#bbdefb` |
| Hồng | `#f8bbd9` |
| Cam | `#ffe0b2` |
| Tím | `#e1bee7` |

---

## 9. Component Mapping (QML)

| Component QML | Vai trò | File đề xuất |
|---|---|---|
| `PlasmaCore.Dialog` | Container toàn bộ widget | `main.qml` |
| `Rectangle` | Container từng Note | `NoteCard.qml` |
| `ListView` | Danh sách todo trong Note | `TodoList.qml` |
| `TextField` | Nhập nội dung todo / search | `TodoInput.qml` |
| `CheckBox` | Toggle completed | trong `TodoItem.qml` |
| `DatePicker` | Chọn dueDate | `DatePickerDialog.qml` |
| `MouseArea` | Drag Note | trong `NoteCard.qml` |
| `ColorPicker` | Chọn màu Note | `ColorPickerPopup.qml` |
| `Text` | Hiển thị relative time / status | trong `TodoItem.qml` |

---

## 10. Storage Strategy

### Option 1 — `plasmoid.configuration` (Khuyến nghị cho MVP)

```qml
PlasmaCore.DataSource {
  // Lưu toàn bộ JSON vào plasmoid config key
}
property string notesJson: plasmoid.configuration.notesData
```

**Ưu điểm:** tích hợp sẵn KDE, tự persist khi restart  
**Nhược điểm:** giới hạn kích thước (~1MB)

### Option 2 — JSON file local (Khuyến nghị khi dữ liệu lớn)

```js
const filePath = StandardPaths.writableLocation(
  StandardPaths.AppDataLocation) + "/notes.json"
```

**Ưu điểm:** không giới hạn kích thước, dễ backup  
**Nhược điểm:** cần xử lý file I/O thủ công

### Quyết định

- **Phase 1 (MVP):** dùng Option 1
- **Phase 2+:** migrate sang Option 2 nếu vượt 500 notes

---

## 11. Error Handling

| Trường hợp | Xử lý |
|---|---|
| `dueDate` invalid | Reset về `now`, log warning |
| `content` rỗng khi save | Không cho save, hiển thị border đỏ |
| JSON parse lỗi khi load | Load `[]` rỗng, hiển thị thông báo nhẹ |
| Storage đầy | Thông báo user, không crash |
| Crash / kill đột ngột | Autosave đảm bảo dữ liệu gần nhất được lưu |
| UUID trùng | Regenerate, cực kỳ hiếm với UUID v4 |

---

## 12. Đánh giá & Bổ sung đề xuất

### 12.1 Những gì đã tốt ✅

- Data model rõ ràng, đủ các field cần thiết
- Business logic `getStatus()` chính xác
- Phân chia phase hợp lý (MVP → polish → advanced)
- FR bao phủ đủ CRUD cơ bản

### 12.2 Những gì còn thiếu — đề xuất bổ sung

#### Bổ sung vào Data Model
- `position` và `size` của Note (để lưu vị trí drag/resize)
- `order` trong Todo item (để hỗ trợ reorder)
- `settings` global (theme, defaultColor)

#### Bổ sung FR còn thiếu
- **FR-15: Duplicate Note** — copy toàn bộ Note sang một Note mới
- **FR-16: Minimize Note** — thu gọn Note chỉ còn header
- **FR-17: Pin Note** — ghim Note luôn nằm trên cùng
- **FR-18: Theme** — light / dark / follow system
- **FR-19: Keyboard shortcuts** — `Ctrl+N` tạo note, `Del` xóa todo đang chọn

#### Bổ sung Non-functional
- **Accessibility:** hỗ trợ keyboard navigation đầy đủ
- **Localization:** chuẩn bị i18n từ đầu (dù chỉ tiếng Anh trước)

---

## 13. Milestones

### Phase 1 — MVP (Tuần 1–2)
- [ ] Cấu trúc file QML cơ bản
- [ ] Tạo / xóa / sửa Note
- [ ] Thêm / xóa / sửa / complete Todo
- [ ] Lưu trữ với `plasmoid.configuration`
- [ ] Hiển thị relative time và deadline status

### Phase 2 — Enhanced (Tuần 3–4)
- [ ] Highlight deadline (warning / overdue)
- [ ] Search real-time
- [ ] Filter (All / Active / Completed / Overdue)
- [ ] Color picker cho Note
- [ ] Resize & Drag Note

### Phase 3 — Polish (Tuần 5–6)
- [ ] Drag & drop reorder Todo
- [ ] Minimize / Pin Note
- [ ] Keyboard shortcuts
- [ ] Animation & transition mượt
- [ ] Theme light/dark

### Phase 4 — Advanced (Tương lai)
- [ ] Sync cloud
- [ ] Markdown support
- [ ] Tag system
- [ ] Notification deadline
- [ ] Export/Import JSON

---

## 14. AI Agent Prompts

> Các prompt dưới đây được thiết kế để AI agent có thể generate code QML/JS chính xác, không bị lỗi context và không hallucinate về API KDE.

---

### 14.1 Master Context Prompt (Dùng đầu mỗi session)

```
Bạn là một KDE Plasma developer chuyên về QML và JavaScript.
Dự án: KDE Sticky Notes Plasmoid
Stack: QML + JS, KDE Plasma 5/6, Qt 5.15+
Không dùng thư viện ngoài.
Lưu trữ: plasmoid.configuration (key: notesData, kiểu string JSON)

Data model cốt lõi:
- Note: { id, title, color, createdAt, position{x,y}, size{width,height}, items[] }
- Todo: { id, content, createdAt, dueDate, completed, order }

Quy tắc khi generate code:
1. Luôn khai báo đầy đủ import QML
2. Không dùng deprecated API của Qt
3. Mọi hàm JS phải có error handling cho invalid date
4. Autosave sau mỗi mutation với debounce 500ms
5. Không hardcode giá trị, dùng hằng số hoặc config

Hãy xác nhận bạn đã hiểu trước khi tôi đưa task cụ thể.
```

---

### 14.2 Prompt: Khởi tạo cấu trúc project

```
Dựa trên master context đã cung cấp, hãy tạo cấu trúc thư mục và file cho plasmoid:

Yêu cầu:
- File metadata: metadata.desktop hoặc metadata.json (KDE Plasma 6)
- main.qml: entry point, load dữ liệu từ plasmoid.configuration
- NoteCard.qml: component một Note (drag, resize, header, todo list)
- TodoItem.qml: component một todo item (checkbox, text, datetime, delete)
- TodoInput.qml: input thêm todo mới
- ColorPickerPopup.qml: popup chọn màu Note
- DatePickerDialog.qml: dialog chọn dueDate
- logic.js: tất cả business logic (createNote, createTodo, getStatus, formatTime, generateUUID, save/load)

Với mỗi file hãy cung cấp:
1. Full code hoàn chỉnh
2. Giải thích ngắn mục đích từng file
3. Các signal/property public mà file expose ra ngoài

Bắt đầu với main.qml và logic.js trước.
```

---

### 14.3 Prompt: Component NoteCard

```
Tạo NoteCard.qml cho KDE Sticky Notes plasmoid.

Nhận vào props:
- noteData: object (Note model đầy đủ)
- onSave(updatedNote): signal khi có thay đổi
- onDelete(noteId): signal khi xóa
- onTodoAdd(noteId): signal khi thêm todo
- onTodoUpdate(noteId, todoId, changes): signal khi sửa todo
- onTodoDelete(noteId, todoId): signal khi xóa todo

Yêu cầu chức năng:
1. Header: hiển thị title (click để edit inline), color picker icon, close button
2. Body: ListView hiển thị danh sách TodoItem
3. Footer: "+ Add item" button / input
4. Drag: kéo bằng header, lưu position vào noteData
5. Resize: ResizeArea ở góc dưới phải
6. Confirm dialog khi xóa Note

Yêu cầu kỹ thuật:
- Dùng PlasmaComponents3 (không dùng QtQuick.Controls trực tiếp)
- Tất cả màu sắc lấy từ PlasmaCore.Theme
- Không dùng fixed pixel size, dùng units.gridUnit
- Khi title rỗng sau edit → tự reset về "New Note"

Output: full QML code với comment giải thích.
```

---

### 14.4 Prompt: Component TodoItem

```
Tạo TodoItem.qml cho KDE Sticky Notes plasmoid.

Nhận vào props:
- todoData: object { id, content, createdAt, dueDate, completed, order }
- onToggle(todoId): signal khi toggle completed
- onEdit(todoId, field, value): signal khi sửa content hoặc dueDate
- onDelete(todoId): signal khi xóa

Yêu cầu hiển thị:
1. Checkbox bên trái (toggle completed)
2. Content text: click để edit inline
   - Khi completed: gạch ngang, màu xám (#9e9e9e)
3. Dòng 2 - CreatedAt: hiển thị relative time (formatRelativeTime từ logic.js)
4. Dòng 3 - DueDate badge: màu theo status
   - normal: mặc định
   - warning: text cam, bg #fff9c4
   - overdue: text đỏ, bg #ffebee
   - done: text xám
5. Delete icon: chỉ hiện khi hover (opacity animation)
6. Click vào dueDate → mở DatePickerDialog

Yêu cầu kỹ thuật:
- Import logic.js: getStatus(), formatRelativeTime(), formatDueDate()
- Dùng Loader để lazy load DatePickerDialog
- DragHandler để hỗ trợ reorder (emit onReorder signal)
- Không dùng MouseArea deprecated, dùng TapHandler

Output: full QML code.
```

---

### 14.5 Prompt: Business Logic (logic.js)

```
Tạo logic.js cho KDE Sticky Notes plasmoid.
File này là pure JavaScript, được import vào QML qua: import "logic.js" as Logic

Implement đầy đủ các hàm sau:

// === ID Generation ===
function generateUUID() → string (UUID v4)

// === Note Operations ===
function createNote() → Note object với default values
function deleteNote(notes, noteId) → notes[] mới (immutable)
function updateNote(notes, noteId, changes) → notes[] mới

// === Todo Operations ===
function createTodo(noteId, notes) → Todo object
function deleteTodo(notes, noteId, todoId) → notes[] mới
function updateTodo(notes, noteId, todoId, changes) → notes[] mới
function reorderTodos(notes, noteId, fromIndex, toIndex) → notes[] mới

// === Status & Display ===
function getStatus(todo) → "normal" | "warning" | "overdue" | "done"
function formatRelativeTime(isoString) → string
function formatDueDate(isoString) → string ("Due today", "Overdue X days", v.v.)

// === Storage ===
function saveToConfig(plasmoid, notes) → void (debounced 500ms)
function loadFromConfig(plasmoid) → notes[] (với error handling)

// === Search & Filter ===
function searchNotes(notes, query) → notes[] (deep search title + content)
function filterTodos(todos, filterType) → todos[] 
  // filterType: "all" | "active" | "completed" | "overdue"

Yêu cầu:
- Tất cả hàm mutate phải immutable (không sửa trực tiếp object gốc)
- Error handling cho mọi date parsing
- JSDoc comment cho mỗi hàm
- Không dùng arrow function ở top-level (QML JS engine compatibility)

Output: full JS code.
```

---

### 14.6 Prompt: Storage & Persistence

```
Implement storage layer cho KDE Sticky Notes plasmoid dùng plasmoid.configuration.

Yêu cầu:
1. Trong package/contents/config/main.xml:
   - Khai báo config key "notesData" kiểu String, default ""
   - Khai báo config key "appSettings" kiểu String, default '{"defaultColor":"#fff59d","theme":"auto"}'

2. Trong logic.js - hàm saveToConfig(plasmoid, notes):
   - Serialize notes[] sang JSON string
   - Lưu vào plasmoid.configuration.notesData
   - Debounce 500ms
   - Try/catch: nếu lỗi → log lỗi, không crash

3. Trong logic.js - hàm loadFromConfig(plasmoid):
   - Đọc plasmoid.configuration.notesData
   - Parse JSON
   - Validate schema cơ bản (notes phải là array)
   - Nếu invalid → return []
   - Migrate data nếu thiếu field mới (backward compatibility)

4. Trong main.qml:
   - Load data khi Component.onCompleted
   - Connect signal onDataChanged → gọi scheduleSave

Output: code cho cả 3 file trên.
```

---

### 14.7 Prompt: Search & Filter

```
Implement chức năng Search và Filter cho KDE Sticky Notes plasmoid.

Context: đã có notes[] trong main.qml, đã có logic.js

Yêu cầu UI (trong main.qml hoặc SearchBar.qml):
1. TextField tìm kiếm:
   - Placeholder: "Search notes..."
   - Debounce 300ms sau khi gõ
   - Clear button (X) khi có text
2. Filter bar (4 nút): All | Active | Completed | Overdue
   - Nút đang active có highlight

Yêu cầu logic:
- Search: tìm trong title của Note VÀ content của tất cả Todo bên trong
- Kết quả search: trả về notes[] nhưng mỗi note chỉ chứa todos khớp
- Filter: áp dụng sau search
- Nếu search rỗng và filter = "all" → hiển thị tất cả

Yêu cầu kỹ thuật:
- Dùng Qt.binding hoặc computed property, không dùng imperative setProperty
- filteredNotes là property computed từ (notes, searchQuery, activeFilter)
- Khi notes thay đổi → filteredNotes tự cập nhật

Output: code SearchBar.qml + phần cập nhật trong main.qml + hàm trong logic.js.
```

---

### 14.8 Prompt: Fix lỗi & Debug

```
Tôi đang gặp lỗi sau trong KDE Sticky Notes plasmoid:

[DÁN LỖI VÀO ĐÂY]

Context của project:
- Stack: QML + JS, KDE Plasma 5/6, Qt 5.15+
- File bị lỗi: [tên file]
- Hành động trigger lỗi: [mô tả]

Code hiện tại:
[DÁN CODE VÀO ĐÂY]

Hãy:
1. Giải thích nguyên nhân lỗi
2. Cung cấp code đã fix
3. Giải thích tại sao fix đó đúng
4. Đề xuất cách tránh lỗi tương tự trong tương lai
```

---

*SRS này được tạo dựa trên đặc tả ban đầu của dự án KDE Sticky Notes Plasmoid, phiên bản 1.0.0*
