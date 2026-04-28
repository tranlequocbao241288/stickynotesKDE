// ============================================================
// logic.js — Business Logic cho KDE Sticky Notes
// ============================================================
//
// FILE NÀY LÀ GÌ?
// ────────────────
// Đây là "bộ não" của ứng dụng. Mọi thao tác với dữ liệu
// (tạo/sửa/xóa note, tạo/sửa/xóa todo, tìm kiếm, lọc...)
// đều được xử lý ở đây.
//
// TẠI SAO TÁCH RIÊNG?
// ────────────────────
// - UI (QML) chỉ lo hiển thị và bắt sự kiện
// - Logic (JS) lo xử lý dữ liệu
// - Dễ test, dễ sửa, không bị trộn lẫn
//
// CÁCH DÙNG TRONG QML:
// ────────────────────
//   import "../code/logic.js" as Logic
//   Logic.createNote()        // gọi hàm
//   Logic.PRESET_COLORS       // truy cập hằng số
//
// QUY TẮC QUAN TRỌNG ("IMMUTABLE UPDATE"):
// ─────────────────────────────────────────
// Khi sửa dữ liệu, KHÔNG BAO GIỜ sửa trực tiếp object gốc.
// Luôn tạo bản sao mới. Ví dụ:
//
//   SAI:  notes[0].title = "abc"        // sửa trực tiếp → bug
//   ĐÚNG: var newNotes = notes.map(...) // tạo mảng mới → an toàn
//
// Lý do: QML chỉ nhận biết thay đổi khi bạn gán lại property.
// Nếu sửa trực tiếp bên trong object, UI sẽ KHÔNG cập nhật.
//
// LƯU Ý VỀ QML JS ENGINE:
// ────────────────────────
// - Dùng "function" thay vì "=>" (arrow function) ở top-level
// - Dùng "var" thay vì "let/const" (QML JS engine cũ hơn)
// ============================================================


// ============================================================
// PHẦN 1: CONSTANTS — Các hằng số dùng xuyên suốt ứng dụng
// ============================================================
// Hằng số (constant) là giá trị KHÔNG BAO GIỜ thay đổi.
// Khai báo ở đầu file để dễ tìm và dễ sửa.
// Quy ước: viết HOA toàn bộ tên. Ví dụ: MAX_TITLE_LENGTH

/**
 * Trạng thái deadline của todo item.
 *
 * GIẢI THÍCH:
 * Mỗi todo có một deadline (dueDate). Dựa vào deadline,
 * ta xác định trạng thái hiện tại:
 *   - normal:  còn > 24 giờ → hiển thị bình thường
 *   - warning: còn < 24 giờ → hiển thị màu cam (cảnh báo)
 *   - overdue: đã quá hạn → hiển thị màu đỏ
 *   - done:    đã hoàn thành → hiển thị màu xám, gạch ngang
 */
var STATUS = {
    NORMAL: "normal",
    WARNING: "warning",
    OVERDUE: "overdue",
    DONE: "done"
};

/**
 * Màu nền badge cho mỗi trạng thái (dùng trong UI).
 *
 * GIẢI THÍCH:
 * Badge = nhãn nhỏ hiển thị trạng thái (ví dụ: "Overdue 3 days")
 * Mỗi trạng thái có màu chữ + màu nền riêng để dễ nhận biết.
 */
var STATUS_COLORS = {
    normal:  { text: "default",  background: "transparent" },
    warning: { text: "#f57f17",  background: "#fff9c4" },     // cam / vàng nhạt
    overdue: { text: "#c62828",  background: "#ffebee" },     // đỏ / đỏ nhạt
    done:    { text: "#9e9e9e",  background: "transparent" }  // xám
};

/**
 * Bảng màu preset cho Note — 6 màu pastel dịu mắt.
 *
 * GIẢI THÍCH ARRAY (MẢNG):
 * Array = danh sách có thứ tự. Truy cập bằng index (vị trí, bắt đầu từ 0).
 *   PRESET_COLORS[0] → "#fff59d" (vàng)
 *   PRESET_COLORS[3] → "#f8bbd0" (hồng)
 */
var PRESET_COLORS = [
    "#fff59d",  // Vàng (default)
    "#c8e6c9",  // Xanh lá
    "#bbdefb",  // Xanh dương
    "#f8bbd0",  // Hồng
    "#ffe0b2",  // Cam
    "#e1bee7"   // Tím
];

/** Màu mặc định khi tạo note mới */
var DEFAULT_COLOR = "#fff59d";

/**
 * Giới hạn số ký tự.
 *
 * GIẢI THÍCH:
 * Giới hạn để tránh user nhập quá dài gây vỡ UI hoặc quá tải storage.
 */
var MAX_TITLE_LENGTH = 100;
var MAX_CONTENT_LENGTH = 500;

/**
 * Thời gian debounce (mili giây).
 *
 * GIẢI THÍCH DEBOUNCE:
 * Ví dụ: User gõ "hello" → mỗi ký tự sẽ trigger save.
 * Nếu save ngay: save 5 lần (h, e, l, l, o) → lãng phí!
 * Với debounce 500ms: CHỈ save 1 lần (sau khi user ngừng gõ 0.5 giây)
 *
 * Cách hoạt động:
 *   1. User gõ "h" → bắt đầu đếm 500ms
 *   2. User gõ "e" (sau 100ms) → RESET đồng hồ, đếm lại 500ms
 *   3. User gõ "l" → RESET lại
 *   4. User gõ "l" → RESET lại
 *   5. User gõ "o" → RESET lại → đợi 500ms → SAVE!
 */
