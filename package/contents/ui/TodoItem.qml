/*
 * TodoItem.qml — Component hiển thị MỘT todo item
 *
 * GIẢI THÍCH:
 * ──────────
 * Mỗi TodoItem gồm:
 *   - Checkbox: bật/tắt hoàn thành
 *   - Content text: nội dung todo (click để sửa)
 *   - CreatedAt: thời gian tạo (dạng "2 hours ago")
 *   - DueDate badge: thời hạn + màu theo trạng thái
 *   - Delete icon: hiện khi hover
 *
 * Skeleton: chưa có giao diện thật. Sẽ hoàn thiện ở Epic E4.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: todoItem

    // ─── PROPERTIES ──────────────────────────────────────
    required property var todoData      // Object todo: {id, content, createdAt, dueDate, completed, order}
    required property int todoIndex     // Vị trí trong danh sách

    // ─── SIGNALS ─────────────────────────────────────────
    signal toggled(string todoId)                      // Toggle completed
    signal edited(string todoId, string field, var value)   // Sửa content hoặc dueDate
    signal deleted(string todoId)                      // Xóa todo
    signal reorderRequested(int fromIndex, int toIndex)  // Kéo thả đổi vị trí
    signal datePickerRequested(string todoId, string currentDate) // Mở chọn ngày


    // ─── KÍCH THƯỚC ──────────────────────────────────────
    implicitHeight: layout.implicitHeight + Kirigami.Units.smallSpacing * 2
    implicitWidth: parent ? parent.width : 200

    // HoverHandler để bắt sự kiện rê chuột (hiện ra nút Xóa)
    HoverHandler {
        id: hoverHandler
    }

    // ─── NỘI DUNG CHÍNH ──────────────────────────────────
    RowLayout {
        id: layout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        // 1. Giữ chuột để kéo thả (Reorder) - Placeholder cho Drag
        Kirigami.Icon {
            source: "drag-handle-vertical"
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            opacity: hoverHandler.hovered ? 0.5 : 0
            
            // Xử lý kéo thả sẽ làm chi tiết ở bản nâng cao
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.OpenHandCursor
            }
        }

        // 2. Checkbox (Hoàn thành hay chưa)
        QQC2.CheckBox {
            id: chkComplete
            checked: todoData ? todoData.completed : false
            Layout.alignment: Qt.AlignTop
            
            onClicked: {
                todoItem.toggled(todoData.id)
            }
        }

        // 3. Nội dung & Thời gian
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            // Nội dung Todo (có thể sửa)
            QQC2.TextField {
                id: contentField
                Layout.fillWidth: true
                text: todoData ? todoData.content : ""
                
                // Mờ và gạch ngang chữ nếu đã hoàn thành (FR-07)
                font.strikeout: todoData && todoData.completed
                color: (todoData && todoData.completed) ? "#757575" : "#212121"

                // Trong suốt để trông như một cái Label bình thường
                background: Rectangle {
                    color: contentField.activeFocus ?Kirigami.Theme.backgroundColor : "transparent"
                    border.color: contentField.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                }

                onEditingFinished: {
                    var newContent = text.trim()
                    // Revert nếu nhập trống
                    if (newContent === "" && todoData) {
                        text = todoData.content
                        return;
                    }
                    if (todoData && newContent !== todoData.content) {
                        todoItem.edited(todoData.id, "content", newContent)
                    }
                }
            }

            // Hiển thị thời gian
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                
                // Thời gian tạo
                QQC2.Label {
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                    color: "#757575"
                    // Logic.formatRelativeTime(todoData.createdAt)
                    text: todoData ? ("Created: " + Logic.formatRelativeTime(todoData.createdAt)) : ""
                }

                // Hiển thị Deadline (DueDate)
                Rectangle {
                    color: "transparent"
                    Layout.preferredWidth: dueDateLabel.width + 10
                    Layout.preferredHeight: dueDateLabel.height + 4
                    radius: 4
                    
                    // FR-12: Màu theo trạng thái (status)
                    property string status: todoData ? Logic.getStatus(todoData) : "normal"
                    border.color: status === "warning" ? "#f57f17" : (status === "overdue" ? "#c62828" : "transparent")

                    QQC2.Label {
                        id: dueDateLabel
                        anchors.centerIn: parent
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                        color: parent.status === "warning" ? "#c86000" : (parent.status === "overdue" ? "#c62828" : "#757575")
                        text: todoData ? Logic.formatDueDate(todoData.dueDate) : ""
                    }

                        // Click để sửa Deadline
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Kích hoạt việc mở dialog đổi ngày, được NoteCard lắng nghe
                            if (todoData) {
                                todoItem.datePickerRequested(todoData.id, todoData.dueDate)
                            }
                        }
                    }
                }
            }
        }

        // 4. Icon Xóa (Chỉ hiện khi đưa chuột vào)
        QQC2.ToolButton {
            icon.name: "edit-delete"
            display: QQC2.AbstractButton.IconOnly
            Layout.alignment: Qt.AlignTop
            opacity: hoverHandler.hovered ? 1 : 0   // FR-08
            
            // Có hiệu ứng mượt khi hiện/ẩn
            Behavior on opacity { NumberAnimation { duration: 150 } }

            onClicked: {
                if (todoData) {
                    todoItem.deleted(todoData.id)
                }
            }
        }
    }
}
