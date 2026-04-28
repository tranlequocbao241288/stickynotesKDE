/*
 * main.qml — Entry point (điểm vào) của KDE Sticky Notes plasmoid
 *
 * GIẢI THÍCH CHO NGƯỜI MỚI:
 * ─────────────────────────
 * File QML được viết theo dạng "khai báo" (declarative):
 *   - Bạn MÔ TẢ giao diện muốn có, không phải viết từng bước tạo
 *   - Mỗi "khối" {} là một component (thành phần giao diện)
 *   - Property (thuộc tính) quyết định giao diện hiển thị ra sao
 *
 * CẤU TRÚC FILE NÀY:
 *   1. import — nạp thư viện cần dùng
 *   2. PlasmoidItem — container chính của widget
 *   3. Bên trong: các component con tạo nên giao diện
 *
 * CÁC KHÁI NIỆM QUAN TRỌNG:
 *   - import: giống #include trong C hoặc import trong Python
 *   - property: biến gắn với component, khi thay đổi → UI tự cập nhật
 *   - id: tên riêng để tham chiếu component từ nơi khác
 *   - anchors: hệ thống định vị (trên/dưới/trái/phải/giữa)
 */

// ─── IMPORTS ───────────────────────────────────────────────
// Nạp các thư viện QML cần thiết

import QtQuick                          // Thư viện gốc: Item, Rectangle, Text, MouseArea...
import QtQuick.Layouts                   // Hệ thống layout: RowLayout, ColumnLayout
import QtQuick.Controls as QQC2         // Controls chuẩn: Button, TextField, ScrollView...
import org.kde.plasma.plasmoid          // API của KDE Plasma plasmoid
import org.kde.kirigami as Kirigami     // Design system của KDE (màu sắc, icon, units)
import Qt.labs.platform                 // StandardPaths để lấy đường dẫn home

// Import file logic.js — chứa toàn bộ business logic
// Cú pháp: import "đường_dẫn" as TênĐểGọi
// Sau này gọi: Logic.createNote(), Logic.getStatus(), v.v.
import "../code/logic.js" as Logic

// ─── COMPONENT CHÍNH ──────────────────────────────────────
// PlasmoidItem là container gốc cho mọi KDE Plasma widget
// Mọi thứ hiển thị trên desktop đều nằm bên trong đây