var SAVE_DEBOUNCE_MS = 500;
var SEARCH_DEBOUNCE_MS = 300;

/** Kích thước mặc định của note mới (pixel) */
var DEFAULT_NOTE_WIDTH = 280;
var DEFAULT_NOTE_HEIGHT = 380;
var DEFAULT_NOTE_X = 100;
var DEFAULT_NOTE_Y = 100;

/** Số mili giây trong các đơn vị thời gian (dùng cho tính toán) */
var MS_PER_MINUTE = 60000;         // 60 * 1000
var MS_PER_HOUR = 3600000;         // 60 * 60 * 1000
var MS_PER_DAY = 86400000;         // 24 * 60 * 60 * 1000
var MS_PER_WEEK = 604800000;       // 7 * 24 * 60 * 60 * 1000


// ============================================================
// PHẦN 2: ID GENERATION — Tạo ID duy nhất
// ============================================================
// Mỗi note và mỗi todo cần có một ID riêng biệt.
// ID giúp ta xác định chính xác note/todo nào cần sửa/xóa.
// Dùng UUID v4 — chuỗi 36 ký tự gần như không bao giờ trùng.
// Ví dụ: "a1b2c3d4-e5f6-4789-abcd-ef0123456789"

/**
 * Tạo UUID v4 (Universally Unique Identifier)
 *
 * GIẢI THÍCH CHI TIẾT:
 *
 * UUID v4 có dạng: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
 *   - x = ký tự hex ngẫu nhiên (0-9, a-f)
 *   - 4 = cố định, đánh dấu đây là version 4
 *   - y = ký tự hex bắt đầu bằng 8, 9, a, hoặc b
 *
 * GIẢI THÍCH CODE:
 *   'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
 *     .replace(/[xy]/g, function(c) { ... })
 *
 *   .replace(): tìm và thay thế văn bản
 *   /[xy]/g: "tìm tất cả chữ x và y trong chuỗi" (regex)
 *   function(c): hàm chạy cho MỖI chữ x/y tìm thấy
 *     c = ký tự hiện tại ('x' hoặc 'y')
 *
 *   Math.random() * 16 | 0: tạo số ngẫu nhiên 0-15
 *     Math.random() → số thập phân 0.0 → 0.999...
 *     * 16 → 0.0 → 15.999...
 *     | 0 → làm tròn xuống (bitwise OR) → 0 → 15
 *
 *   .toString(16): chuyển số thành ký tự hex
 *     10 → "a", 11 → "b", 15 → "f"
 *
 * @returns {string} UUID v4, ví dụ "a1b2c3d4-e5f6-4789-abcd-ef0123456789"
 */
function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0;
        var v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}


// ============================================================
// PHẦN 3: NOTE OPERATIONS — Thao tác với Note
// ============================================================
// Note = một khối ghi chú trên desktop.
// Mỗi Note chứa: id, title, color, createdAt, position, size, items[]

/**
 * Tạo một Note mới với giá trị mặc định.
 *
 * GIẢI THÍCH OBJECT (ĐỐI TƯỢNG):
 * Object = tập hợp các cặp key:value
 *   { key1: value1, key2: value2, ... }
 *
 * Ví dụ Note:
 *   {
 *     id: "abc-123",           // string: ID duy nhất
 *     title: "New Note",       // string: tiêu đề
 *     color: "#fff59d",        // string: mã màu hex
 *     createdAt: "2026-...",   // string: thời gian tạo (ISO 8601)
 *     position: {x: 100, y: 100},  // object lồng nhau: vị trí
 *     size: {width: 280, height: 380},  // object lồng nhau: kích thước
 *     items: []                // array: danh sách todo (ban đầu rỗng)
 *   }
 *
 * @returns {object} Note mới với giá trị mặc định
 */
function createNote() {
    var now = new Date().toISOString();
    return {
        id: generateUUID(),
        title: "New Note",
        color: DEFAULT_COLOR,
        createdAt: now,
        position: { x: DEFAULT_NOTE_X, y: DEFAULT_NOTE_Y },
        size: { width: DEFAULT_NOTE_WIDTH, height: DEFAULT_NOTE_HEIGHT },
        items: []
    };
}

/**
 * Xóa một Note khỏi mảng notes.
 *
 * GIẢI THÍCH .filter():
 * .filter() tạo mảng MỚI chỉ chứa các phần tử thỏa điều kiện.
 *
 * Ví dụ:
 *   [1, 2, 3, 4, 5].filter(function(n) { return n > 3; })
 *   → [4, 5]  (chỉ giữ lại số > 3)
 *
 * Trong trường hợp này:
 *   notes.filter(function(n) { return n.id !== noteId; })
 *   → giữ lại tất cả note NGOẠI TRỪ note có id = noteId
 *   → note bị "xóa" vì không còn trong mảng mới
 *
 * @param {array} notes - Mảng notes hiện tại
 * @param {string} noteId - ID của note cần xóa
 * @returns {array} Mảng notes MỚI (không chứa note bị xóa)
 */
function deleteNote(notes, noteId) {
    return notes.filter(function(note) {
        return note.id !== noteId;
    });
}

