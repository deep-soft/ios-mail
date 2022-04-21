//
//  MarkLegitimate.swift
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

import ProtonCore_Networking

struct MarkLegitimate: Request {

    private let messageId: MessageID

    init(messageId: MessageID) {
        self.messageId = messageId
    }

    var path: String {
        "/mail/v4/messages/\(messageId.rawValue)/mark/ham"
    }

    var method: HTTPMethod {
        .put
    }

}
