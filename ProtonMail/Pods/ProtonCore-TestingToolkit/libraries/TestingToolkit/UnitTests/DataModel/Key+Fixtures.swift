//
//  Key+Fixtures.swift
//  ProtonCore-TestingToolkit-a7641708
//
//  Created by Krzysztof Siejkowski on 28/05/2021.
//

import ProtonCore_DataModel

public extension Key {

    static var dummy: Key {
        Key(keyID: .empty,
            privateKey: nil,
            keyFlags: .zero,
            token: nil,
            signature: nil,
            activation: nil,
            active: .zero,
            version: .zero,
            primary: .zero,
            isUpdated: false)
    }

    func updated(keyID: String? = nil,
                 privateKey: String? = nil,
                 keyFlags: Int? = nil,
                 token: String? = nil,
                 signature: String? = nil,
                 activation: String? = nil,
                 active: Int? = nil,
                 version: Int? = nil,
                 primary: Int? = nil,
                 isUpdated: Bool? = nil) -> Key {
        Key(keyID: keyID ?? self.keyID,
            privateKey: privateKey ?? self.privateKey,
            keyFlags: keyFlags ?? self.keyFlags,
            token: token ?? self.token,
            signature: signature ?? self.signature,
            activation: activation ?? self.activation,
            active: active ?? self.active,
            version: version ?? self.version,
            primary: primary ?? self.primary,
            isUpdated: isUpdated ?? self.isUpdated)
    }

}