/**
 * Cập nhật một Note trong mảng notes.
 *
 * GIẢI THÍCH .map():
 * .map() tạo mảng MỚI bằng cách biến đổi TỪNG phần tử.
 *
 * Ví dụ:
 *   [1, 2, 3].map(function(n) { return n * 2; })
 *   → [2, 4, 6]
 *
 * GIẢI THÍCH Object.assign():
 * Object.assign(target, source1, source2, ...)
 * Sao chép tất cả property từ source vào target.
 *
 * Ví dụ:
 *   Object.assign({}, {a: 1, b: 2}, {b: 3, c: 4})
 *   → {a: 1, b: 3, c: 4}
 *   (b bị ghi đè bởi source sau)
 *
 * {} (object rỗng) làm target → tạo bản sao mới, không sửa gốc
 *
 * @param {array} notes - Mảng notes hiện tại
 * @param {string} noteId - ID của note cần sửa
 * @param {object} changes - Object chứa các field cần thay đổi
 *                           Ví dụ: { title: "New Title", color: "#c8e6c9" }
 * @returns {array} Mảng notes MỚI (note đã được cập nhật)
 */
function updateNote(notes, noteId, changes) {
    return notes.map(function(note) {
        if (note.id === noteId) {
            // Tạo bản sao note + ghi đè bằng changes
            return Object.assign({}, note, changes);
        }
        return note;  // Các note khác giữ nguyên
    });
}


// ============================================================
// PHẦN 4: TODO OPERATIONS — Thao tác với Todo
// ============================================================
// Todo = một task nhỏ nằm bên trong Note.
// Mỗi Todo chứa: id, content, createdAt, dueDate, completed, order

/**
 * Tạo một Todo mới và thêm vào Note.
 *
 * GIẢI THÍCH:
 * - Tìm Note theo noteId trong mảng notes
 * - Tính order = số todo hiện có (để todo mới luôn ở cuối)
 * - Tạo todo mới với giá trị mặc định
 *
 * GIẢI THÍCH "order":
 * order = thứ tự hiển thị. Todo đầu tiên order=0, thứ hai order=1, v.v.
 * Khi user kéo thả đổi vị trí, ta chỉ cần đổi order.
 *
 * @param {string} noteId - ID của note chứa todo mới
 * @param {array} notes - Mảng notes hiện tại (để tính order)
 * @returns {object} Todo mới
 */
function createTodo(noteId, notes) {
    var now = new Date().toISOString();
    var currentNote = null;

    // Tìm note theo noteId
    for (var i = 0; i < notes.length; i++) {
        if (notes[i].id === noteId) {
            currentNote = notes[i];
            break;  // Tìm thấy → dừng vòng lặp
        }
    }

    // Tính order: = số todo hiện có (nếu có 3 todo → todo mới order = 3)
    var nextOrder = currentNote && currentNote.items ? currentNote.items.length : 0;

    return {
        id: generateUUID(),
        content: "",            // Rỗng — user sẽ gõ nội dung sau
        createdAt: now,
        dueDate: now,           // Mặc định = hôm nay
        completed: false,
        order: nextOrder
    };
}

/**
 * Thêm một todo đã tạo vào note.
 *
 * GIẢI THÍCH concat():
 * .concat() nối thêm phần tử vào mảng, TRẢ VỀ MẢNG MỚI.
 *
 * Ví dụ:
 *   [1, 2].concat(3) → [1, 2, 3]   (mảng gốc [1,2] không bị sửa)
 *
 * So sánh với .push():
 *   [1, 2].push(3)   → sửa trực tiếp mảng gốc thành [1, 2, 3]
 *   → KHÔNG DÙNG push vì vi phạm nguyên tắc immutable!
 *
 * @param {array} notes - Mảng notes hiện tại
 * @param {string} noteId - ID note chứa todo
 * @param {object} newTodo - Todo mới cần thêm
 * @returns {array} Mảng notes MỚI
 */
function addTodoToNote(notes, noteId, newTodo) {
    console.log("logic.js: addTodoToNote called - noteId:", noteId, "todo:", newTodo.content);
    
    var result = notes.map(function(note) {
        if (note.id === noteId) {
            var updatedNote = Object.assign({}, note, {
                items: note.items.concat(newTodo)
            });
            console.log("logic.js: Added todo to note, new items count:", updatedNote.items.length);
            return updatedNote;
        }
        return note;
    });
    
    return result;
}

/**
 * Xóa một Todo khỏi Note.
 *
 * GIẢI THÍCH:
 * Dùng kết hợp .map() (duyệt notes) + .filter() (lọc todo).
 *   1. .map() duyệt qua tất cả notes
 *   2. Khi gặp note đúng noteId → dùng .filter() để bỏ todo có todoId
 *   3. Các note khác giữ nguyên
 *
 * @param {array} notes
 * @param {string} noteId
 * @param {string} todoId
 * @returns {array} Mảng notes MỚI
 */
function deleteTodo(notes, noteId, todoId) {
    return notes.map(function(note) {
        if (note.id === noteId) {
            return Object.assign({}, note, {
                items: note.items.filter(function(todo) {
                    return todo.id !== todoId;
                })
            });
        }
        return note;
    });
}

/**
 * Cập nhật một Todo trong Note.
 *
 * @param {array} notes
 * @param {string} noteId
 * @param {string} todoId
 * @param {object} changes - Ví dụ: { content: "Buy milk", completed: true }
 * @returns {array} Mảng notes MỚI
 */
