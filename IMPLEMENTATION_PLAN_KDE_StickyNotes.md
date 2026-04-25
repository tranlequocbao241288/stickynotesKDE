# Implementation Plan chi tiết - KDE Sticky Notes Plasmoid

Phiên bản: 1.0.0  
Ngày lập kế hoạch: 2026-04-24  
Nguồn yêu cầu: SRS v1.0.0

---

## 1) Mục tiêu triển khai

Mục tiêu của kế hoạch này là chuyển toàn bộ yêu cầu trong SRS thành các bước triển khai cụ thể, có thứ tự, có tiêu chí nghiệm thu rõ ràng, để có thể:

- Ship được bản MVP ổn định đúng phạm vi
- Không sót requirement quan trọng (FR, NFR, Data, Error Handling)
- Giảm rủi ro khi phát triển QML/JS trên KDE Plasma

Kết quả cuối cùng kỳ vọng:

- Một plasmoid hoạt động ổn trên KDE Plasma 5.x/6.x
- Dữ liệu sticky notes được lưu bền vững sau restart Plasma
- Đủ bộ chức năng FR-01 tới FR-14 của SRS

---

## 2) Giải thích nhanh các thuật ngữ dùng trong kế hoạch

- Debounce: Trì hoãn thực thi một hàm trong một khoảng thời gian ngắn, nếu có thao tác mới thì reset đồng hồ. Dùng để giảm số lần save/search.
- Immutable update: Cập nhật dữ liệu bằng cách tạo object/array mới, không sửa trực tiếp object cũ. Giúp state dễ kiểm soát và ít bug.
- Acceptance Criteria: Điều kiện chấp nhận. Chỉ khi pass hết các điều kiện thì task/feature mới được xem là hoàn thành.
- DoD (Definition of Done): Bộ tiêu chuẩn hoàn tất cho mỗi hạng mục.

---

## 3) Kiến trúc kỹ thuật đề xuất

## 3.1 Cấu trúc thư mục

```text
sticknotesKDE/
├── SRS_KDE_StickyNotes.md
├── IMPLEMENTATION_PLAN_KDE_StickyNotes.md
└── package/
    └── contents/
        ├── ui/
        │   ├── main.qml
        │   ├── NoteCard.qml
        │   ├── TodoItem.qml
        │   ├── TodoInput.qml
        │   ├── ColorPickerPopup.qml
        │   └── DatePickerDialog.qml
        ├── code/
        │   └── logic.js
        └── config/
            └── main.xml
```

## 3.2 Phân chia trách nhiệm

- UI Layer (QML): Render giao diện, bắt sự kiện người dùng, phát signal.
- Logic Layer (logic.js): Tạo/cập nhật/xóa dữ liệu, tính status deadline, format thời gian, search/filter, save/load.
- Storage Layer: Dùng plasmoid.configuration cho MVP.

Nguyên tắc:

- UI không chứa business logic phức tạp.
- Mọi mutation dữ liệu đi qua logic.js.
- Save qua debounce 500ms để cân bằng hiệu năng và độ an toàn dữ liệu.

---

## 4) Ma trận traceability (SRS -> công việc)

| Nhóm | Requirement | Hạng mục triển khai chính |
|---|---|---|
| Note | FR-01, FR-02, FR-03, FR-04 | main.qml, NoteCard.qml, logic.js |
| Todo | FR-05, FR-06, FR-07, FR-08, FR-09 | TodoItem.qml, TodoInput.qml, logic.js |
| Time | FR-10, FR-11, FR-12 | logic.js + binding trong TodoItem.qml |
| Search/Filter | FR-13, FR-14 | Search area trong main.qml + logic.js |
| NFR | 5.1, 5.2, 5.3, 5.4 | debounce, autosave, validation, UX keyboard |
| Data | Mục 6 | schema + validator/migration trong logic.js |
| Error | Mục 11 | try/catch parse, fallback date, non-crash behavior |

