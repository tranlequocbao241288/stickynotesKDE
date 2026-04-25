#!/usr/bin/env node
// ============================================================
// test_logic.js — Script test cho logic.js
// ============================================================
// Chạy: node test_logic.js
//
// Script này sẽ gọi từng hàm trong logic.js và kiểm tra kết quả.
// Mỗi test sẽ in ✅ nếu pass hoặc ❌ nếu fail.

// Đọc file logic.js và eval
var fs = require("fs");
var code = fs.readFileSync(__dirname + "/package/contents/code/logic.js", "utf-8");

// Tạo môi trường giả lập cho console.warn
var originalWarn = console.warn;
console.warn = function() {}; // suppress warnings during tests

eval(code);

// Restore console.warn
console.warn = originalWarn;

var passed = 0;
var failed = 0;

function assert(condition, testName) {
    if (condition) {
        console.log("  ✅ " + testName);
        passed++;
    } else {
        console.log("  ❌ " + testName);
        failed++;
    }
}

// ─────────────────────────────────────────────
console.log("\n📦 PHẦN 1: TEST generateUUID()");
// ─────────────────────────────────────────────
var uuid1 = generateUUID();
var uuid2 = generateUUID();

assert(typeof uuid1 === "string", "UUID là string");
assert(uuid1.length === 36, "UUID dài 36 ký tự");
assert(uuid1 !== uuid2, "Hai UUID khác nhau");
assert(uuid1.split("-").length === 5, "UUID có 5 phần ngăn bởi dấu -");
assert(uuid1[14] === "4", "UUID v4 có ký tự '4' ở vị trí 14");

// ─────────────────────────────────────────────
console.log("\n📦 PHẦN 2: TEST createNote()");
// ─────────────────────────────────────────────
var note = createNote();

assert(note.id.length === 36, "Note có ID hợp lệ");
assert(note.title === "New Note", "Title mặc định = 'New Note'");
assert(note.color === "#fff59d", "Màu mặc định = vàng");
assert(Array.isArray(note.items), "items là mảng");
assert(note.items.length === 0, "items ban đầu rỗng");
assert(note.position.x === 100, "Position x mặc định = 100");
assert(note.size.width === 280, "Width mặc định = 280");
assert(!isNaN(new Date(note.createdAt).getTime()), "createdAt là ISO date hợp lệ");

// ─────────────────────────────────────────────
console.log("\n📦 PHẦN 3: TEST deleteNote()");
// ─────────────────────────────────────────────
var notes = [createNote(), createNote(), createNote()];
var idToDelete = notes[1].id;
var afterDelete = deleteNote(notes, idToDelete);

assert(afterDelete.length === 2, "Sau xóa còn 2 notes");
assert(notes.length === 3, "Mảng gốc KHÔNG bị sửa (immutable)");
assert(afterDelete.every(function(n) { return n.id !== idToDelete; }), "Note bị xóa không còn trong mảng");

// ─────────────────────────────────────────────
console.log("\n📦 PHẦN 4: TEST updateNote()");
// ─────────────────────────────────────────────
var notes2 = [createNote()];
var updatedNotes = updateNote(notes2, notes2[0].id, { title: "Updated!", color: "#c8e6c9" });

assert(updatedNotes[0].title === "Updated!", "Title được cập nhật");
assert(updatedNotes[0].color === "#c8e6c9", "Color được cập nhật");
assert(notes2[0].title === "New Note", "Mảng gốc KHÔNG bị sửa (immutable)");

// ─────────────────────────────────────────────
console.log("\n📦 PHẦN 5: TEST createTodo() + addTodoToNote()");
// ─────────────────────────────────────────────
var notes3 = [createNote()];
var todo1 = createTodo(notes3[0].id, notes3);
var notes3a = addTodoToNote(notes3, notes3[0].id, todo1);

assert(todo1.content === "", "Todo content mặc định rỗng");
assert(todo1.completed === false, "Todo mặc định chưa hoàn thành");
assert(todo1.order === 0, "Todo đầu tiên order = 0");
assert(notes3a[0].items.length === 1, "Note có 1 todo sau khi thêm");
assert(notes3[0].items.length === 0, "Mảng gốc KHÔNG bị sửa");