function updateTodo(notes, noteId, todoId, changes) {
    return notes.map(function(note) {
        if (note.id === noteId) {
            return Object.assign({}, note, {
                items: note.items.map(function(todo) {
                    if (todo.id === todoId) {
                        return Object.assign({}, todo, changes);
                    }
                    return todo;
                })
            });
        }
        return note;
    });
}

/**
 * Đổi vị trí (reorder) todo trong note.
 *
 * GIẢI THÍCH THUẬT TOÁN:
 * Khi user kéo todo từ vị trí A sang vị trí B:
 *   1. Sao chép mảng items
 *   2. Lấy todo ra khỏi vị trí cũ (splice lần 1)
 *   3. Chèn todo vào vị trí mới (splice lần 2)
 *   4. Cập nhật lại field "order" cho tất cả todo
 *
 * GIẢI THÍCH .splice():
 * splice(index, deleteCount) → xóa deleteCount phần tử tại index, trả về phần tử đã xóa
 * splice(index, 0, item)     → chèn item vào index, không xóa gì
 *
 * Ví dụ: Mảng ["A", "B", "C", "D"], kéo "C" (index 2) lên trước "A" (index 0)
 *   1. removed = splice(2, 1) → xóa "C" → mảng = ["A", "B", "D"], removed = "C"
 *   2. splice(0, 0, "C")     → chèn "C" tại index 0 → mảng = ["C", "A", "B", "D"]
 *
 * @param {array} notes
 * @param {string} noteId
 * @param {number} fromIndex - Vị trí cũ
 * @param {number} toIndex - Vị trí mới
 * @returns {array} Mảng notes MỚI
 */
function reorderTodos(notes, noteId, fromIndex, toIndex) {
    return notes.map(function(note) {
        if (note.id === noteId) {
            // Sao chép mảng items (không sửa trực tiếp)
            var newItems = note.items.slice();  // .slice() tạo bản sao mảng

            // Lấy todo ra khỏi vị trí cũ
            var removed = newItems.splice(fromIndex, 1)[0];

            // Chèn vào vị trí mới
            newItems.splice(toIndex, 0, removed);

            // Cập nhật lại order cho tất cả items
            newItems = newItems.map(function(item, index) {
                return Object.assign({}, item, { order: index });
            });

            return Object.assign({}, note, { items: newItems });
        }
        return note;
    });
}


// ============================================================
// PHẦN 5: STATUS & DISPLAY — Xác định trạng thái + Hiển thị
// ============================================================

/**
 * Xác định trạng thái deadline của todo.
 *
 * GIẢI THÍCH LOGIC:
 *   1. Nếu todo đã hoàn thành → "done" (không quan tâm deadline)
 *   2. Parse dueDate thành Date object
 *   3. Nếu parse lỗi → "normal" (fallback an toàn)
 *   4. Nếu quá hạn (due < now) → "overdue"
 *   5. Nếu còn < 24 giờ → "warning"
 *   6. Còn lại → "normal"
 *
 * GIẢI THÍCH new Date():
 *   new Date("2026-04-24T12:00:00Z") → tạo object Date từ chuỗi ISO
 *   .getTime() → số mili giây từ 1/1/1970 (Unix timestamp)
 *   isNaN() → kiểm tra "Not a Number" (dùng khi parse date lỗi)
 *
 * @param {object} todo - Object todo có dueDate và completed
 * @returns {string} "normal" | "warning" | "overdue" | "done"
 */
function getStatus(todo) {
    // 1. Đã hoàn thành → done (ưu tiên cao nhất)
    if (todo.completed) {
        return STATUS.DONE;
    }

    // 2. Parse dueDate
    var now = new Date();
    var due = new Date(todo.dueDate);

    // 3. Nếu date invalid → fallback normal
    if (isNaN(due.getTime())) {
        return STATUS.NORMAL;
    }

    // 4. Quá hạn
    if (due < now) {
        return STATUS.OVERDUE;
    }

    // 5. Còn < 24 giờ → cảnh báo
    var diff = due - now;  // Khoảng cách tính bằng mili giây
    if (diff < MS_PER_DAY) {
        return STATUS.WARNING;
    }

    // 6. Còn lại → bình thường
    return STATUS.NORMAL;
}

/**
 * Format thời gian tạo dạng "X ... ago" (relative time).
 *
 * GIẢI THÍCH:
 * Thay vì hiện "2026-04-24T10:30:00Z" (khó đọc),
 * ta hiển thị "2 hours ago" (dễ hiểu hơn).
 *
 * Quy tắc (từ SRS):
 *   < 1 phút  → "Just now"
 *   < 60 phút → "X minutes ago"
 *   < 24 giờ  → "X hours ago"
 *   < 7 ngày  → "X days ago"
 *   ≥ 7 ngày  → "dd/MM/yyyy" (hiển thị ngày cụ thể)
 *
 * GIẢI THÍCH Math.floor():
 *   Math.floor(4.7) → 4 (làm tròn XUỐNG)
 *   Dùng để: 90 phút / 60 = 1.5 → Math.floor → 1 → "1 hours ago"
 *
 * @param {string} isoString - Thời gian định dạng ISO 8601
 * @returns {string} Thời gian tương đối
 */
