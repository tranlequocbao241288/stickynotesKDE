/*
 * Executable.qml — Helper để chạy shell commands từ QML
 * 
 * QML không có built-in cách chạy shell commands, nên ta dùng
 * PlasmaCore.DataSource với engine "executable" để chạy commands.
 */

import QtQuick
import org.kde.plasma.core as PlasmaCore

Item {
    id: executableHelper

    /**
     * Chạy shell command và trả về output.
     * 
     * @param cmd - Shell command cần chạy
     * @returns Output của command (string)
     */
    function exec(cmd) {
        // Tạo DataSource với engine "executable"
        var dataSource = Qt.createQmlObject(
            'import org.kde.plasma.core as PlasmaCore; ' +
            'PlasmaCore.DataSource { ' +
            '    id: execSource; ' +
            '    engine: "executable"; ' +
            '    connectedSources: []; ' +
            '    onNewData: { ' +
            '        disconnectSource(sourceName); ' +
            '    } ' +
            '}',
            executableHelper
        );

        // Kết nối source và chạy command
        dataSource.connectSource(cmd);
        
        // Đợi kết quả (synchronous - không lý tưởng nhưng đơn giản)
        // Trong production nên dùng async với callback
        var maxWait = 100; // 100ms timeout
        var waited = 0;
        while (!dataSource.data[cmd] && waited < maxWait) {
            // Busy wait (không tốt nhưng đơn giản cho MVP)
            waited++;
        }
        
        var result = "";
        if (dataSource.data[cmd]) {
            result = dataSource.data[cmd]["stdout"] || "";
        }
        
        // Cleanup
        dataSource.destroy();
        
        return result;
    }

    /**
     * Chạy command async với callback.
     * 
     * @param cmd - Shell command
     * @param callback - Function(output) được gọi khi xong
     */
    function execAsync(cmd, callback) {
        var dataSource = Qt.createQmlObject(
            'import org.kde.plasma.core as PlasmaCore; ' +
            'PlasmaCore.DataSource { ' +
            '    id: execSource; ' +
            '    engine: "executable"; ' +
            '    connectedSources: []; ' +
            '    property var callback: null; ' +
            '    onNewData: function(sourceName, data) { ' +
            '        if (callback) { ' +
            '            callback(data["stdout"] || ""); ' +
            '        } ' +
            '        disconnectSource(sourceName); ' +
            '        destroy(); ' +
            '    } ' +
            '}',
            executableHelper
        );

        dataSource.callback = callback;
        dataSource.connectSource(cmd);
    }
}