PlasmoidItem {
    id: root    // Đặt tên "root" để các component con có thể tham chiếu

    // ─── KÍCH THƯỚC HIỂN THỊ (TRÊN DESKTOP) ──────────────
    // Kích thước mặc định của widget khi kéo ra ngoài màn hình
    implicitWidth: Kirigami.Units.gridUnit * 20    // ~360px
    implicitHeight: Kirigami.Units.gridUnit * 24   // ~432px

    // ─── DỮ LIỆU ────────────────────────────────────────
    // notesModel: mảng chứa toàn bộ notes, sẽ load từ config
    property var notesModel: []

    // ─── TÌM KIẾM & LỌC (Epic E6) ───────────────────────
    property string searchQuery: ""
    property string activeFilter: "all"
    
    // filteredNotes sẽ tự động tính toán lại mỗi khi notesModel, searchQuery hoặc activeFilter thay đổi
    property var filteredNotes: Logic.getFilteredNotes(notesModel, searchQuery, activeFilter)

    // ─── GOOGLE DRIVE SYNC HELPERS ──────────────────────
    /**
     * Ghi file lên Google Drive.
     * 
     * @param drivePath - Đường dẫn thư mục Google Drive
     * @param fileName - Tên file
     * @param content - Nội dung file (JSON string)
     */
    function syncToGoogleDrive(drivePath, fileName, content) {
        try {
            // Expand ~ thành đường dẫn home thực
            var expandedPath = drivePath.replace("~", StandardPaths.writableLocation(StandardPaths.HomeLocation));
            var fullPath = expandedPath + "/" + fileName;
            
            // Escape content cho shell command
            var escapedContent = content.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\$/g, "\\$").replace(/`/g, "\\`");
            
            // Tạo thư mục nếu chưa có và ghi file
            var script = "mkdir -p '" + expandedPath + "' && echo \"" + escapedContent + "\" > '" + fullPath + "'";
            
            // Sử dụng executable helper
            executable.exec(script);
            
            console.log("main.qml: Synced to Google Drive:", fullPath);
        } catch (e) {
            console.error("main.qml: Failed to sync to Google Drive:", e.message);
        }
    }

    /**
     * Đọc file từ Google Drive.
     * 
     * @param drivePath - Đường dẫn thư mục Google Drive
     * @param fileName - Tên file
     * @returns Nội dung file hoặc chuỗi rỗng nếu lỗi
     */
    function loadFromGoogleDrive(drivePath, fileName) {
        try {
            // Expand ~ thành đường dẫn home thực
            var expandedPath = drivePath.replace("~", StandardPaths.writableLocation(StandardPaths.HomeLocation));
            var fullPath = expandedPath + "/" + fileName;
            
            // Đọc file
            var result = executable.exec("cat '" + fullPath + "' 2>/dev/null || echo ''");
            
            if (result && result.trim() !== "") {
                console.log("main.qml: Loaded from Google Drive:", fullPath);
                return result;
            }
            
            return "";
        } catch (e) {
            console.error("main.qml: Failed to load from Google Drive:", e.message);
            return "";
        }
    }

    /**
     * Kiểm tra xem đường dẫn Google Drive có tồn tại không.
     * 
     * @param drivePath - Đường dẫn thư mục Google Drive
     * @returns true nếu tồn tại, false nếu không
     */
    function checkDrivePathExists(drivePath) {
        try {
            var expandedPath = drivePath.replace("~", StandardPaths.writableLocation(StandardPaths.HomeLocation));
            var result = executable.exec("test -d '" + expandedPath + "' && echo 'exists' || echo 'not_exists'");
            return result && result.trim() === "exists";
        } catch (e) {
            return false;
        }
    }

    // ─── EXECUTABLE HELPER (để chạy shell commands) ─────
    Executable {
        id: executable
    }

    // ─── GIAO DIỆN ───────────────────────────────────────
    // fullRepresentation: Giao diện đầy đủ khi click vào widget trên panel
    // (Nếu widget nằm trên desktop thì luôn hiển thị giao diện này)
    fullRepresentation: ColumnLayout {
        // ColumnLayout: xếp các component con theo chiều DỌC (từ trên xuống dưới)
        // anchors.fill: parent → chiếm toàn bộ không gian có sẵn
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing   // khoảng cách giữa các component

        // ─── HEADER ──────────────────────────────────────
        // Thanh trên cùng: chứa tiêu đề + nút tạo note mới
        RowLayout {
            // RowLayout: xếp theo chiều NGANG (trái → phải)
            Layout.fillWidth: true   // chiếm hết chiều ngang
            Layout.margins: Kirigami.Units.smallSpacing

            // ── Tiêu đề ứng dụng ──
            Kirigami.Heading {
                // Heading: component text với style heading của KDE
                text: "📝 Sticky Notes"
                level: 2   // Cỡ heading (1 = to nhất, 5 = nhỏ nhất)
                Layout.fillWidth: true  // Kéo dài chiếm hết chỗ trống
            }

            // ── Nút tạo note mới ──
            QQC2.ToolButton {
                // ToolButton: nút bấm nhỏ gọn, thường dùng trên toolbar
                icon.name: "list-add"   // Icon "+" có sẵn trong KDE
                text: "New Note"

                // display: chỉ hiện icon, ẩn text (text vẫn dùng cho tooltip)
                display: QQC2.AbstractButton.IconOnly

                // ToolTip: tooltip hiện khi hover chuột lên nút
                QQC2.ToolTip.text: "Create a new note"
                QQC2.ToolTip.visible: hovered   // hiện khi hover
                QQC2.ToolTip.delay: 500          // delay 500ms

                // onClicked: gọi Logic.createNote() để tạo note mới
                onClicked: {
                    var newNote = Logic.createNote()
                    
                    // Thay vì random nhỏ lẻ, dời vị trí Note mới dựa trên số lượng notes hiện có (cascade)
                    // để đảm bảo ghi chú mới không bao giờ đè hoàn toàn lên ghi chú cũ
                    var offset = (root.notesModel.length * 40) % 400
                    newNote.position = { x: 100 + offset, y: 100 + offset }
                    
                    // Tạo mảng mới = mảng cũ + note mới (nguyên tắc immutable)
                    root.notesModel = root.notesModel.concat(newNote)
                    // Hẹn giờ lưu dữ liệu
                    Logic.scheduleSave(root, root.notesModel)
                }
            }

            // ── Nút đồng bộ Google Drive ──
            QQC2.ToolButton {
                icon.name: "cloud-upload"
                text: "Sync to Drive"
                display: QQC2.AbstractButton.IconOnly
                visible: root.plasmoid.configuration.enableGoogleDriveSync
                
                QQC2.ToolTip.text: "Manually sync to Google Drive"
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: 500

                onClicked: {
                    Logic.manualSyncToDrive(root, root.notesModel)
                    syncNotification.text = "Synced to Google Drive!"
                    syncNotification.visible = true
                    syncNotificationTimer.restart()
                }
            }

            // ── Nút tải lại từ Google Drive ──
            QQC2.ToolButton {
                icon.name: "cloud-download"
                text: "Load from Drive"
                display: QQC2.AbstractButton.IconOnly
                visible: root.plasmoid.configuration.enableGoogleDriveSync
                
                QQC2.ToolTip.text: "Reload notes from Google Drive"
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: 500

                onClicked: {
                    var driveNotes = Logic.manualLoadFromDrive(root)
                    if (driveNotes !== null) {
                        root.notesModel = driveNotes
                        syncNotification.text = "Loaded from Google Drive!"
                        syncNotification.visible = true
                        syncNotificationTimer.restart()
                    } else {
                        syncNotification.text = "Failed to load from Drive"
                        syncNotification.visible = true
                        syncNotificationTimer.restart()
                    }
                }
            }
        }

        // ─── SEPARATOR ───────────────────────────────────
        Kirigami.Separator {
            Layout.fillWidth: true
        }

        // ─── THANH TÌM KIẾM & LỌC (Epic E6) ─────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.largeSpacing

            // Ô nhập tìm kiếm
            QQC2.TextField {
                id: searchInput
                Layout.fillWidth: true
                placeholderText: "🔍 Search notes or todos... (Ctrl+F)"
                
                // Cập nhật query (có debounce nhỏ tự nhiên của QML nhưng an toàn)
                onTextChanged: {
                    root.searchQuery = text
                }
            }

            // Phím tắt Ctrl+F đưa trỏ chuột ngay lập tức vào ô tìm kiếm
            Shortcut {
                sequence: "Ctrl+F"
                onActivated: searchInput.forceActiveFocus()
            }

            // Các nút Lọc (Filter)
            RowLayout {
                spacing: 0
                
                QQC2.Button {
                    text: "All"
                    checked: root.activeFilter === "all"
                    checkable: true
                    onClicked: root.activeFilter = "all"
                }
                QQC2.Button {
                    text: "Active"
                    checked: root.activeFilter === "active"
                    checkable: true
                    onClicked: root.activeFilter = "active"
                }
                QQC2.Button {
                    text: "Completed"
                    checked: root.activeFilter === "completed"
                    checkable: true
                    onClicked: root.activeFilter = "completed"
                }
                QQC2.Button {
                    text: "Overdue"
                    checked: root.activeFilter === "overdue"
                    checkable: true
                    onClicked: root.activeFilter = "overdue"
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        // ─── NỘI DUNG CHÍNH (Drag Canvas) ──────────
        // Bọc Flickable và Placeholder vào chung 1 Item để Placeholder được canh giữa phần thân (thay vì canh giữa toàn màn hình)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Flickable tạo một khoảng không gian (canvas) rộng để kéo các note
            Flickable {
                id: noteCanvas
                anchors.fill: parent
                contentWidth: 3000   // Kích thước canvas ảo
                contentHeight: 3000
                clip: true           // Ẩn nội dung tràn ra ngoài viewport

                // ╔════════════════════════════════════════════════╗
                // ║  FIX: Tắt drag-to-scroll của Flickable         ║
                // ║  Lý do: Flickable bắt gesture kéo → cuộn       ║
                // ║  toàn bộ canvas → tất cả notes di chuyển theo.  ║
                // ║  Thay vào đó dùng ScrollBar + WheelHandler.     ║
                // ╚════════════════════════════════════════════════╝
                interactive: false

                // ScrollBar cho phép cuộn bằng thanh cuộn
                QQC2.ScrollBar.vertical: QQC2.ScrollBar { active: true }
                QQC2.ScrollBar.horizontal: QQC2.ScrollBar { active: true }

                // WheelHandler: cuộn canvas bằng con lăn chuột
                WheelHandler {
                    onWheel: function(event) {
                        var newY = noteCanvas.contentY - event.angleDelta.y
                        noteCanvas.contentY = Math.max(0, Math.min(
                            noteCanvas.contentHeight - noteCanvas.height, newY))
                        var newX = noteCanvas.contentX - event.angleDelta.x
                        noteCanvas.contentX = Math.max(0, Math.min(
                            noteCanvas.contentWidth - noteCanvas.width, newX))
                    }
                }

                // Background để dễ nhận biết vùng có thể cuộn
                Rectangle {
                    anchors.fill: parent
                    color: Kirigami.Theme.backgroundColor
                    opacity: 0.5
                }

                // Repeater: tự động tạo NoteCard dựa trên kết quả LỌC
                Repeater {
                    model: root.filteredNotes
                    
                    delegate: NoteCard {
                        id: noteDelegate
                        // modelData và index sẽ được Qt 6 auto-inject
                        // vì NoteCard khai báo "required property var modelData"

                        // ╔═══════════════════════════════════════════════════════╗
                        // ║  FIX: Không dùng binding x/y trực tiếp vào noteData  ║
                        // ║  Lý do: mỗi lần model thay đổi (kể cả update note     ║
                        // ║  khác) QML re-evaluate binding → note đang kéo bị    ║
                        // ║  snap về vị trí cũ trong data.                        ║
                        // ║  Giải pháp: đặt x/y một lần khi tạo, sau đó chỉ      ║
                        // ║  cập nhật từ data khi note KHÔNG đang được kéo.       ║
                        // ╚═══════════════════════════════════════════════════════╝

                        // Set vị trí ban đầu từ data (chỉ 1 lần khi tạo)
                        Component.onCompleted: {
                            x = (noteData && noteData.position) ? noteData.position.x : 100
                            y = (noteData && noteData.position) ? noteData.position.y : 100
                        }

                        // Đồng bộ vị trí từ data khi data thay đổi NHƯNG note không đang kéo
                        onNoteDataChanged: {
                            if (!dragging && noteData && noteData.position) {
                                x = noteData.position.x
                                y = noteData.position.y
                            }
                        }

                        onNoteUpdated: function(updatedNote) {
                            var rootRef = root
                            rootRef.notesModel = Logic.updateNote(rootRef.notesModel, updatedNote.id, updatedNote)
                            Logic.scheduleSave(rootRef, rootRef.notesModel)
                        }

                        onNoteDeleted: function(noteId) {
                            var rootRef = root
                            rootRef.notesModel = Logic.deleteNote(rootRef.notesModel, noteId)
                            Logic.scheduleSave(rootRef, rootRef.notesModel)
                        }

                        onTodoAdded: function(noteId, content) {
                            console.log("main.qml: onTodoAdded called - noteId:", noteId, "content:", content)
                            
                            // Lưu reference đến root trước
                            var rootRef = root
                            
                            var newTodo = Logic.createTodo(noteId, rootRef.notesModel)
                            console.log("main.qml: Created todo:", newTodo.id)
                            
                            // Gán nội dung thực sự thay vì chuỗi rỗng
                            if (content) {
                                newTodo.content = content
                            }
                            
                            console.log("main.qml: Before addTodoToNote")
                            var updatedModel = Logic.addTodoToNote(rootRef.notesModel, noteId, newTodo)
                            console.log("main.qml: After addTodoToNote")
                            
                            rootRef.notesModel = updatedModel
                            Logic.scheduleSave(rootRef, rootRef.notesModel)
                        }
                        
                        onTodoUpdated: function(noteId, todoId, changes) {
                            var rootRef = root
                            rootRef.notesModel = Logic.updateTodo(rootRef.notesModel, noteId, todoId, changes)
                            Logic.scheduleSave(rootRef, rootRef.notesModel)
                        }

                        onTodoDeleted: function(noteId, todoId) {
                            var rootRef = root
                            rootRef.notesModel = Logic.deleteTodo(rootRef.notesModel, noteId, todoId)
                            Logic.scheduleSave(rootRef, rootRef.notesModel)
                        }

                        onTodoToggled: function(noteId, todoId) {
                            var rootRef = root
                            var currentTodo = rootRef.notesModel.find(n => n.id === noteId).items.find(t => t.id === todoId);
                            if (currentTodo) {
                                rootRef.notesModel = Logic.updateTodo(rootRef.notesModel, noteId, todoId, { completed: !currentTodo.completed })
                                Logic.scheduleSave(rootRef, rootRef.notesModel)
                            }
                        }
                    }
                }
            }

            // Placeholder thông báo rỗng (chỉ hiển thị đè lên vùng Flickable)
            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - (Kirigami.Units.largeSpacing * 4)
                text: root.notesModel.length === 0 ? "No notes yet" : "No results found"
                explanation: root.notesModel.length === 0 ? "Click the + button to create your first note" : "Try adjusting your search or filter"
                icon.name: "knotes"
                visible: root.filteredNotes.length === 0
            }
        }
    }

    // ─── SYNC NOTIFICATION ────────────────────────────────
    // Thông báo nhỏ hiện khi sync thành công
    Kirigami.InlineMessage {
        id: syncNotification
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Kirigami.Units.largeSpacing
        type: Kirigami.MessageType.Positive
        visible: false
        
        Timer {
            id: syncNotificationTimer
            interval: 3000  // 3 giây
            onTriggered: syncNotification.visible = false
        }
    }

    // ─── KHỞI TẠO ────────────────────────────────────────
    // Component.onCompleted: hàm chạy MỘT LẦN khi widget load xong
    // Giống onLoad() trong web, hoặc main() trong C
    Component.onCompleted: {
        console.log("Sticky Notes plasmoid loaded successfully!")
        // Tải dữ liệu từ cấu hình (Epic E2)
        root.notesModel = Logic.loadFromConfig(root)
    }
}
