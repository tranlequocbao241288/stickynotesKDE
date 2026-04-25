/*
 * TodoInput.qml — Component nhập todo mới
 *
 * GIẢI THÍCH:
 * ──────────
 * Đây là ô input ở cuối mỗi NoteCard.
 * User gõ nội dung → nhấn Enter hoặc click nút "+" → tạo todo mới.
 * Nếu content rỗng → không cho tạo.
 *
 * Skeleton: chưa có giao diện thật. Sẽ hoàn thiện ở Epic E4.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

RowLayout {
    id: todoInput

    // ─── SIGNALS ─────────────────────────────────────────
    signal todoSubmitted(string content)   // Phát khi user submit todo mới

    // ─── PLACEHOLDER UI ──────────────────────────────────
    spacing: Kirigami.Units.smallSpacing

    QQC2.TextField {
        id: inputField
        Layout.fillWidth: true
        placeholderText: "+ Add item..."
        
        // Cố định màu chữ tối trên nền thẻ Note sáng
        color: "#212121"
        
        // Xóa background mặc định (thường màu xám đen ở dark mode)
        // Thay bằng một nền trong suốt, hoặc trắng khi focus
        background: Rectangle {
            color: inputField.activeFocus ? "white" : "transparent"
            radius: 4
            opacity: inputField.activeFocus ? 0.7 : 1
            border.color: inputField.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
        }

        // onAccepted: chạy khi nhấn Enter, ổn định hơn trên QQC2.TextField
        onAccepted: {
            if (text.trim() !== "") {
                todoInput.todoSubmitted(text.trim())
                text = ""   // Xóa input sau khi submit
            }
        }
    }

    QQC2.ToolButton {
        icon.name: "list-add"
        enabled: inputField.text.trim() !== ""   // Chỉ bấm được khi có text

        onClicked: {
            if (inputField.text.trim() !== "") {
                todoInput.todoSubmitted(inputField.text.trim())
                inputField.text = ""
                inputField.forceActiveFocus()   // Focus lại input sau khi submit
            }
        }
    }
}
