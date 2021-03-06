/****************************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Matt Vogt <matthew.vogt@jollamobile.com>
** All rights reserved.
**
** Copyright (C) 2015 Murat Khairulin
**
** This file is part of Sailfish Silica UI component package.
**
** You may use this file under the terms of BSD license as follows:
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**     * Redistributions of source code must retain the above copyright
**       notice, this list of conditions and the following disclaimer.
**     * Redistributions in binary form must reproduce the above copyright
**       notice, this list of conditions and the following disclaimer in the
**       documentation and/or other materials provided with the distribution.
**     * Neither the name of the Jolla Ltd nor the
**       names of its contributors may be used to endorse or promote products
**       derived from this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
** ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
** WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
** DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
** ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
** (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
** LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
** ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
** SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**
****************************************************************************************/

import QtQuick 2.1
import Sailfish.Silica 1.0

MouseArea {
    id: root

    property alias text: label.text
    property alias description: desc.text

    property bool checked
    property bool automaticCheck: true
    property real leftMargin
    property real rightMargin: Theme.paddingLarge
    property bool highlighted: blinker.isOn || (pressed && containsMouse)
    property bool blinking: blinker.remainingBlinks > 0
    property bool busy
    property int priorityValue
    property variant priorityColors: ["--", "-", "", "+", "++"]

    width: parent ? parent.width : Screen.width
    implicitHeight: Math.max(toggle.height, desc.y + desc.height)

    Item {
        id: toggle

        width: Theme.itemSizeExtraSmall
        height: Theme.itemSizeSmall
        anchors {
            left: parent.left
            leftMargin: root.leftMargin
        }

        GlassItem {
            id: indicator
            anchors.centerIn: parent
            opacity: root.enabled ? 1.0 : 0.4
            dimmed: !checked
            falloffRadius: checked ? defaultFalloffRadius : 0.075
            Behavior on falloffRadius {
                NumberAnimation { duration: busy ? 450 : 50; easing.type: Easing.InOutQuad }
            }
            // KLUDGE: Behavior and State don't play well together
            // http://qt-project.org/doc/qt-5/qtquick-statesanimations-behaviors.html
            // force re-evaluation of brightness when returning to default state
            brightness: { return 1.0 }
            Behavior on brightness {
                NumberAnimation { duration: busy ? 450 : 50; easing.type: Easing.InOutQuad }
            }
            color: highlighted ? Theme.highlightColor : Theme.primaryColor
        }
        states: State {
            when: root.busy
            PropertyChanges { target: indicator; brightness: busyTimer.brightness; dimmed: false; falloffRadius: busyTimer.falloffRadius; opacity: 1.0 }
        }
        Timer {
            id: busyTimer
            property real brightness: 0.4
            property real falloffRadius: 0.075
            running: busy && Qt.application.active
            interval: 500
            repeat: true
            onRunningChanged: {
                brightness = checked ? 1.0 : 0.4
                falloffRadius = checked ? indicator.defaultFalloffRadius : 0.075
            }
            onTriggered: {
                falloffRadius = falloffRadius === 0.075 ? indicator.defaultFalloffRadius : 0.075
                brightness = brightness == 0.4 ? 1.0 : 0.4
            }
        }
    }

    /* @blinks has to be an odd number */
    function startBlink(duration, blinks) {
        blinker.launch(duration, blinks)
    }

    function stopBlink() {
        blinker.reset()
    }

    Timer {
        id: blinker
        triggeredOnStart: false

        property int remainingBlinks: 0
        property bool isOn: false   /* has to be false, when an even number of blinks remains */

        function launch(duration, blinks) {
            interval = duration / blinks
            remainingBlinks = blinks
            isOn = true
            start()
        }

        function reset() {
            stop()
            isOn = false
            remainingBlinks = 0
        }

        onTriggered: {
            --remainingBlinks
            if (remainingBlinks <= 0) {
                reset()
                return
            }
            isOn = !isOn
            restart()
        }
    }

    Label {
        id: label
        opacity: root.enabled ? 1.0 : 0.4
        anchors {
            verticalCenter: toggle.verticalCenter
            // center on the first line if there are multiple lines
            verticalCenterOffset: lineCount > 1 ? (lineCount-1)*height/lineCount/2 : 0
            left: toggle.right
            right: prio.left
        }
        wrapMode: Text.NoWrap
        font.strikeout: taskListWindow.closedTaskAppearance === 2 ? !taskListWindow.statusOpen(checked) : false
        color: highlighted ? Theme.highlightColor : (checked ? Theme.primaryColor : Theme.secondaryColor)
        truncationMode: TruncationMode.Elide
    }

    Item {
        id: prio
        width: Theme.itemSizeExtraSmall
        height: Theme.itemSizeSmall
        anchors {
            right: parent.right
        }
        visible: priorityValue > 0

        Label {
            id: prioIndicator
            anchors.centerIn: parent
            text: priorityColors[priorityValue - 1]
            color: highlighted ? Theme.highlightColor : (checked ? Theme.primaryColor : Theme.secondaryColor)
        }
    }

    Label {
        id: desc
        height: text.length ? (implicitHeight + Theme.paddingMedium) : 0
        opacity: root.enabled ? 1.0 : 0.4
        anchors {
            top: label.bottom
            left: label.left
            right: parent.right
            rightMargin: Theme.paddingLarge
        }
        wrapMode: Text.NoWrap
        font.pixelSize: Theme.fontSizeExtraSmall
        color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        truncationMode: TruncationMode.Elide
    }

    onClicked: {
        if (automaticCheck) {
            checked = !checked
        }
    }
}
