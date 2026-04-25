/*
 * ColorPickerPopup.qml — Popup chọn màu cho Note
 *
 * GIẢI THÍCH:
 * ──────────
 * Khi user click icon 🎨 trên header của NoteCard,
 * popup này hiện ra với 6 ô màu preset.
 * Click vào ô màu → Note đổi màu nền → popup tự đóng.
 *
 * KHÁI NIỆM MỚI — "Popup":
 *   - Popup là component "nổi" trên giao diện, không chiếm vị trí cố định
 *   - Giống dropdown menu hoặc tooltip
 *   - Popup tự đóng khi click vào nơi khác (closePolicy)
 *
 * KHÁI NIỆM MỚI — "Grid":
 *   - Grid xếp các component con thành lưới (hàng x cột)
 *   - columns: 3 → mỗi hàng có 3 ô → 6 màu = 2 hàng x 3 cột
 *
 * KHÁI NIỆM MỚI — "Repeater":
 *   - Repeater tạo nhiều component giống nhau từ một mảng dữ liệu
 *   - model: mảng màu → Repeater tạo 6 ô màu
 *   - modelData: giá trị của phần tử hiện tại trong mảng
 *
 * Skeleton: giao diện cơ bản. Sẽ polish ở Epic E3.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

import "../code/logic.js" as Logic

QQC2.Popup {
    id: colorPicker

    // ─── PROPERTIES ──────────────────────────────────────
    property string currentColor: Logic.DEFAULT_COLOR   // Màu đang chọn

    // ─── SIGNALS ─────────────────────────────────────────
    signal colorSelected(string color)   // Phát khi user chọn màu

    // ─── CẤU HÌNH POPUP ─────────────────────────────────
    modal: false                          // Không chặn tương tác bên ngoài
    padding: Kirigami.Units.smallSpacing

    // ─── NỘI DUNG ────────────────────────────────────────
    contentItem: Grid {
        columns: 3                        // 3 cột → 2 hàng x 3 cột = 6 ô
        spacing: Kirigami.Units.smallSpacing

        // Repeater: lặp qua mảng PRESET_COLORS, tạo 6 ô màu
        Repeater {
            model: Logic.PRESET_COLORS   // ["#fff59d", "#c8e6c9", ...]

            // delegate: component được tạo cho MỖI phần tử trong model
            delegate: Rectangle {
                // modelData: giá trị phần tử hiện tại (ví dụ: "#fff59d")
                required property string modelData

                width: Kirigami.Units.gridUnit * 2
                height: Kirigami.Units.gridUnit * 2
                radius: Kirigami.Units.cornerRadius
                color: modelData

                // Viền đậm hơn nếu đang là màu được chọn
                border.width: modelData === colorPicker.currentColor ? 3 : 1
                border.color: modelData === colorPicker.currentColor
                              ? Kirigami.Theme.highlightColor
                              : Kirigami.Theme.disabledTextColor

                // MouseArea: vùng bắt click chuột
                MouseArea {
                    anchors.fill: parent       // Phủ toàn bộ ô màu
                    cursorShape: Qt.PointingHandCursor   // Con trỏ hình bàn tay

                    onClicked: {
                        colorPicker.colorSelected(modelData)   // Phát signal
                        colorPicker.close()                     // Đóng popup
                    }
                }
            }
        }
    }
}
