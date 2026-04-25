/*
 * DatePickerDialog.qml — Dialog chọn ngày deadline (dueDate)
 *
 * GIẢI THÍCH:
 * ──────────
 * Khi user click vào dueDate của một todo item,
 * dialog này mở ra để chọn ngày mới.
 *
 * KHÁI NIỆM MỚI — "Dialog":
 *   - Dialog là cửa sổ con "chặn" giao diện chính
 *   - User phải chọn xong rồi đóng dialog mới thao tác tiếp
 *   - Khác vs Popup: Dialog modal = chặn tương tác bên ngoài
 *
 * LƯU Ý VỀ DATEPICKER TRONG QML:
 *   - Qt 6 không có DatePicker component sẵn
 *   - Có 2 cách: dùng SpinBox cho ngày/tháng/năm, hoặc tự vẽ lịch
 *   - Ở đây dùng cách đơn giản: 3 SpinBox (ngày, tháng, năm)
 *   - Sẽ polish giao diện đẹp hơn ở Epic E4
 *
 * Skeleton: giao diện cơ bản với 3 SpinBox. Sẽ hoàn thiện ở Epic E4.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.Dialog {
    id: datePickerDialog

    // ─── PROPERTIES ──────────────────────────────────────
    // selectedDate: ngày đang chọn, định dạng ISO 8601 string
    property string selectedDate: new Date().toISOString()

    // Internal: tách ngày/tháng/năm từ selectedDate để hiển thị trên SpinBox
    property int _day: 1
    property int _month: 1
    property int _year: 2026

    // ─── SIGNALS ─────────────────────────────────────────
    signal dateAccepted(string isoDate)   // Phát khi user nhấn OK

    // ─── CẤU HÌNH DIALOG ────────────────────────────────
    title: "Select Due Date"
    modal: true                // Chặn tương tác bên ngoài
    standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel

    // ─── KHỞI TẠO ───────────────────────────────────────
    // onOpened: chạy mỗi khi dialog mở ra
    onOpened: {
        // Parse selectedDate → tách ra ngày/tháng/năm
        try {
            var d = new Date(selectedDate)
            if (!isNaN(d.getTime())) {
                _day = d.getDate()        // 1-31
                _month = d.getMonth() + 1 // 1-12 (getMonth trả 0-11)
                _year = d.getFullYear()   // 2026
            }
        } catch (e) {
            // Nếu parse lỗi → dùng ngày hôm nay
            var today = new Date()
            _day = today.getDate()
            _month = today.getMonth() + 1
            _year = today.getFullYear()
        }
    }

    // ─── KHI NHẤN OK ─────────────────────────────────────
    onAccepted: {
        // Ghép ngày/tháng/năm thành ISO date string
        // Lưu ý: tháng trong Date() là 0-11 nên trừ 1
        var d = new Date(_year, _month - 1, _day)
        datePickerDialog.dateAccepted(d.toISOString())
    }

    // ─── NỘI DUNG ────────────────────────────────────────
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        // Hướng dẫn
        QQC2.Label {
            text: "Choose a due date for this todo:"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }

        // 3 SpinBox: Ngày / Tháng / Năm
        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.alignment: Qt.AlignHCenter

            // ── Ngày ──
            ColumnLayout {
                QQC2.Label { text: "Day"; Layout.alignment: Qt.AlignHCenter }
                QQC2.SpinBox {
                    id: daySpinBox
                    from: 1; to: 31
                    value: datePickerDialog._day
                    onValueModified: datePickerDialog._day = value
                }
            }

            // ── Tháng ──
            ColumnLayout {
                QQC2.Label { text: "Month"; Layout.alignment: Qt.AlignHCenter }
                QQC2.SpinBox {
                    id: monthSpinBox
                    from: 1; to: 12
                    value: datePickerDialog._month
                    onValueModified: datePickerDialog._month = value
                }
            }

            // ── Năm ──
            ColumnLayout {
                QQC2.Label { text: "Year"; Layout.alignment: Qt.AlignHCenter }
                QQC2.SpinBox {
                    id: yearSpinBox
                    from: 2020; to: 2050
                    value: datePickerDialog._year
                    onValueModified: datePickerDialog._year = value
                }
            }
        }
    }
}
