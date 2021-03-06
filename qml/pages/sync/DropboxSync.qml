/*
    TaskList - A small but mighty program to manage your daily tasks.
    Copyright (C) 2015 Murat Khairulin

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.1
import Sailfish.Silica 1.0
import ".."

Page {
    id: dropboxSync
    allowedOrientations: Orientation.All

    property bool attemptedAuth

    BusyIndicator {
        id: indicator
        running: true
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
    }

    SilicaFlickable {
        id: dbFlickable
        contentHeight: column.height
        width: parent.width
        anchors.fill: parent

        VerticalScrollDecorator { flickable: dbFlickable }

        PageHeader {
            id: syncHeader
            //: dropbox sync page title
            //% "Sync Dropbox"
            title: qsTrId("db-sync-label") + " - TaskList"
        }

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: parent.width - 2 * Theme.horizontalPageMargin
            anchors {
                top: syncHeader.bottom
                horizontalCenter: parent.horizontalCenter
            }
            visible: false

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                //: sync headline when online data is newer than the local one
                //% "Remote data cannot be updated. The remote data has been uploaded by another device."
                text: qsTrId("db-sync-interrupt-label")
            }

            SectionHeader {
                //: headline for the option section of the upgrade dialog
                //% "Choose an option"
                text: qsTrId("option-header")
            }

            Button {
                width: parent.width * 0.75
                anchors.horizontalCenter: parent.horizontalCenter
                //: button to upload the remote data
                //% "Replace remote data"
                text: qsTrId("remote-replace-label")
                onClicked: upload()
            }

            Button {
                width: parent.width * 0.75
                anchors.horizontalCenter: parent.horizontalCenter
                //: button to upload the local data
                //% "Replace local data"
                text: qsTrId("local-replace-label")
                onClicked: download()
            }

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                //: explanation what happens when sync buttons above are being pressed
                //% "Hint: Those actions replace the particular target data and can not be revoked!"
                text: qsTrId("db-sync-replace-description")
            }
        }
    }

    function toggleElements(busy) {
        indicator.running = busy
        column.visible = !busy
    }

    function upload() {
        toggleElements(true)
        taskListWindow.uploadData()
        pageStack.pop()
    }

    function download() {
        toggleElements(true)
        taskListWindow.downloadData()
        taskListWindow.justStarted = true
        pageStack.pop()
    }

    function startSync() {
        var lastSync = taskListWindow.lastSyncRevision()
        var remote = taskListWindow.getRemoteRevision()
        if (typeof lastSync === "undefined" && typeof remote === "undefined") /* no prev sync */
            upload()
        else if (lastSync === remote) /* prev sync was done from this DB */
            upload()
        else /* prev sync was done from another DB, let user decide */
            toggleElements(false)
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            // try to load credentials from database, and authorize if they're missing
            if (!taskListWindow.setDropboxCredentials()) {
                // may be user has already declined access
                if (attemptedAuth) {
                    pageStack.pop()
                    return
                }
                attemptedAuth = true
                var authLink = taskListWindow.dropboxAuthorizeLink()
                var authPage = pageStack.push("DropboxAuth.qml", { url: authLink })
                authPage.accepted.connect(function() {
                    taskListWindow.getDropboxCredentials()
                })
                // when DropboxAuth page is closed, this page becomes active
                // and this routine is executed again
            } else {
                startSync()
            }
        }
    }
}