function formatRelativeTime(isoString) {
    var now = new Date();
    var date = new Date(isoString);

    // Kiểm tra date có hợp lệ không
    if (isNaN(date.getTime())) {
        return "Unknown";
    }

    var diff = now - date;  // Khoảng cách (mili giây)

    // Nếu diff < 0 (thời gian trong tương lai) → hiện ngày cụ thể
    if (diff < 0) {
        return _formatDate(date);
    }

    if (diff < MS_PER_MINUTE) {
        return "Just now";
    }

    if (diff < MS_PER_HOUR) {
        var minutes = Math.floor(diff / MS_PER_MINUTE);
        return minutes + (minutes === 1 ? " minute ago" : " minutes ago");
    }

    if (diff < MS_PER_DAY) {
        var hours = Math.floor(diff / MS_PER_HOUR);
        return hours + (hours === 1 ? " hour ago" : " hours ago");
    }

    if (diff < MS_PER_WEEK) {
        var days = Math.floor(diff / MS_PER_DAY);
        return days + (days === 1 ? " day ago" : " days ago");
    }

    // ≥ 7 ngày → hiện ngày cụ thể
    return _formatDate(date);
}

/**
 * Format due date dạng dễ đọc.
 *
 * Quy tắc (từ SRS):
 *   Hôm nay        → "Due today"
 *   Quá hạn        → "Overdue X days"
 *   Trong vòng 24h → "Due in X hours"
 *   Trong vòng 7d  → "Due in X days"
 *   Xa hơn         → "Due on dd/MM/yyyy"
 *
 * @param {string} isoString - Thời gian deadline, ISO 8601
 * @returns {string} Deadline dạng dễ đọc
 */
function formatDueDate(isoString) {
    var now = new Date();
    var due = new Date(isoString);

    // Kiểm tra date hợp lệ
    if (isNaN(due.getTime())) {
        return "No deadline";
    }

    var diff = due - now;  // dương = tương lai, âm = quá hạn

    // Kiểm tra "hôm nay": cùng ngày/tháng/năm
    if (due.getFullYear() === now.getFullYear() &&
        due.getMonth() === now.getMonth() &&
        due.getDate() === now.getDate()) {
        return "Due today";
    }

    // Quá hạn (diff < 0)
    if (diff < 0) {
        var overdueDays = Math.ceil(Math.abs(diff) / MS_PER_DAY);
        return "Overdue " + overdueDays + (overdueDays === 1 ? " day" : " days");
    }

    // Trong vòng 24 giờ
    if (diff < MS_PER_DAY) {
        var hours = Math.ceil(diff / MS_PER_HOUR);
        return "Due in " + hours + (hours === 1 ? " hour" : " hours");
    }

    // Trong vòng 7 ngày
    if (diff < MS_PER_WEEK) {
        var days = Math.ceil(diff / MS_PER_DAY);
        return "Due in " + days + (days === 1 ? " day" : " days");
    }

    // Xa hơn → hiện ngày cụ thể
    return "Due on " + _formatDate(due);
}

/**
 * Helper: Format Date thành "dd/MM/yyyy"
 *
 * GIẢI THÍCH _UNDERSCORE:
 * Tên hàm bắt đầu bằng _ = quy ước "private" (nội bộ).
 * Chỉ dùng trong file này, không gọi từ bên ngoài.
 *
 * GIẢI THÍCH PADSTART:
 * "5".padStart(2, "0") → "05" (thêm "0" phía trước cho đủ 2 ký tự)
 * Dùng để: ngày 5 → "05", tháng 3 → "03"
 *
 * LƯU Ý: padStart có thể không có trong QML JS engine cũ,
 * nên ta tự viết hàm pad.
 */
function _formatDate(date) {
    var day = date.getDate();
    var month = date.getMonth() + 1;  // getMonth() trả 0-11
    var year = date.getFullYear();

    // Pad: "5" → "05"
    var dayStr = day < 10 ? "0" + day : "" + day;
    var monthStr = month < 10 ? "0" + month : "" + month;

    return dayStr + "/" + monthStr + "/" + year;
}


// ============================================================
// PHẦN 6: VALIDATION — Kiểm tra dữ liệu hợp lệ
// ============================================================
// Validation = kiểm tra dữ liệu trước khi lưu.
// Đảm bảo không có dữ liệu "rác" gây lỗi ứng dụng.

/**
 * Validate và sửa chữa một Note.
 *
 * GIẢI THÍCH:
 * Thay vì từ chối dữ liệu lỗi (throw error), ta SỬA CHỮA nó:
 *   - title rỗng → đặt lại "New Note"
 *   - title quá dài → cắt bớt
 *   - color không hợp lệ → dùng DEFAULT_COLOR
 *   - items không phải array → đặt []
 *   - createdAt invalid → dùng thời gian hiện tại
 *
 * Cách tiếp cận này gọi là "defensive programming" (lập trình phòng thủ):
 * → Ứng dụng KHÔNG BAO GIỜ crash, luôn có fallback.
 *
 * @param {object} note - Note cần validate
 * @returns {object} Note đã được sửa chữa (hoặc giữ nguyên nếu OK)
 */
