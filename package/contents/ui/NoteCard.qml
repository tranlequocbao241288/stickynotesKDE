/*
 * NoteCard.qml — Component hiển thị MỘT note (sticky note)
 *
 * GIẢI THÍCH:
 * ──────────
 * Mỗi NoteCard = 1 sticky note trên giao diện, gồm:
 *   - Header: title + nút color + nút xóa
 *   - Body: danh sách todo items
 *   - Footer: input thêm todo mới
 *
 * KHÁI NIỆM MỚI — "required property":
 *   - Khi dùng NoteCard, BẮT BUỘC phải truyền giá trị cho property này
 *   - Giống parameter bắt buộc của function
 *   - Ví dụ khi dùng: NoteCard { noteData: {...} }
 *
 * KHÁI NIỆM MỚI — "signal":
 *   - Signal là "sự kiện" mà component phát ra
 *   - Component cha lắng nghe signal này để xử lý
 *   - Giống event trong JavaScript: onClick, onChange...
 *   - Ví dụ: khi user xóa note → NoteCard phát signal noteDeleted
 *            → main.qml lắng nghe và xóa note khỏi mảng
 *
 * Skeleton: chỉ khai báo cấu trúc, chưa có giao diện thật.
 * Sẽ hoàn thiện ở Epic E3.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../code/logic.js" as Logic

// Item: component cơ bản nhất trong QML (container vô hình)
Item {
    id: noteCard

    // ─── PROPERTIES (Thuộc tính) ─────────────────────────
    // Qt 6 FIX: Khi delegate có "required property", QML TẮT việc tự động
    // inject modelData/index. Phải khai báo ĐÚNG TÊN role của model.
    required property var modelData     // Qt 6 auto-inject từ Repeater model
    required property int index         // Qt 6 auto-inject từ Repeater model

    // Alias: đặt tên dễ hiểu cho code bên trong component
    property var noteData: modelData    // Object note: {id, title, color, items[], ...}
    property int noteIndex: index       // Vị trí trong mảng notes (0, 1, 2...)

    // ─── SIGNALS (Sự kiện) ───────────────────────────────
    // Component cha sẽ lắng nghe các signal này
    signal noteUpdated(var updatedNote)        // Khi note bị sửa (title, color, position...)
    signal noteDeleted(string noteId)          // Khi user muốn xóa note
    signal todoAdded(string noteId, string content)            // Khi user thêm todo mới
    signal todoUpdated(string noteId, string todoId, var changes)   // Khi todo bị sửa
    signal todoDeleted(string noteId, string todoId)                // Khi todo bị xóa
    signal todoToggled(string noteId, string todoId)                // Khi toggle completed

    // ─── KÍCH THƯỚC ──────────────────────────────────────
    width: noteData && noteData.size ? noteData.size.width : 280
    height: noteData && noteData.size ? noteData.size.height : 380

    // ─── TRẠNG THÁI KÉO ─────────────────────────────────
    // Property này cho phép main.qml biết note đang được kéo
    // để KHÔNG sync position từ data (tránh snap về vị trí cũ)
    property bool dragging: dragHandler.active

    // DragHandler được đặt ở cấp cao nhất để bao phủ TOÀN BỘ thẻ Note
    // Điều này ngăn người dùng vô tình cuộn (pan) Flickable nền khi cố gắng kéo thẻ Note
    DragHandler {
        id: dragHandler
        target: noteCard
        onActiveChanged: {
            // Khi thả chuột ra -> Cập nhật vị trí lên model
            if (!active && noteData) {
                var changes = { position: { x: noteCard.x, y: noteCard.y } }
                noteCard.noteUpdated(Object.assign({}, noteData, changes))
            }
        }
    }

    // Cập nhật lại model khi Note bị thay đổi kích thước
    function updateSize() {
        if (noteData) {
            var changes = { size: { width: noteCard.width, height: noteCard.height } }
            noteCard.noteUpdated(Object.assign({}, noteData, changes))
        }
    }

    // ─── NỘI DUNG CHÍNH ──────────────────────────────────
    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: noteData ? noteData.color : "#fff59d"
        radius: Kirigami.Units.cornerRadius
        border.color: Kirigami.Theme.disabledTextColor
        border.width: 1

        // Đổ bóng nhẹ cho Note
        layer.enabled: true

        // Ép màu chữ đen/tối vì các thẻ Note luôn mang màu nền sáng (Pastel)
        // Nếu user dùng Dark Mode, chữ mặc định sẽ màu Trắng -> tàng hình trên nền Vàng!
        palette.text: "#212121"
        palette.windowText: "#212121"
        palette.buttonText: "#212121"
        palette.placeholderText: "#555555"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            // ─── HEADER ──────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true

                // 1. Title (nhấn vào để sửa)
                QQC2.TextArea {
                    id: titleInput
                    Layout.fillWidth: true
                    text: noteData ? noteData.title : ""
                    font.bold: true
                    wrapMode: Text.Wrap
                    
                    // Font lớn hơn 1 chút so với mặc định cho tiêu đề
                    font.pointSize: Math.max(1, Kirigami.Theme.defaultFont.pointSize * 1.2)
                    
                    color: "#212121"
                    
                    // Xóa viền/nền mặc định của TextField để giống chữ bình thường,
                    // chỉ hiện viền khi được focus
                    background: Rectangle {
                        color: titleInput.activeFocus ? "white" : "transparent"
                        radius: 2
                        opacity: titleInput.activeFocus ? 0.7 : 1
                    }
                    
                    // Lưu title khi mất focus
                    onActiveFocusChanged: {
                        if (!activeFocus && noteData) {
                            var newTitle = text.trim()
                            if (newTitle === "") {
                                newTitle = "New Note"
                                text = newTitle
                            }
                            var changes = { title: newTitle }
                            noteCard.noteUpdated(Object.assign({}, noteData, changes))
                        }
                    }
                }

                // 2. Nút đổi màu
                QQC2.ToolButton {
                    icon.name: "color-picker"
                    display: QQC2.AbstractButton.IconOnly
                    QQC2.ToolTip.text: "Change Color"
                    QQC2.ToolTip.visible: hovered
                    onClicked: colorPicker.open()
                }

                // 3. Nút xóa Note
                QQC2.ToolButton {
                    icon.name: "edit-delete"
                    display: QQC2.AbstractButton.IconOnly
                    QQC2.ToolTip.text: "Delete Note"
                    QQC2.ToolTip.visible: hovered
                    onClicked: deleteDialog.open()
                }
            }

            // ─── BODY (Danh sách Todo) ───
            ListView {
                id: todoList
                Layout.fillWidth: true
                Layout.fillHeight: true   // Chiếm hết khoảng trống ở giữa

                model: noteData ? noteData.items : []
                clip: true
                spacing: 0
                boundsBehavior: Flickable.StopAtBounds // Ngăn kéo dãn lố

                // Hiển thị thanh cuộn thay vì dùng ScrollView bọc ngoài
                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    active: true
                }

                delegate: TodoItem {
                    width: ListView.view.width
                    // modelData và index sẽ được Qt 6 auto-inject
                    // vì TodoItem khai báo "required property var modelData"

                    onToggled: function(todoId) {
                        noteCard.todoToggled(noteData.id, todoId)
                    }
                    onEdited: function(todoId, field, value) {
                        var changes = {}
                        changes[field] = value
                        noteCard.todoUpdated(noteData.id, todoId, changes)
                    }
                    onDeleted: function(todoId) {
                        noteCard.todoDeleted(noteData.id, todoId)
                    }
                    onDatePickerRequested: function(todoId, currentDate) {
                        datePicker.currentTodoId = todoId
                        datePicker.selectedDate = currentDate
                        datePicker.open()
                    }
                }
            }

            // ─── FOOTER (Todo Input - sẽ làm ở Epic E4) ────
            TodoInput {
                Layout.fillWidth: true
                // Khi gõ todo mới, truyền LUÔN content lên
                onTodoSubmitted: function(content) {
                    noteCard.todoAdded(noteData.id, content)
                }
            }
        }

        // ─── RESIZE AREA (Góc phải dưới) ────────────────────
        MouseArea {
            width: Kirigami.Units.gridUnit
            height: Kirigami.Units.gridUnit
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            cursorShape: Qt.SizeFDiagCursor   // Con trỏ chéo (mũi tên đổi kích thước)
            
            property real startX: 0
            property real startY: 0
            property real startWidth: 0
            property real startHeight: 0

            // Bắt đầu kéo
            onPressed: function(mouse) {
                startX = mouse.x
                startY = mouse.y
                startWidth = noteCard.width
                startHeight = noteCard.height
            }

            // Đang kéo -> cập nhật UI ngay lập tức để nhìn thấy
            onPositionChanged: function(mouse) {
                if (pressed) {
                    var newWidth = Math.max(200, startWidth + (mouse.x - startX))
                    var newHeight = Math.max(200, startHeight + (mouse.y - startY))
                    noteCard.width = newWidth
                    noteCard.height = newHeight
                }
            }

            // Thả chuột -> Lưu kích thước mới vào dữ liệu
            onReleased: {
                if (noteData) {
                    var changes = { size: { width: noteCard.width, height: noteCard.height } }
                    noteCard.noteUpdated(Object.assign({}, noteData, changes))
                }
            }
        }
    }

    // ─── COMPONENTS ẨN (Popup, Dialog) ───────────────────

    // Popup chọn màu
    ColorPickerPopup {
        id: colorPicker
        currentColor: noteData ? noteData.color : "#fff59d"
        x: parent.width - width - Kirigami.Units.gridUnit // Hiển thị ở góc trên phải
        y: Kirigami.Units.gridUnit * 2
        
        onColorSelected: function(newColor) {
            var changes = { color: newColor }
            noteCard.noteUpdated(Object.assign({}, noteData, changes))
        }
    }

    // Dialog xác nhận xóa (FR-02)
    QQC2.Dialog {
        id: deleteDialog
        title: "Delete Note"
        // Đổi từ Yes thành Ok vì QQC2.Dialog chỉ emit onAccepted() cho AcceptRole (Ok)
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true

        QQC2.Label {
            text: "Xóa note này? Tất cả todo bên trong sẽ bị mất."
            wrapMode: Text.Wrap
        }

        onAccepted: {
            noteCard.noteDeleted(noteData.id)
        }
    }

    // Dialog chọn ngày dueDate cho một công việc TODO
    DatePickerDialog {
        id: datePicker
        property string currentTodoId: ""
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        onDateAccepted: function(isoDate) {
            if (currentTodoId !== "") {
                var changes = { dueDate: isoDate }
                noteCard.todoUpdated(noteData.id, currentTodoId, changes)
                currentTodoId = ""
            }
        }
    }
}
