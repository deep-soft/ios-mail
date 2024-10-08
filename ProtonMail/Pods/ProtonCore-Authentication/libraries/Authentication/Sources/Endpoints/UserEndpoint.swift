//
//  UserEndpoint.swift
//  ProtonCore-Authentication - Created on 16/03/2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreDataModel
import ProtonCoreNetworking

extension AuthService {

    struct UserResponse: APIDecodableResponse, Encodable {
        let user: User
    }

    struct UserInfoEndpoint: Request {
        var path: String {
            return "/users"
        }
        var method: HTTPMethod {
            return .get
        }
        var parameters: [String: Any]?

        var isAuth: Bool {
            return true
        }
        var auth: AuthCredential?
        var authCredential: AuthCredential? {
            return self.auth
        }
    }
}