// Thêm todo thứ 2
var todo2 = createTodo(notes3a[0].id, notes3a);
assert(todo2.order === 1, "Todo thứ 2 order = 1");

// ─────────────────────────────────────────────
console.log("\n📦 PHẦN 6: TEST deleteTodo() + updateTodo()");
// ─────────────────────────────────────────────
var notes4 = addTodoToNote([createNote()], undefined, undefined);
var noteBase = createNote();
var todoA = createTodo(noteBase.id, [noteBase]);
todoA.content = "Task A";
var notesWithTodo = addTodoToNote([noteBase], noteBase.id, todoA);

var todoB = createTodo(noteBase.id, notesWithTodo);
todoB.content = "Task B";
notesWithTodo = addTodoToNote(notesWithTodo, noteBase.id, todoB);

assert(notesWithTodo[0].items.length === 2, "Có 2 todos");

// Update todo
var updatedTodos = updateTodo(notesWithTodo, noteBase.id, todoA.id, { content: "Task A updated", completed: true });
assert(updatedTodos[0].items[0].content === "Task A updated", "Todo content đã cập nhật");
assert(updatedTodos[0].items[0].completed === true, "Todo completed đã cập nhật");
assert(updatedTodos[0].items[1].content === "Task B", "Todo khác không bị ảnh hưởng");

// Delete todo
var afterDeleteTodo = deleteTodo(updatedTodos, noteBase.id, todoB.id);
assert(afterDeleteTodo[0].items.length === 1, "Sau xóa còn 1 todo");

// ─────────────────────────────────────────────
console.log("\n📦 PHẦN 7: TEST reorderTodos()");
// ─────────────────────────────────────────────
var noteReorder = createNote();
var t1 = createTodo(noteReorder.id, [noteReorder]); t1.content = "First";
var notesR = addTodoToNote([noteReorder], noteReorder.id, t1);
var t2 = createTodo(noteReorder.id, notesR); t2.content = "Second";
notesR = addTodoToNote(notesR, noteReorder.id, t2);
var t3 = createTodo(noteReorder.id, notesR); t3.content = "Third";
notesR = addTodoToNote(notesR, noteReorder.id, t3);

// Kéo "Third" (index 2) lên đầu (index 0)
var reordered = reorderTodos(notesR, noteReorder.id, 2, 0);
assert(reordered[0].items[0].content === "Third", "Third di chuyển lên đầu");
assert(reordered[0].items[1].content === "First", "First xuống vị trí 2");
assert(reordered[0].items[2].content === "Second", "Second xuống vị trí 3");
assert(reordered[0].items[0].order === 0, "Order được cập nhật: 0");
assert(reordered[0].items[1].order === 1, "Order được cập nhật: 1");
assert(reordered[0].items[2].order === 2, "Order được cập nhật: 2");

// ─────────────────────────────────────────────
console.log("\n📦 PHẦN 8: TEST getStatus()");
// ─────────────────────────────────────────────
var todoDone = { completed: true, dueDate: new Date().toISOString() };
assert(getStatus(todoDone) === "done", "Completed → done");

var todoOverdue = { completed: false, dueDate: "2020-01-01T00:00:00Z" };
assert(getStatus(todoOverdue) === "overdue", "Quá hạn → overdue");

var futureDate = new Date(Date.now() + 3600000); // +1 giờ
var todoWarning = { completed: false, dueDate: futureDate.toISOString() };
assert(getStatus(todoWarning) === "warning", "Còn < 24h → warning");

var farFuture = new Date(Date.now() + 86400000 * 10); // +10 ngày
var todoNormal = { completed: false, dueDate: farFuture.toISOString() };
assert(getStatus(todoNormal) === "normal", "Còn > 24h → normal");

var todoInvalidDate = { completed: false, dueDate: "not-a-date" };
assert(getStatus(todoInvalidDate) === "normal", "Date invalid → normal (fallback)");

// ─────────────────────────────────────────────
console.log("\n📦 PHẦN 9: TEST formatRelativeTime()");
// ─────────────────────────────────────────────
assert(formatRelativeTime(new Date().toISOString()) === "Just now", "Vừa tạo → Just now");
assert(formatRelativeTime("invalid") === "Unknown", "Date invalid → Unknown");