function validateNote(note) {
    var result = Object.assign({}, note);

    // ID: nếu thiếu → tạo mới
    if (!result.id) {
        result.id = generateUUID();
    }

    // Title: rỗng → default, quá dài → cắt
    if (!result.title || result.title.trim() === "") {
        result.title = "New Note";
    } else if (result.title.length > MAX_TITLE_LENGTH) {
        result.title = result.title.substring(0, MAX_TITLE_LENGTH);
    }

    // Color: kiểm tra có trong preset không
    if (!result.color || PRESET_COLORS.indexOf(result.color) === -1) {
        result.color = DEFAULT_COLOR;
    }

    // CreatedAt: invalid → dùng now
    if (!result.createdAt || isNaN(new Date(result.createdAt).getTime())) {
        result.createdAt = new Date().toISOString();
    }

    // Position: thiếu → default
    if (!result.position || typeof result.position !== "object") {
        result.position = { x: DEFAULT_NOTE_X, y: DEFAULT_NOTE_Y };
    }

    // Size: thiếu → default
    if (!result.size || typeof result.size !== "object") {
        result.size = { width: DEFAULT_NOTE_WIDTH, height: DEFAULT_NOTE_HEIGHT };
    }

    // Items: không phải array → []
    if (!Array.isArray(result.items)) {
        result.items = [];
    } else {
        // Validate từng todo trong items
        result.items = result.items.map(function(todo) {
            return validateTodo(todo);
        });
    }

    return result;
}

/**
 * Validate và sửa chữa một Todo.
 *
 * @param {object} todo - Todo cần validate
 * @returns {object} Todo đã được sửa chữa
 */
function validateTodo(todo) {
    var result = Object.assign({}, todo);

    // ID
    if (!result.id) {
        result.id = generateUUID();
    }

    // Content: giữ nguyên dù rỗng (user sẽ nhập sau)
    if (typeof result.content !== "string") {
        result.content = "";
    } else if (result.content.length > MAX_CONTENT_LENGTH) {
        result.content = result.content.substring(0, MAX_CONTENT_LENGTH);
    }

    // CreatedAt
    if (!result.createdAt || isNaN(new Date(result.createdAt).getTime())) {
        result.createdAt = new Date().toISOString();
    }

    // DueDate: invalid → reset về now + cảnh báo
    if (!result.dueDate || isNaN(new Date(result.dueDate).getTime())) {
        console.warn("logic.js: Invalid dueDate detected, resetting to now");
        result.dueDate = new Date().toISOString();
    }

    // Completed: phải là boolean
    if (typeof result.completed !== "boolean") {
        result.completed = false;
    }

    // Order: phải là number >= 0
    if (typeof result.order !== "number" || result.order < 0) {
        result.order = 0;
    }

    return result;
}


// ============================================================
// PHẦN 7: PERSISTENCE — Lưu/Tải dữ liệu
// ============================================================
// Dữ liệu được lưu dưới dạng JSON string vào plasmoid.configuration.
// JSON (JavaScript Object Notation) = cách viết object/array thành chuỗi text.
//
// Ví dụ:
//   Object: {name: "John", age: 30}
//   JSON:   '{"name":"John","age":30}'
//
// JSON.stringify() = object → string (để lưu)
// JSON.parse()     = string → object (để đọc)
//
// LƯU Ý: QML JS engine không có setTimeout/clearTimeout,
// nên ta save trực tiếp thay vì debounce.

/**
 * Lên lịch save dữ liệu (debounce).
 *
 * LƯU Ý: QML JS engine không có setTimeout, nên ta save trực tiếp
 * thay vì debounce. Performance impact nhỏ vì save chỉ là ghi string.
 *
 * @param {object} plasmoidItem - PlasmoidItem QML (để truy cập configuration)
 * @param {array} notes - Mảng notes cần lưu
 */
function scheduleSave(plasmoidItem, notes) {
    // Save trực tiếp (không debounce vì QML JS không có setTimeout)
    _doSave(plasmoidItem, notes);
}

/**
 * Thật sự lưu dữ liệu vào config (hàm nội bộ).
 *
 * GIẢI THÍCH TRY/CATCH:
 * try { ... } catch (e) { ... }
 * → Thử chạy code trong try
 * → Nếu lỗi xảy ra → KHÔNG crash, chạy code trong catch thay vì
 * → e = object lỗi, chứa thông tin lỗi
 *
 * Ví dụ:
 *   try {
 *     JSON.parse("invalid json")  // → lỗi!
 *   } catch (e) {
 *     console.log("Lỗi rồi:", e.message)  // → bắt lỗi, không crash
 *   }
 */
function _doSave(plasmoidItem, notes) {
    try {
        var jsonString = JSON.stringify(notes);
        
        // Debug: Log dữ liệu trước khi save
        console.log("logic.js: Saving notes:", notes.length);
        for (var i = 0; i < notes.length; i++) {
            console.log("  Note", i, ":", notes[i].title, "- items:", notes[i].items ? notes[i].items.length : 0);
        }
        
        plasmoidItem.plasmoid.configuration.notesData = jsonString;
        console.log("logic.js: Saved " + notes.length + " notes to local config");
        console.log("logic.js: JSON length:", jsonString.length, "chars");
        
        // Đồng bộ lên Google Drive nếu được bật
        _scheduleDriveSync(plasmoidItem, notes);
    } catch (e) {
        console.error("logic.js: Failed to save notes:", e.message);
    }
}

/**
 * Tải dữ liệu từ config khi khởi động.
 *
 * @param {object} plasmoidItem - PlasmoidItem QML
 * @returns {array} Mảng notes (rỗng nếu chưa có dữ liệu hoặc lỗi)
 */