---

## 5) Work Breakdown Structure (WBS) chi tiết

## Epic E0 - Khởi tạo nền tảng dự án

Mục tiêu: Tạo bộ khung plasmoid chạy được.

Tasks:

1. Tạo metadata và entrypoint
- Tạo metadata cho Plasma 5/6
- Tạo main.qml tối thiểu hiển thị khung widget
- Verify plasmoid load được

2. Tạo skeleton component
- Tạo NoteCard.qml, TodoItem.qml, TodoInput.qml, ColorPickerPopup.qml, DatePickerDialog.qml, logic.js
- Export đủ property/signal cơ bản

Acceptance Criteria:

- Plasmoid load không lỗi QML runtime
- Cấu trúc file đúng chuẩn package/contents

Estimate: 1.5 ngày

---

## Epic E1 - Data model + business logic lõi

Mục tiêu: Chuẩn hóa schema và toàn bộ hàm xử lý dữ liệu.

Tasks:

1. Implement constants và helper
- STATUS: normal/warning/overdue/done
- Preset colors
- Giới hạn title/content length

2. Implement ID generation
- generateUUID() theo UUID v4
- Kiểm tra trùng ID trong mảng hiện tại (fallback regenerate)

3. Implement Note APIs
- createNote()
- deleteNote(notes, noteId)
- updateNote(notes, noteId, changes)

4. Implement Todo APIs
- createTodo(noteId, notes)
- deleteTodo(notes, noteId, todoId)
- updateTodo(notes, noteId, todoId, changes)
- reorderTodos(notes, noteId, fromIndex, toIndex)

5. Implement date/status/display APIs
- getStatus(todo)
- formatRelativeTime(iso)
- formatDueDate(iso)

6. Validation + migration
- validateNote(), validateTodo()
- sanitize invalid date -> now
- fill field thiếu cho dữ liệu cũ

Acceptance Criteria:

- Tất cả hàm mutation trả dữ liệu mới (immutable)
- Không throw khi gặp date invalid
- Tạo note/todo đúng default theo SRS

Estimate: 2.5 ngày

---

## Epic E2 - Persistence (Storage)

Mục tiêu: Dữ liệu không mất sau restart Plasma.

Tasks:

1. Cấu hình key lưu trữ
- main.xml có notesData (string)
- main.xml có appSettings (string)

2. Load dữ liệu khi startup
- Component.onCompleted gọi loadFromConfig()
- Nếu parse lỗi -> []

3. Save dữ liệu an toàn
- schedule save debounce 500ms
- try/catch khi stringify và ghi config

4. Cơ chế autosave
- Sau mỗi mutation Note/Todo, kích hoạt schedule save

Acceptance Criteria:

- Restart Plasma vẫn giữ đúng dữ liệu
- Không crash khi JSON trong config bị hỏng

Estimate: 1.5 ngày

---

## Epic E3 - UI quản lý Note (FR-01..FR-04)

Mục tiêu: User thao tác note đầy đủ.

Tasks:

1. Tạo note mới
- Nút + New Note
- Sau tạo: auto focus title để edit

2. Chỉnh sửa note
- Inline edit title
- Validate title rỗng -> reset New Note
- Color picker tối thiểu 6 màu preset

3. Xóa note
- Icon delete ở header
- Confirm dialog đúng message SRS

4. Drag/Resize note
- Kéo note qua header
- Resize góc/cạnh
- Cập nhật position/size + autosave

Acceptance Criteria:

- Pass FR-01, FR-02, FR-03, FR-04
- position/size lưu đúng sau restart

Estimate: 3 ngày

---

## Epic E4 - UI quản lý Todo (FR-05..FR-09)

Mục tiêu: User thao tác todo đầy đủ.

Tasks:

1. Thêm todo
- Enter hoặc + Add item
- Không save nếu content rỗng
- Focus input ngay khi tạo

