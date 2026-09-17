import QtQuick
import QtQuick.Layouts
import "../"

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string keyHint: ""
    property color accentColor: ThemeBackend.blue
    property bool isSelected: false

    implicitWidth: Scaler.s(136)
    implicitHeight: Scaler.s(136)

    signal clicked()
    signal hovered()

    property real flashOpacity: 0.0

    function trigger() {
        root.flashOpacity = 0.25;
        flashAnim.start();
        if (typeof Sounds !== "undefined") {
            Sounds.playSfx("reusables/clickbutton/click.wav");
        }
        root.clicked();
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: ThemeBackend.clampedBorderRadius
        color: root.isSelected
            ? Qt.tint(ThemeBackend.surface1, Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16))
            : (mouseArea.containsMouse ? ThemeBackend.surface1 : ThemeBackend.surface0)
        border.color: (root.isSelected || mouseArea.containsMouse) ? root.accentColor : ThemeBackend.surface1
        border.width: root.isSelected ? 2 : 1

        scale: mouseArea.pressed ? 0.96 : (root.isSelected ? 1.05 : (mouseArea.containsMouse ? 1.03 : 1.0))
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Scaler.s(8)

            Text {
                text: root.icon
                font.family: "Iosevka Nerd Font"
                font.pixelSize: Scaler.s(38)
                color: root.accentColor
                Layout.alignment: Qt.AlignHCenter

                scale: (root.isSelected || mouseArea.containsMouse) ? 1.12 : 1.0
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Scaler.s(3)

                Text {
                    text: root.label
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: Scaler.s(13)
                    font.weight: Font.Bold
                    color: ThemeBackend.text
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    visible: root.keyHint !== ""
                    text: "[" + root.keyHint + "]"
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: Scaler.s(10)
                    font.weight: Font.Medium
                    color: root.isSelected ? root.accentColor : ThemeBackend.subtext0
                    opacity: root.isSelected ? 0.95 : 0.5
                    Layout.alignment: Qt.AlignHCenter

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                }
            }
        }

        // Selected Pill Indicator
        Rectangle {
            id: selectionIndicator
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Scaler.s(6)
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.isSelected ? Scaler.s(28) : 0
            height: Scaler.s(3)
            radius: height / 2
            color: root.accentColor
            opacity: root.isSelected ? 1.0 : 0.0

            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        // Trigger flash feedback
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#ffffff"
            opacity: root.flashOpacity
            PropertyAnimation on opacity { id: flashAnim; to: 0; duration: 250; easing.type: Easing.OutExpo }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.hovered()
        onClicked: root.trigger()
    }
}