function loadFromConfig(plasmoidItem) {
    try {
        // Thử load từ Google Drive trước (nếu được bật)
        var driveNotes = _loadFromDrive(plasmoidItem);
        if (driveNotes !== null) {
            console.log("logic.js: Loaded " + driveNotes.length + " notes from Google Drive");
            return driveNotes;
        }

        // Fallback: load từ local config
        var jsonString = plasmoidItem.plasmoid.configuration.notesData;

        // Debug: Log dữ liệu đang load
        console.log("logic.js: Loading from local config, JSON length:", jsonString ? jsonString.length : 0);

        // Nếu chưa có dữ liệu → trả về mảng rỗng
        if (!jsonString || jsonString.trim() === "") {
            console.log("logic.js: No saved data, starting fresh");
            return [];
        }

        var notes = JSON.parse(jsonString);

        // Đảm bảo kết quả là mảng
        if (!Array.isArray(notes)) {
            console.warn("logic.js: Saved data is not an array, resetting");
            return [];
        }

        // Debug: Log số lượng notes và items
        console.log("logic.js: Parsed", notes.length, "notes from JSON");
        for (var i = 0; i < notes.length; i++) {
            console.log("  Note", i, ":", notes[i].title, "- items:", notes[i].items ? notes[i].items.length : 0);
        }

        // Validate từng note (migration + sửa lỗi dữ liệu cũ)
        notes = notes.map(function(note) {
            return validateNote(note);
        });

        console.log("logic.js: Loaded " + notes.length + " notes from local config");
        return notes;

    } catch (e) {
        // JSON parse lỗi → trả về mảng rỗng (không crash)
        console.error("logic.js: Failed to load notes:", e.message);
        return [];
    }
}


// ============================================================
// PHẦN 8: SEARCH & FILTER — Tìm kiếm và Lọc
// ============================================================

/**
 * Tìm kiếm notes theo từ khóa.
 *
 * GIẢI THÍCH:
 * Tìm trong cả title của Note VÀ content của mọi Todo bên trong.
 * Case insensitive = không phân biệt hoa/thường.
 *
 * GIẢI THÍCH .toLowerCase():
 *   "Hello World".toLowerCase() → "hello world"
 *   Dùng để so sánh không phân biệt hoa/thường:
 *     "Hello".toLowerCase().indexOf("hello") → 0 (tìm thấy)
 *
 * GIẢI THÍCH .indexOf():
 *   "Hello World".indexOf("World") → 6 (vị trí tìm thấy)
 *   "Hello World".indexOf("xyz")   → -1 (không tìm thấy)
 *
 * @param {array} notes - Mảng notes
 * @param {string} query - Từ khóa tìm kiếm
 * @returns {array} Mảng notes khớp (mỗi note chỉ chứa todos khớp)
 */
function searchNotes(notes, query) {
    // Nếu query rỗng → trả về tất cả
    if (!query || query.trim() === "") {
        return notes;
    }

    var lowerQuery = query.toLowerCase();

    return notes.filter(function(note) {
        // Kiểm tra title note có khớp không
        var titleMatch = note.title.toLowerCase().indexOf(lowerQuery) !== -1;

        // Kiểm tra content của bất kỳ todo nào có khớp không
        var todoMatch = note.items.some(function(todo) {
            return todo.content.toLowerCase().indexOf(lowerQuery) !== -1;
        });

        // Giữ lại note nếu title HOẶC bất kỳ todo nào khớp
        return titleMatch || todoMatch;
    });
}

/**
 * Lọc todos theo trạng thái.
 *
 * GIẢI THÍCH .some():
 *   [1, 2, 3].some(function(n) { return n > 2; }) → true
 *   Kiểm tra: "có BẤT KỲ phần tử nào thỏa điều kiện không?"
 *
 * @param {array} todos - Mảng todos
 * @param {string} filterType - "all" | "active" | "completed" | "overdue"
 * @returns {array} Mảng todos đã lọc
 */
function filterTodos(todos, filterType) {
    if (filterType === "all") {
        return todos;
    }

    return todos.filter(function(todo) {
        var status = getStatus(todo);

        switch (filterType) {
            case "active":
                // Active = chưa hoàn thành
                return !todo.completed;
            case "completed":
                // Completed = đã hoàn thành
                return todo.completed;
            case "overdue":
                // Overdue = quá hạn VÀ chưa hoàn thành
                return status === STATUS.OVERDUE;
            default:
                return true;
        }
    });
}

/**
 * Kết hợp Search + Filter: search trước, filter sau.
 *
 * GIẢI THÍCH:
 * 1. Tìm kiếm theo query → thu hẹp danh sách notes
 * 2. Với mỗi note tìm được → lọc todos theo filterType
 * 3. Trả về notes đã lọc (mỗi note chứa todos đã filter)
 *
 * @param {array} notes - Mảng notes gốc
 * @param {string} query - Từ khóa (rỗng = bỏ qua search)
 * @param {string} filterType - "all" | "active" | "completed" | "overdue"
 * @returns {array} Mảng notes đã search + filter
 */
function getFilteredNotes(notes, query, filterType) {
    // Bước 1: Search
    var searched = searchNotes(notes, query);

    // Bước 2: Filter todos trong mỗi note
    if (filterType === "all") {
        return searched;
    }

    return searched.map(function(note) {
        return Object.assign({}, note, {
            items: filterTodos(note.items, filterType)
        });
    });
}