var fiveMinAgo = new Date(Date.now() - 5 * 60000).toISOString();
assert(formatRelativeTime(fiveMinAgo) === "5 minutes ago", "5 phút trước");

var threeHoursAgo = new Date(Date.now() - 3 * 3600000).toISOString();
assert(formatRelativeTime(threeHoursAgo) === "3 hours ago", "3 giờ trước");

var twoDaysAgo = new Date(Date.now() - 2 * 86400000).toISOString();
assert(formatRelativeTime(twoDaysAgo) === "2 days ago", "2 ngày trước");

// ─────────────────────────────────────────────
console.log("\n📦 PHẦN 10: TEST formatDueDate()");
// ─────────────────────────────────────────────
assert(formatDueDate("invalid-date") === "No deadline", "Date invalid → No deadline");

var overdueTodo = new Date(Date.now() - 3 * 86400000).toISOString();
var overdueResult = formatDueDate(overdueTodo);
assert(overdueResult.indexOf("Overdue") === 0, "Quá hạn → bắt đầu bằng 'Overdue'");

// ─────────────────────────────────────────────
console.log("\n📦 PHẦN 11: TEST validateNote() + validateTodo()");
// ─────────────────────────────────────────────
var badNote = { title: "", color: "invalid", items: "not-array" };
var fixed = validateNote(badNote);
assert(fixed.title === "New Note", "Title rỗng → 'New Note'");
assert(fixed.color === "#fff59d", "Color invalid → default");
assert(Array.isArray(fixed.items), "Items không phải array → []");
assert(fixed.id.length === 36, "Thiếu id → tạo mới");

var badTodo = { dueDate: "broken", completed: "yes" };
var fixedTodo = validateTodo(badTodo);
assert(!isNaN(new Date(fixedTodo.dueDate).getTime()), "DueDate invalid → reset về now");
assert(fixedTodo.completed === false, "Completed 'yes' → false");

// ─────────────────────────────────────────────
console.log("\n📦 PHẦN 12: TEST searchNotes()");
// ─────────────────────────────────────────────
var searchNotes1 = createNote(); searchNotes1.title = "Shopping List";
var searchTodo = createTodo(searchNotes1.id, [searchNotes1]);
searchTodo.content = "Buy milk";
searchNotes1.items = [searchTodo];

var searchNotes2 = createNote(); searchNotes2.title = "Work Tasks";
var searchTodo2 = createTodo(searchNotes2.id, [searchNotes2]);
searchTodo2.content = "Finish report";
searchNotes2.items = [searchTodo2];

var allNotes = [searchNotes1, searchNotes2];

assert(searchNotes(allNotes, "").length === 2, "Query rỗng → trả tất cả");
assert(searchNotes(allNotes, "shop").length === 1, "Tìm 'shop' → 1 kết quả");
assert(searchNotes(allNotes, "milk").length === 1, "Tìm 'milk' (trong todo) → 1 kết quả");
assert(searchNotes(allNotes, "SHOP").length === 1, "Case insensitive");
assert(searchNotes(allNotes, "xyz").length === 0, "Không tìm thấy → 0 kết quả");

// ─────────────────────────────────────────────
console.log("\n📦 PHẦN 13: TEST filterTodos()");
// ─────────────────────────────────────────────
var todos = [
    { id: "1", content: "Active", completed: false, dueDate: farFuture.toISOString() },
    { id: "2", content: "Done", completed: true, dueDate: new Date().toISOString() },
    { id: "3", content: "Overdue", completed: false, dueDate: "2020-01-01T00:00:00Z" }
];

assert(filterTodos(todos, "all").length === 3, "Filter 'all' → 3");
assert(filterTodos(todos, "active").length === 2, "Filter 'active' → 2 (chưa hoàn thành)");
assert(filterTodos(todos, "completed").length === 1, "Filter 'completed' → 1");
assert(filterTodos(todos, "overdue").length === 1, "Filter 'overdue' → 1");

// ─────────────────────────────────────────────
console.log("\n══════════════════════════════════════");
console.log("📊 KẾT QUẢ: " + passed + " passed, " + failed + " failed");
console.log("══════════════════════════════════════\n");

if (failed > 0) {
    process.exit(1);
}
