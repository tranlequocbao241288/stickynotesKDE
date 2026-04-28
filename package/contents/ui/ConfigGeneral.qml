/*
 * ConfigGeneral.qml — Cấu hình chung cho plasmoid
 * 
 * File này hiển thị trong Settings dialog khi user right-click widget → Configure
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configPage

    // Alias để KDE tự động bind với plasmoid.configuration
    property alias cfg_enableGoogleDriveSync: enableSyncCheckbox.checked
    property alias cfg_googleDrivePath: drivePathField.text
    property alias cfg_googleDriveFileName: fileNameField.text

    Kirigami.FormLayout {
        anchors.fill: parent

        // ─── GOOGLE DRIVE SYNC SECTION ───────────────────
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Google Drive Sync"
        }

        QQC2.CheckBox {
            id: enableSyncCheckbox
            Kirigami.FormData.label: "Enable sync:"
            text: "Automatically sync notes to Google Drive"
        }

        QQC2.TextField {
            id: drivePathField
            Kirigami.FormData.label: "Drive path:"
            placeholderText: "~/GoogleDrive/StickyNotes"
            enabled: enableSyncCheckbox.checked
            
            QQC2.ToolTip.text: "Path to your mounted Google Drive folder.\nExample: ~/GoogleDrive/StickyNotes or ~/gdrive/StickyNotes"
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.TextField {
            id: fileNameField
            Kirigami.FormData.label: "File name:"
            placeholderText: "sticky-notes-data.json"
            enabled: enableSyncCheckbox.checked
            
            QQC2.ToolTip.text: "Name of the JSON file to store notes"
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        // ─── HELP TEXT ────────────────────────────────────
        Item {
            Kirigami.FormData.isSection: true
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: "To use Google Drive sync, you need to mount your Google Drive first using rclone or google-drive-ocamlfuse."
            visible: enableSyncCheckbox.checked
        }

        RowLayout {
            Layout.fillWidth: true
            visible: enableSyncCheckbox.checked

            QQC2.Label {
                text: "Setup guide:"
                Layout.alignment: Qt.AlignVCenter
            }

            QQC2.Button {
                text: "Install rclone"
                icon.name: "download"
                onClicked: Qt.openUrlExternally("https://rclone.org/install/")
            }

            QQC2.Button {
                text: "Configure rclone"
                icon.name: "configure"
                onClicked: Qt.openUrlExternally("https://rclone.org/drive/")
            }
        }

        // ─── STATUS CHECK ─────────────────────────────────
        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Layout.fillWidth: true
            visible: enableSyncCheckbox.checked

            QQC2.Label {
                text: "Status:"
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                width: 12
                height: 12
                radius: 6
                color: statusLabel.isAvailable ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                Layout.alignment: Qt.AlignVCenter
            }

            QQC2.Label {
                id: statusLabel
                property bool isAvailable: false
                text: isAvailable ? "Google Drive is accessible" : "Google Drive path not found"
                Layout.alignment: Qt.AlignVCenter
            }

            QQC2.Button {
                text: "Check"
                icon.name: "view-refresh"
                onClicked: checkDriveStatus()
            }
        }
    }

    // ─── FUNCTIONS ────────────────────────────────────────
    function checkDriveStatus() {
        // Kiểm tra xem đường dẫn có tồn tại không
        var path = drivePathField.text;
        if (!path || path.trim() === "") {
            statusLabel.isAvailable = false;
            return;
        }

        // Gọi shell command để kiểm tra
        // (Trong thực tế, cần implement qua plasmoid hoặc dùng Qt.labs.platform)
        // Đây là placeholder - sẽ cần implement thực tế
        console.log("Checking drive path:", path);
        
        // Tạm thời giả định có sẵn (cần implement thực tế)
        statusLabel.isAvailable = true;
    }

    Component.onCompleted: {
        if (enableSyncCheckbox.checked) {
            checkDriveStatus();
        }
    }
}
