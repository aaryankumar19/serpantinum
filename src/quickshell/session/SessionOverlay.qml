import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../"
import "../reusables"
import "../singletons/widgetcontrols"
import "../singletons/info"

PanelWindow {
    id: sessionWindow

    screen: SessionController.screen || (typeof Quickshell !== "undefined" && Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

    WlrLayershell.namespace: "qs-session"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    focusable: isVisible
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    property bool isVisible: SessionController.isVisible
    visible: isVisible

    property int selectedIndex: 0

    readonly property var actionsModel: [
        { action: "lock", icon: "", label: "Lock", keyHint: "L", accentColor: ThemeBackend.blue, script: "scripts/lock.sh" },
        { action: "suspend", icon: "󰤄", label: "Suspend", keyHint: "U", accentColor: ThemeBackend.sapphire, script: "scripts/system/suspend.sh" },
        { action: "hibernate", icon: "󰒲", label: "Hibernate", keyHint: "H", accentColor: ThemeBackend.mauve, script: "scripts/system/hibernate.sh" },
        { action: "reboot", icon: "", label: "Reboot", keyHint: "R", accentColor: ThemeBackend.peach, script: "scripts/system/reboot.sh" },
        { action: "poweroff", icon: "", label: "Shutdown", keyHint: "S", accentColor: ThemeBackend.red, script: "scripts/system/poweroff.sh" },
        { action: "exit", icon: "󰍃", label: "Logout", keyHint: "E", accentColor: ThemeBackend.yellow, script: "scripts/system/exit.sh" }
    ]

    FileView {
        id: lastActionFile
        path: (typeof Caching !== "undefined" && Caching.getStateDir) ? (Caching.getStateDir("session") + "/last_action") : ""
        onLoaded: {
            let txt = text();
            if (txt) {
                applyLastAction(txt.trim());
            }
        }
    }

    Timer {
        id: uptimeRefreshTimer
        interval: 5000
        running: sessionWindow.isVisible
        repeat: true
        onTriggered: {
            if (typeof SystemInfo !== "undefined" && SystemInfo.updateUptime) {
                SystemInfo.updateUptime();
            }
        }
    }

    onIsVisibleChanged: {
        if (isVisible) {
            if (typeof SystemInfo !== "undefined" && SystemInfo.updateUptime) {
                SystemInfo.updateUptime();
            }
            lastActionFile.reload();
            applyLastAction(SessionController.lastAction);
            sessionFocusScope.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        if (Quickshell.env("SERPANTINUM_TARGET_FILE")) {
            SessionController.show();
        }
    }

    function closeOverlay() {
        SessionController.hide();
    }

    function applyLastAction(actionKey) {
        if (!actionKey) return;
        for (let i = 0; i < actionsModel.length; i++) {
            if (actionsModel[i].action === actionKey) {
                selectedIndex = i;
                return;
            }
        }
    }

    function saveLastAction(actionKey) {
        if (!actionKey) return;
        SessionController.lastAction = actionKey;
        let stateDir = (typeof Caching !== "undefined" && Caching.getStateDir) ? Caching.getStateDir("session") : "";
        if (stateDir) {
            Quickshell.execDetached(["bash", "-c", "echo -n '" + actionKey + "' > '" + stateDir + "/last_action'"]);
        }
    }

    function selectNext() {
        selectedIndex = (selectedIndex + 1) % actionsModel.length;
        if (typeof Sounds !== "undefined") {
            Sounds.playSfx("system/quick_click.wav");
        }
        saveLastAction(actionsModel[selectedIndex].action);
    }

    function selectPrevious() {
        selectedIndex = (selectedIndex - 1 + actionsModel.length) % actionsModel.length;
        if (typeof Sounds !== "undefined") {
            Sounds.playSfx("system/quick_click.wav");
        }
        saveLastAction(actionsModel[selectedIndex].action);
    }

    function triggerSelected() {
        if (selectedIndex >= 0 && selectedIndex < actionsModel.length) {
            requestAction(actionsModel[selectedIndex].action);
        }
    }

    function getGreeting() {
        let hr = new Date().getHours();
        let user = SystemInfo.username || "User";
        if (hr >= 5 && hr < 12) return "Good morning, " + user;
        if (hr >= 12 && hr < 17) return "Good afternoon, " + user;
        if (hr >= 17 && hr < 22) return "Good evening, " + user;
        return "Good night, " + user;
    }

    function getBatteryIcon() {
        if (typeof SysData === "undefined" || !SysData.batteryHasBattery) return "";
        if (SysData.batteryIsCharging) return "󰂄";
        let pct = SysData.batteryPercent;
        if (pct >= 90) return "󰁹";
        if (pct >= 80) return "󰂂";
        if (pct >= 70) return "󰂁";
        if (pct >= 60) return "󰂀";
        if (pct >= 50) return "󰁿";
        if (pct >= 40) return "󰁾";
        if (pct >= 30) return "󰁽";
        if (pct >= 20) return "󰁼";
        return "󰁺";
    }

    function executeScript(scriptRelPath) {
        closeOverlay();
        let basePath = (typeof Caching !== "undefined" && Caching.serpantinumDir) ? Caching.serpantinumDir : "";
        if (basePath) {
            Quickshell.execDetached(["bash", basePath + "/" + scriptRelPath]);
        } else {
            let fallbackCmd = "";
            if (scriptRelPath.indexOf("poweroff") !== -1) {
                fallbackCmd = "systemctl poweroff || loginctl poweroff || poweroff";
            } else if (scriptRelPath.indexOf("reboot") !== -1) {
                fallbackCmd = "systemctl reboot || loginctl reboot || reboot";
            } else if (scriptRelPath.indexOf("suspend") !== -1) {
                fallbackCmd = "systemctl suspend || loginctl suspend";
            } else if (scriptRelPath.indexOf("hibernate") !== -1) {
                fallbackCmd = "systemctl hibernate || loginctl hibernate";
            } else if (scriptRelPath.indexOf("lock") !== -1) {
                fallbackCmd = "loginctl lock-session";
            } else if (scriptRelPath.indexOf("exit") !== -1) {
                fallbackCmd = "loginctl terminate-user $USER";
            }
            if (fallbackCmd) {
                Quickshell.execDetached(["bash", "-c", fallbackCmd]);
            } else {
                Quickshell.execDetached(["bash", "-c", scriptRelPath]);
            }
        }
    }

    function requestAction(actionKey) {
        saveLastAction(actionKey);
        applyLastAction(actionKey);

        for (let i = 0; i < actionsModel.length; i++) {
            if (actionsModel[i].action === actionKey) {
                executeScript(actionsModel[i].script);
                return;
            }
        }

        if (actionKey === "lock") {
            executeScript("scripts/lock.sh");
        } else {
            executeScript("scripts/system/" + actionKey + ".sh");
        }
    }

    FocusScope {
        id: sessionFocusScope
        anchors.fill: parent
        focus: true
        opacity: sessionWindow.isVisible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Keys.onEscapePressed: (event) => {
            closeOverlay();
            event.accepted = true;
        }

        Keys.onReturnPressed: (event) => {
            triggerSelected();
            event.accepted = true;
        }

        Keys.onEnterPressed: (event) => {
            triggerSelected();
            event.accepted = true;
        }

        Keys.onSpacePressed: (event) => {
            triggerSelected();
            event.accepted = true;
        }

        Keys.onLeftPressed: (event) => {
            selectPrevious();
            event.accepted = true;
        }

        Keys.onRightPressed: (event) => {
            selectNext();
            event.accepted = true;
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Tab) {
                if (event.modifiers & Qt.ShiftModifier) {
                    selectPrevious();
                } else {
                    selectNext();
                }
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Backtab) {
                selectPrevious();
                event.accepted = true;
                return;
            }

            let k = event.text ? event.text.toLowerCase() : "";
            if (k === "l") {
                requestAction("lock");
                event.accepted = true;
            } else if (k === "s") {
                requestAction("poweroff");
                event.accepted = true;
            } else if (k === "r") {
                requestAction("reboot");
                event.accepted = true;
            } else if (k === "u") {
                requestAction("suspend");
                event.accepted = true;
            } else if (k === "h") {
                requestAction("hibernate");
                event.accepted = true;
            } else if (k === "e") {
                requestAction("exit");
                event.accepted = true;
            }
        }

        // Fullscreen Dimming Backdrop
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(ThemeBackend.crust.r, ThemeBackend.crust.g, ThemeBackend.crust.b, 0.72)

            MouseArea {
                anchors.fill: parent
                onClicked: closeOverlay()
            }
        }

        // Centered Content
        ColumnLayout {
            anchors.centerIn: parent
            spacing: Scaler.s(36)

            // Header Banner
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Scaler.s(10)

                // User Avatar
                ImageBox {
                    Layout.alignment: Qt.AlignHCenter
                    size: Scaler.s(76)
                    cornerRadius: size / 2
                    imageRadius: size / 2
                    source: SystemInfo.avatarPath !== "" ? ("file://" + SystemInfo.avatarPath) : ""
                    backgroundColor: SystemInfo.avatarPath === "" ? ThemeBackend.surface1 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: Scaler.s(34)
                        color: ThemeBackend.text
                        visible: SystemInfo.avatarPath === ""
                    }
                }

                // Greeting
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: getGreeting()
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: Scaler.s(22)
                    font.weight: Font.Bold
                    color: ThemeBackend.text
                }

                // Subtitle / Status Row
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Scaler.s(16)

                    // Battery status (if available)
                    RowLayout {
                        visible: typeof SysData !== "undefined" && Boolean(SysData.batteryHasBattery)
                        spacing: Scaler.s(5)

                        Text {
                            text: getBatteryIcon()
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: Scaler.s(14)
                            color: ThemeBackend.green
                        }

                        Text {
                            text: (typeof SysData !== "undefined" ? SysData.batteryPercent : 0) + "%"
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: Scaler.s(12)
                            color: ThemeBackend.subtext0
                        }
                    }

                    // Live Uptime
                    RowLayout {
                        visible: SystemInfo.uptime !== ""
                        spacing: Scaler.s(5)

                        Text {
                            text: "󰔚"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: Scaler.s(14)
                            color: ThemeBackend.blue
                        }

                        Text {
                            text: "Uptime: " + SystemInfo.uptime
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: Scaler.s(12)
                            color: ThemeBackend.subtext0
                        }
                    }
                }
            }

            // Action Row: All 6 options in a single horizontal row
            RowLayout {
                id: actionRow
                Layout.alignment: Qt.AlignHCenter
                spacing: Scaler.s(16)

                Repeater {
                    id: actionRepeater
                    model: sessionWindow.actionsModel

                    PowerButton {
                        required property var modelData
                        required property int index

                        icon: modelData.icon
                        label: modelData.label
                        keyHint: modelData.keyHint
                        accentColor: modelData.accentColor
                        isSelected: sessionWindow.selectedIndex === index

                        onHovered: {
                            sessionWindow.selectedIndex = index;
                            sessionWindow.saveLastAction(modelData.action);
                        }

                        onClicked: {
                            sessionWindow.requestAction(modelData.action);
                        }
                    }
                }
            }

            // Interactive Navigation Hint
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Use [← / →] to navigate  •  [Enter] to select  •  [Esc] to cancel"
                font.family: ThemeBackend.fontFamily
                font.pixelSize: Scaler.s(11)
                color: ThemeBackend.subtext0
                opacity: 0.65
            }
        }
    }
}
