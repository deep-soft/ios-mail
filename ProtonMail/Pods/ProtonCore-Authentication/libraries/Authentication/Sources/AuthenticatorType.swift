//
//  AuthenticatorType.swift
//  ProtonCore-Authentication
//
//  Created by Krzysztof Siejkowski on 20/05/2021.
//

import Foundation
import ProtonCore_APIClient
import ProtonCore_DataModel
import ProtonCore_Networking

public protocol AuthenticatorInterface {

    func authenticate(username: String, password: String, completion: @escaping Authenticator.Completion)

    func confirm2FA(_ twoFactorCode: String, context: TwoFactorContext, completion: @escaping Authenticator.Completion)

    func refreshCredential(_ oldCredential: Credential, completion: @escaping Authenticator.Completion)

    func checkAvailable(_ username: String, completion: @escaping (Result<(), AuthErrors>) -> Void)

    func setUsername(username: String, completion: @escaping (Result<(), AuthErrors>) -> Void)

    func setUsername(_ credential: Credential?,
                     username: String,
                     completion: @escaping (Result<(), AuthErrors>) -> Void)

    func createAddress(_ credential: Credential?,
                       domain: String,
                       displayName: String?,
                       siganture: String?,
                       completion: @escaping (Result<Address, AuthErrors>) -> Void)

    func getUserInfo(_ credential: Credential?, completion: @escaping (Result<User, AuthErrors>) -> Void)

    func getAddresses(_ credential: Credential?, completion: @escaping (Result<[Address], AuthErrors>) -> Void)

    func getKeySalts(_ credential: Credential?, completion: @escaping (Result<[KeySalt], AuthErrors>) -> Void)

    func closeSession(_ credential: Credential,
                      completion: @escaping (Result<AuthService.EndSessionResponse, AuthErrors>) -> Void)

    func getRandomSRPModulus(completion: @escaping (Result<AuthService.ModulusEndpointResponse, AuthErrors>) -> Void)

    func createAddressKey(_ credential: Credential?,
                          address: Address,
                          password: String,
                          salt: Data,
                          primary: Bool,
                          completion: @escaping (Result<Key, AuthErrors>) -> Void)

    func setupAccountKeys(_ credential: Credential?,
                          addresses: [Address],
                          password: String,
                          completion: @escaping (Result<(), AuthErrors>) -> Void)
}

// Workaround for the lack of default parameters in protocols

public extension AuthenticatorInterface {
    func setUsername(username: String, completion: @escaping (Result<(), AuthErrors>) -> Void) {
        setUsername(nil, username: username, completion: completion)
    }
    func getKeySalts(completion: @escaping (Result<[KeySalt], AuthErrors>) -> Void) {
        getKeySalts(nil, completion: completion)
    }
    func getUserInfo(completion: @escaping (Result<User, AuthErrors>) -> Void) {
        getUserInfo(nil, completion: completion)
    }
    func getAddresses(completion: @escaping (Result<[Address], AuthErrors>) -> Void) {
        getAddresses(nil, completion: completion)
    }
    func createAddress(domain: String, completion: @escaping (Result<Address, AuthErrors>) -> Void) {
        createAddress(nil, domain: domain, displayName: nil, siganture: nil, completion: completion)
    }
    func createAddressKey(address: Address, password: String, salt: Data, primary: Bool,
                          completion: @escaping (Result<Key, AuthErrors>) -> Void) {
        createAddressKey(nil, address: address, password: password, salt: salt, primary: primary, completion: completion)
    }
    func setupAccountKeys(addresses: [Address], password: String, completion: @escaping (Result<(), AuthErrors>) -> Void) {
        setupAccountKeys(nil, addresses: addresses, password: password, completion: completion)
    }
}
