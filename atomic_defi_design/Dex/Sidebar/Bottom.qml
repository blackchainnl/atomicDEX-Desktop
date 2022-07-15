import QtQuick 2.12
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.15
import App 1.0
import Dex.Themes 1.0 as Dex

import "../Components"
import "../Constants"

MouseArea
{
    id: root

    signal supportClicked()
    signal settingsClicked()

    height: lineHeight * 3
    hoverEnabled: true
    propagateComposedEvents: true

    Connections
    {
        target: parent.parent

        function onIsExpandedChanged()
        {
            if (isExpanded) waitForSidebarExpansionAnimation.start();
            else
            {
                settingsLine.label.opacity = 0;
                supportLine.label.opacity = 0;
                privacyLine.label.opacity = 0;
            }
        }
    }

    NumberAnimation
    {
        id: waitForSidebarExpansionAnimation
        targets: [settingsLine.label, supportLine.label, privacyLine.label]
        properties: "opacity"
        duration: 200
        from: 0
        to: 0
        onFinished: labelsOpacityAnimation.start()
    }

    NumberAnimation
    {
        id: labelsOpacityAnimation
        targets: [settingsLine.label, supportLine.label, privacyLine.label]
        properties: "opacity"
        duration: 350
        from: 0.0
        to: 1
    }

    ColumnLayout
    {
        anchors.fill: parent
        FigurativeLine
        {
            id: settingsLine

            Layout.fillWidth: true
            label.text: isExpanded ? qsTr("Settings") : ""
            icon.source: General.image_path + "menu-settings-white.svg"
            onClicked: settingsClicked()
        }

        FigurativeLine
        {
            id: supportLine

            Layout.fillWidth: true
            label.text: isExpanded ? qsTr("Support") : ""
            icon.source: General.image_path + "menu-support-white.png"
            onClicked: supportClicked(type)
        }

        Line
        {
            id: privacyLine

            Layout.fillWidth: true
            label.text: qsTr("Privacy")
            label.visible: isExpanded

            onClicked:
            {
                console.log(">> privacy_mode: " + General.privacy_mode)
                console.log(">> privacySwitch.checked: " + privacySwitch.checked)
                if (General.privacy_mode) {
                    privacySwitch.checked = true
                    var wallet_name = API.app.wallet_mgr.wallet_default_name
                    
                    let dialog = app.getText(
                    {
                        title: qsTr("Disable Privacy?"),
                        text: qsTr("Enter password to confirm"),
                        standardButtons: Dialog.Yes | Dialog.Cancel,
                        closePolicy: Popup.NoAutoClose,
                        warning: true,
                        iconColor: Dex.CurrentTheme.noColor,
                        isPassword: true,
                        placeholderText: qsTr("Type password"),
                        yesButtonText: qsTr("Confirm"),
                        cancelButtonText: qsTr("Cancel"),

                        onAccepted: function(text)
                        {
                            if (API.app.wallet_mgr.confirm_password(wallet_name, text))
                            {
                                General.privacy_mode = false;
                                privacySwitch.checked = false
                                app.showDialog(
                                {
                                    title: qsTr("Privacy status"),
                                    text: qsTr("Privacy mode disabled successfully"),
                                    yesButtonText: qsTr("Ok"), titleBold: true,
                                    standardButtons: Dialog.Ok
                                })
                                console.log("+ privacy_mode: " + General.privacy_mode)
                            }
                            else
                            {
                                app.showDialog(
                                {
                                    title: qsTr("Wrong password!"),
                                    text: "%1 ".arg(wallet_name) + qsTr("wallet password is incorrect"),
                                    warning: true,
                                    standardButtons: Dialog.Ok, titleBold: true,
                                    yesButtonText: qsTr("Ok"),
                                })
                                console.log("- privacy_mode: " + General.privacy_mode)
                            }
                            console.log("<< privacySwitch.checked: " + privacySwitch.checked)
                            dialog.close()
                            dialog.destroy()
                        }
                    })
                }
                else {
                    General.privacy_mode = true;
                    privacySwitch.checked = true
                    console.log("= privacy_mode: " + General.privacy_mode)
                    console.log("<< privacySwitch.checked: " + privacySwitch.checked)
                }
            }

            DefaultSwitch
            {
                id: privacySwitch

                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                scale: 0.75
                mouseArea.hoverEnabled: true
                onClicked: parent.clicked()
            }
        }
    }
}
