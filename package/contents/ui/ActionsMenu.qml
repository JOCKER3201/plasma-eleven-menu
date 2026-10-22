/*
    SPDX-FileCopyrightText: 2026 Michael Furtak <michaelfurtak@tutanota.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.plasma.extras as PlasmaExtras

// Natywne menu kontekstowe Plazmy budowane z listy akcji backendu kicker
// (rola actionList: elementy {text, icon, actionId, actionArgument,
// separator, type}). Te same dane napędzają menu kontekstowe Kickoffa.
PlasmaExtras.Menu {
    id: menu

    property var actionList: []

    signal actionClicked(string actionId, var actionArgument)

    property Instantiator _items: Instantiator {
        model: menu.actionList

        delegate: PlasmaExtras.MenuItem {
            required property var modelData

            // Separatory bywają kodowane jako {separator: true} albo
            // {type: "separator"}; element bez actionId też nie jest akcją.
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

            // Puste actionId NIGDY nie opuszcza menu — trigger(index, "", …)
            // oznacza "uruchom aplikację", a menu kontekstowe nie ma prawa
            // tego robić.
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
