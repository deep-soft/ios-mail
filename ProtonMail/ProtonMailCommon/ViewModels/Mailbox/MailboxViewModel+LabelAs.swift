//
//  MailboxViewModel+LabelAs.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations

// MARK: - Label as functinos
extension MailboxViewModel: LabelAsActionSheetProtocol {
    func handleLabelAsAction(messages: [Message], shouldArchive: Bool, currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType]) {
        for (label, markType) in currentOptionsStatus {
            if selectedLabelAsLabels
                .contains(where: { $0.labelID == label.location.labelID}) {
                // Add to message which does not have this label
                let messageToApply = messages.filter({ !$0.contains(label: label.location.labelID )})
                messageService.label(messages: messageToApply,
                                     label: label.location.labelID,
                                     apply: true,
                                     shouldFetchEvent: false)
            } else if markType != .dash { // Ignore the option in dash
                let messageToRemove = messages.filter({ $0.contains(label: label.location.labelID )})
                messageService.label(messages: messageToRemove,
                                     label: label.location.labelID,
                                     apply: false,
                                     shouldFetchEvent: false)
            }
        }

        user.eventsService.fetchEvents(labelID: labelID)

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            messageService.move(messages: messages,
                                to: Message.Location.archive.rawValue,
                                queue: true)
        }
    }
    
    func handleLabelAsAction(conversations: [Conversation], shouldArchive: Bool, currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType]) {
        for (label, markType) in currentOptionsStatus {
            if selectedLabelAsLabels
                .contains(where: { $0.labelID == label.location.labelID}) {
                // Add to message which does not have this label
                let conversationsToApply = conversations.filter({ !$0.getLabelIds().contains(label.location.labelID )})
                conversationService.label(conversationIDs: conversationsToApply.map(\.conversationID),
                                          as: label.location.labelID) { _ in }
            } else if markType != .dash { // Ignore the option in dash
                let conversationsToRemove = conversations.filter({ $0.getLabelIds().contains(label.location.labelID )})
                conversationService.unlabel(conversationIDs: conversationsToRemove.map(\.conversationID),
                                            as: label.location.labelID) { _ in }
            }
        }

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            conversationService.move(conversationIDs: conversations.map(\.conversationID), from: "",
                                     to: Message.Location.archive.rawValue) { _ in }
        }
    }

    func updateSelectedLabelAsDestination(menuLabel: MenuLabel?, isOn: Bool) {
        if let label = menuLabel {
            if isOn {
                selectedLabelAsLabels.insert(label.location)
            } else {
                selectedLabelAsLabels.remove(label.location)
            }
        } else {
            selectedLabelAsLabels.removeAll()
        }
    }
}