2. Sửa todo
- Inline edit content
- Click dueDate mở DatePicker

3. Toggle completed
- Checkbox đổi trạng thái
- Text strikethrough + màu xám khi done

4. Xóa todo
- Icon xóa hiện khi hover
- Không confirm

5. Reorder todo
- Drag and drop
- Placeholder khi kéo
- Cập nhật order ổn định

Acceptance Criteria:

- Pass FR-05 -> FR-09
- Thao tác nhanh, không lag với 100 items

Estimate: 3.5 ngày

---

## Epic E5 - Time display + deadline highlight (FR-10..FR-12)

Mục tiêu: Hiển thị đúng ngữ cảnh thời gian và trạng thái deadline.

Tasks:

1. Relative time cho createdAt
- Just now / X minutes / X hours / X days / dd/MM/yyyy

2. Due date text
- Due today / Overdue X days / Due in X hours / Due in X days / Due on dd/MM/yyyy

3. Badge theo status
- warning: cam + nền vàng nhạt
- overdue: đỏ + nền đỏ nhạt
- done: xám

Acceptance Criteria:

- Pass FR-10, FR-11, FR-12
- Không vỡ UI khi dueDate invalid

Estimate: 1.5 ngày

---

## Epic E6 - Search + Filter (FR-13..FR-14)

Mục tiêu: Tìm kiếm và lọc thời gian thực.

Tasks:

1. Search input
- Debounce 300ms
- Search cả title note + content todo
- Highlight keyword khớp

2. Filter buttons
- All / Active / Completed / Overdue
- Trạng thái active rõ ràng

3. Kết hợp Search + Filter
- Search trước, filter sau
- filteredNotes cập nhật tự động khi state đổi

Acceptance Criteria:

- Pass FR-13, FR-14
- Input rỗng + filter all -> hiển thị toàn bộ

Estimate: 2 ngày

---

## Epic E7 - NFR, UX, hardening

Mục tiêu: Nâng độ ổn định và trải nghiệm.

Tasks:

1. Hiệu năng
- Kiểm tra load < 200ms (mức mục tiêu)
- Kiểm tra scroll mượt với dataset 100+ todo
- Tránh binding thừa gây re-render lớn

2. Usability
- Keyboard: Enter thêm, Esc hủy
- Focus handling rõ ràng

3. Tương thích
- Smoke test Plasma 5.x và 6.x
- Kiểm tra import tương thích Qt 5.15 / Qt 6

4. Error handling
- JSON parse fail fallback []
- invalid dueDate fallback now + warning log
- không crash khi storage đầy

Acceptance Criteria:

- Không crash trong các test tình huống lỗi
- Keyboard flow hoạt động như SRS

Estimate: 2 ngày

---

## Epic E8 - Release readiness

Mục tiêu: Chốt bản phát hành ổn định.

Tasks:

1. Dọn cảnh báo QML/JS
2. Review consistency UI
3. Viết README ngắn: cài đặt, tính năng, giới hạn
4. Chuẩn bị checklist release

Acceptance Criteria:

- Không lỗi nghiêm trọng P0/P1
- Có tài liệu chạy/cài đặt cơ bản

Estimate: 1 ngày

---

## 6) Lịch triển khai đề xuất (6 tuần)

| Tuần | Trọng tâm | Deliverables |
|---|---|---|
| 1 | E0 + E1 (nền tảng + logic) | Khung plasmoid, logic.js đầy đủ CRUD + time |
| 2 | E2 + E3 (storage + note UI) | Note CRUD + drag/resize + autosave |
| 3 | E4 (todo UI full) | Todo CRUD + due date + reorder cơ bản |
| 4 | E5 + E6 (time + search/filter) | Deadline highlight + search/filter realtime |
| 5 | E7 (NFR + hardening) | Tối ưu performance, keyboard flow, error scenarios |
| 6 | E8 (release) | Bản release candidate + checklist nghiệm thu |

