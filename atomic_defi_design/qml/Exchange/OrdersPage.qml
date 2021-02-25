import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3

import Qaterial 1.0 as Qaterial

import "../Components"
import "../Constants"
import ".."

Item {
    id: root

    readonly property date default_min_date: new Date("2019-01-01")
    readonly property date default_max_date: new Date(new Date().setDate(new Date().getDate() + 30))

    property var list_model: API.app.orders_mdl
    property var list_model_proxy: API.app.orders_mdl.orders_proxy_mdl
    property int page_index

    property alias title: order_list.title
    //property alias empty_text: order_list.empty_text
    property alias items: order_list.items

    property bool is_history: false

    property string recover_funds_result: '{}'

    function onRecoverFunds(order_id) {
        const result = API.app.recover_fund(order_id)
        console.log("Refund result: ", result)
        recover_funds_result = result
        recover_funds_modal.open()
    }

//    function inCurrentPage() {
//        return  exchange.inCurrentPage() &&
//                exchange.current_page === page_index
//    }

    function applyDateFilter() {
        list_model_proxy.filter_minimum_date = min_date.date

        if(max_date.date < min_date.date)
            max_date.date = min_date.date

        list_model_proxy.filter_maximum_date = max_date.date
    }

    function applyTickerFilter() {
        list_model_proxy.set_coin_filter(combo_base.currentValue + "/" + combo_rel.currentValue)
    }
    function applyTickerFilter2(ticker1, ticker2) {
        list_model_proxy.set_coin_filter(ticker1 + "/" + ticker2)
    }

    function applyFilter() {
        applyDateFilter()
        applyTickerFilter2(combo_base.currentTicker, combo_rel.currentTicker)
    }

    Component.onCompleted: {
        list_model_proxy.is_history = root.is_history
        applyFilter()
        list_model_proxy.apply_all_filtering()
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter

        anchors.fill: parent
        anchors.bottomMargin: is_history? 0 : 10
        spacing: 15

        // Bottom part
        Item {
            id: orders_settings
            property bool displaySetting: false
            Layout.fillWidth: true
            Layout.preferredHeight: displaySetting? 80 : 30
            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 150
                }
            }

            Rectangle {
                width: parent.width
                height: orders_settings.displaySetting? 50 : 10
                Behavior on height {
                    NumberAnimation {
                        duration: 150
                    }
                }
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -15
                visible: false//orders_settings.height>75
                color: Style.colorTheme5
            }

            Row {
                x: 5
                y: 0
                spacing: 0
                //anchors.verticalCenter: parent.verticalCenter
                Qaterial.OutlineButton {
                    icon.source: Qaterial.Icons.filter
                    text: "Filter"
                    foregroundColor:Style.colorWhite5
                    anchors.verticalCenter: parent.verticalCenter
                    outlinedColor: Style.colorTheme5
                    onClicked: orders_settings.displaySetting = !orders_settings.displaySetting
                }
                Qaterial.Button {
                    visible: root.is_history
                    height: 40
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Export CSV")
                    enabled: list_model.length > 0
                    onClicked: {
                        export_csv_dialog.folder = General.os_file_prefix + API.app.settings_pg.get_export_folder()
                        export_csv_dialog.open()
                    }
                }

            }
            Row {
                anchors.right: parent.right
                y: 0
                rightPadding: 5
                //anchors.verticalCenter: parent.verticalCenter
                PrimaryButton {
                    visible: root.is_history
                    Layout.leftMargin: 30
                    text: qsTr("Apply Filter")
                    enabled: list_model_proxy.can_i_apply_filtering
                    onClicked: list_model_proxy.apply_all_filtering()
                    anchors.verticalCenter: parent.verticalCenter
                }
                Qaterial.OutlineButton {
                    icon.source: Qaterial.Icons.close
                    text: "Cancel All"
                    visible: !is_history
                    foregroundColor: Qaterial.Colors.pink
                    anchors.verticalCenter: parent.verticalCenter
                    outlinedColor: Style.colorTheme5
                    onClicked: API.app.trading_pg.cancel_order(list_model_proxy.get_filtered_ids())
                }
            }
            RowLayout {
                visible: orders_settings.height>75
                width: parent.width-20
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -15
                spacing: 10
                DefaultSweetComboBox {
                    id: combo_base
                    model: API.app.portfolio_pg.global_cfg_mdl.all_proxy
                    onCurrentTickerChanged: applyFilter()
                    width: 150
                    height: 100
                    valueRole: "ticker"
                    textRole: 'ticker'
                }
                Qaterial.ColorIcon {
                    Layout.alignment: Qt.AlignVCenter
                    source: Qaterial.Icons.swapHorizontal
                    DefaultMouseArea {
                        id: swap_button
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            const base_idx = combo_base.currentIndex
                            combo_base.currentIndex = combo_rel.currentIndex
                            combo_rel.currentIndex = base_idx
                        }
                    }
                }

                DefaultSweetComboBox {
                    id: combo_rel
                    model: API.app.portfolio_pg.global_cfg_mdl.all_proxy//combo_base.model
                    onCurrentTickerChanged: applyFilter()
                    width: 150
                    height: 100
                    valueRole: "ticker"
                    textRole: 'ticker'

                }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Qaterial.TextFieldDatePicker {
                    id: min_date
                    title: qsTr("From")
                    from: default_min_date
                    to: default_max_date
                    date: default_min_date
                    onAccepted: applyDateFilter()
                    Layout.preferredWidth: 130
                }

                Qaterial.TextFieldDatePicker {
                    id: max_date
                    enabled: min_date.enabled
                    title: qsTr("To")
                    from: min_date.date
                    to: default_max_date
                    date: default_max_date
                    onAccepted: applyDateFilter()
                    Layout.preferredWidth: 130
                }


            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            spacing: parent.spacing

            OrderList {
                id: order_list
                items: list_model
                is_history: root.is_history
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

        }

        ModalLoader {
            id: order_modal
            sourceComponent: OrderModal {}
        }
    }

    FileDialog {
        id: export_csv_dialog

        title: qsTr("Please choose the CSV export name and location")
        selectMultiple: false
        selectExisting: false
        selectFolder: false

        defaultSuffix: "csv"
        nameFilters: [ "CSV files (*.csv)", "All files (*)" ]

        onAccepted: {
            const path = fileUrl.toString()

            // Export
            console.log("Exporting to CSV: " + path)
            API.app.exporter_service.export_swaps_history_to_csv(path.replace(General.os_file_prefix, ""))

            // Open the save folder
            const folder_path = path.substring(0, path.lastIndexOf("/"))
            Qt.openUrlExternally(folder_path)
        }
        onRejected: {
            console.log("CSV export cancelled")
        }
    }
    ModalLoader {
        id: recover_funds_modal
        sourceComponent: LogModal {
            header: qsTr("Recover Funds Result")
            field.text: General.prettifyJSON(recover_funds_result)

            onClosed: recover_funds_result = "{}"
        }
    }
}