// ============================================================
// PHẦN 9: GOOGLE DRIVE SYNC — Đồng bộ với Google Drive
// ============================================================
// Đồng bộ dữ liệu lên Google Drive để không mất khi restart máy.
// Yêu cầu: Google Drive đã được mount vào hệ thống (qua rclone, google-drive-ocamlfuse, v.v.)

/**
 * Lên lịch đồng bộ lên Google Drive (debounce).
 *
 * LƯU Ý: QML JS engine không có setTimeout, nên ta sync trực tiếp.
 *
 * @param {object} plasmoidItem - PlasmoidItem QML
 * @param {array} notes - Mảng notes cần sync
 */
function _scheduleDriveSync(plasmoidItem, notes) {
    // Kiểm tra xem có bật Google Drive sync không
    if (!plasmoidItem.plasmoid.configuration.enableGoogleDriveSync) {
        return;
    }

    // Sync trực tiếp (không debounce vì QML JS không có setTimeout)
    _doSyncToDrive(plasmoidItem, notes);
}

/**
 * Thật sự đồng bộ dữ liệu lên Google Drive.
 *
 * GIẢI THÍCH:
 * Sử dụng Qt.labs.platform.StandardPaths để lấy đường dẫn home.
 * Sau đó dùng executable để gọi lệnh shell ghi file.
 *
 * @param {object} plasmoidItem - PlasmoidItem QML
 * @param {array} notes - Mảng notes cần sync
 */
function _doSyncToDrive(plasmoidItem, notes) {
    try {
        var config = plasmoidItem.plasmoid.configuration;
        var drivePath = config.googleDrivePath;
        var fileName = config.googleDriveFileName;
        
        // Expand ~ thành đường dẫn home thực
        if (drivePath.indexOf("~") === 0) {
            // Trong QML, ta sẽ gọi hàm helper từ main.qml để expand path
            // Ở đây chỉ chuẩn bị dữ liệu
        }
        
        var jsonString = JSON.stringify(notes, null, 2);  // Pretty print với indent 2
        
        // Gọi hàm helper từ QML để ghi file
        // (QML sẽ implement hàm này vì JS thuần không có file I/O)
        if (plasmoidItem.syncToGoogleDrive) {
            plasmoidItem.syncToGoogleDrive(drivePath, fileName, jsonString);
            console.log("logic.js: Synced " + notes.length + " notes to Google Drive");
        } else {
            console.warn("logic.js: syncToGoogleDrive function not available in QML");
        }
    } catch (e) {
        console.error("logic.js: Failed to sync to Google Drive:", e.message);
    }
}

/**
 * Tải dữ liệu từ Google Drive khi khởi động.
 *
 * @param {object} plasmoidItem - PlasmoidItem QML
 * @returns {array|null} Mảng notes hoặc null nếu không load được
 */
function _loadFromDrive(plasmoidItem) {
    try {
        var config = plasmoidItem.plasmoid.configuration;
        
        // Kiểm tra xem có bật Google Drive sync không
        if (!config.enableGoogleDriveSync) {
            return null;
        }

        var drivePath = config.googleDrivePath;
        var fileName = config.googleDriveFileName;
        
        // Gọi hàm helper từ QML để đọc file
        if (plasmoidItem.loadFromGoogleDrive) {
            var jsonString = plasmoidItem.loadFromGoogleDrive(drivePath, fileName);
            
            if (!jsonString || jsonString.trim() === "") {
                return null;
            }
            
            var notes = JSON.parse(jsonString);
            
            if (!Array.isArray(notes)) {
                console.warn("logic.js: Google Drive data is not an array");
                return null;
            }
            
            // Validate từng note
            notes = notes.map(function(note) {
                return validateNote(note);
            });
            
            return notes;
        } else {
            console.warn("logic.js: loadFromGoogleDrive function not available in QML");
            return null;
        }
    } catch (e) {
        console.error("logic.js: Failed to load from Google Drive:", e.message);
        return null;
    }
}

/**
 * Kiểm tra xem Google Drive có sẵn sàng không.
 *
 * @param {object} plasmoidItem - PlasmoidItem QML
 * @returns {boolean} true nếu Drive sẵn sàng, false nếu không
 */
function checkGoogleDriveAvailable(plasmoidItem) {
    try {
        var config = plasmoidItem.plasmoid.configuration;
        var drivePath = config.googleDrivePath;
        
        if (plasmoidItem.checkDrivePathExists) {
            return plasmoidItem.checkDrivePathExists(drivePath);
        }
        
        return false;
    } catch (e) {
        console.error("logic.js: Failed to check Google Drive availability:", e.message);
        return false;
    }
}

/**
 * Đồng bộ thủ công (gọi từ UI).
 *
 * @param {object} plasmoidItem - PlasmoidItem QML
 * @param {array} notes - Mảng notes cần sync
 */
function manualSyncToDrive(plasmoidItem, notes) {
    console.log("logic.js: Manual sync triggered");
    _doSyncToDrive(plasmoidItem, notes);
}

/**
 * Tải lại từ Google Drive (gọi từ UI).
 *
 * @param {object} plasmoidItem - PlasmoidItem QML
 * @returns {array|null} Mảng notes hoặc null nếu không load được
 */
function manualLoadFromDrive(plasmoidItem) {
    console.log("logic.js: Manual load from Drive triggered");
    return _loadFromDrive(plasmoidItem);
}