Tổng effort ước tính: 18.5 đến 21 ngày công thực thi.

---

## 7) Kế hoạch kiểm thử chi tiết

## 7.1 Unit test logic.js (khuyến nghị)

Nhóm test bắt buộc:

1. Note operations
- createNote tạo đúng field mặc định
- updateNote immutable
- deleteNote xóa đúng id

2. Todo operations
- createTodo order tăng đúng
- updateTodo giữ field không liên quan
- reorderTodos không mất item

3. Time/status
- getStatus cho đủ 4 trạng thái
- formatRelativeTime/formatDueDate với mốc biên
- invalid date không throw

4. Search/filter
- search title + content
- filter active/completed/overdue đúng logic

## 7.2 Manual test matrix theo UC

- UC-01: Tạo note mới, focus title
- UC-02: Xóa note, confirm dialog xuất hiện
- UC-03: Sửa title/màu, autosave
- UC-04: Drag/resize rồi restart kiểm tra persist
- UC-05..UC-09: Full CRUD todo + reorder
- UC-11..UC-12: Search/filter realtime

## 7.3 Test lỗi và recovery

- Config chứa JSON hỏng
- dueDate invalid
- content rỗng khi save
- Dữ liệu lớn (100+ todo)

---

## 8) Definition of Done (DoD)

Một hạng mục chỉ được đánh dấu Done khi đạt đủ:

1. Đúng functional requirement tương ứng (có bằng chứng test)
2. Không có lỗi P0/P1 liên quan hạng mục đó
3. Có xử lý lỗi/fallback cho input xấu
4. Có autosave nếu hạng mục có thay đổi dữ liệu
5. Qua review code cơ bản (readability, không duplicate logic lớn)

---

## 9) Rủi ro chính và cách giảm thiểu

1. Rủi ro: Binding QML phức tạp gây lag
- Giảm thiểu: tách component nhỏ, tránh recompute toàn list

2. Rủi ro: Dữ liệu cũ thiếu field gây crash
- Giảm thiểu: migration + default filler trong loadFromConfig

3. Rủi ro: Drag/resize/reorder xung đột gesture
- Giảm thiểu: phân rõ vùng tương tác (header kéo, body scroll, handle resize)

4. Rủi ro: Date/time edge case theo locale/timezone
- Giảm thiểu: xử lý trên ISO + normalize tại logic.js

---

## 10) Checklist nghiệm thu theo FR

- FR-01: Tao note moi
- FR-02: Xoa note co confirm
- FR-03: Sua title + color, autosave
- FR-04: Drag/resize + persist
- FR-05: Them todo, chan content rong
- FR-06: Sua content/dueDate
- FR-07: Toggle completed + style done
- FR-08: Xoa todo khong confirm
- FR-09: Reorder todo
- FR-10: Relative createdAt
- FR-11: Due date text theo ngữ cảnh
- FR-12: Highlight status
- FR-13: Search realtime debounce 300ms
- FR-14: Filter all/active/completed/overdue

---

## 11) Gợi ý thứ tự commit

1. chore: scaffold plasmoid structure + metadata
2. feat: add core logic.js for note/todo CRUD
3. feat: add persistence via plasmoid.configuration
4. feat: implement note card CRUD + color + confirm delete
5. feat: implement todo item/input + complete/delete/edit
6. feat: add deadline status and time formatting
7. feat: add search and filter with debounce
8. feat: add drag resize reorder interactions
9. fix: harden error handling and migration paths
10. chore: docs and release checklist

---

## 12) Next step thực thi ngay

Bắt đầu theo thứ tự:

1. Dựng E0 (khung project plasmoid chạy được)
2. Hoàn tất logic.js (E1) trước khi làm UI sâu
3. Tích hợp persistence (E2)
4. Sau đó mới build Note UI rồi Todo UI

Lý do: Làm chắc nền logic + storage sớm sẽ giảm bug dây chuyền ở các phase UI sau.
