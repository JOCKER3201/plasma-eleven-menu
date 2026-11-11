/*
    SPDX-FileCopyrightText: 2026 JOCKER3201 <noreply@users.noreply.github.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.plasma.extras as PlasmaExtras

// A native Plasma context menu built from a kicker-backend action list
// (the actionList role: {text, icon, actionId, actionArgument, separator,
// type} elements). The same data drives Kickoff's context menus.
PlasmaExtras.Menu {
    id: menu

    property var actionList: []

    signal actionClicked(string actionId, var actionArgument)

    property Instantiator _items: Instantiator {
        model: menu.actionList

        delegate: PlasmaExtras.MenuItem {
            required property var modelData

            // Separators are sometimes encoded as {separator: true} and
            // sometimes as {type: "separator"}; an element without an
            // actionId is not an action either.
            readonly property string entryActionId: modelData.actionId ?? ""
            readonly property bool isSeparator: modelData.separator === true
                || modelData.type === "separator"
                || (entryActionId.length === 0 && (modelData.text ?? "").length === 0)
            readonly property bool isTitle: modelData.type === "title"

            text: modelData.text ?? ""
            icon: modelData.icon
            separator: isSeparator
            section: isTitle
            enabled: !isSeparator && !isTitle && entryActionId.length > 0
                && modelData.enabled !== false

            // An empty actionId NEVER leaves the menu — trigger(index, "", …)
            // means "launch the application", and a context menu has no
            // business doing that.
            onClicked: {
                if (entryActionId.length > 0) {
                    menu.actionClicked(entryActionId, modelData.actionArgument)
                }
            }
        }

        onObjectAdded: (index, object) => menu.addMenuItem(object, null)
        onObjectRemoved: (index, object) => menu.removeMenuItem(object)
    }
}
