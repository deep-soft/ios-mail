//
//  ContactsAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/10/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


// MARK : Get contacts part
class ContactsRequest : ApiRequest<ContactsResponse> {
    var page : Int = 0
    var max : Int = 100
    
    init(page: Int, pageSize : Int) {
        self.page = page
        self.max = pageSize
    }
    
    override public func path() -> String {
        return ContactsAPI.path +  AppConstants.DEBUG_OPTION
    }
    
    override public func apiVersion() -> Int {
        return ContactsAPI.v_get_contacts
    }
}

//
class ContactsResponse : ApiResponse {
    var total : Int = -1
    var contacts : [[String : Any]] = []
    override func ParseResponse (_ response: [String : Any]!) -> Bool {
        self.total = response?["Total"] as? Int ?? -1
        self.contacts = response?["Contacts"] as? [[String : Any]] ?? []
        return true
    }
}

// MARK : Get messages part
class ContactEmailsRequest : ApiRequest<ContactEmailsResponse> {
    var page : Int = 0
    var max : Int = 100
    
    init(page: Int, pageSize : Int) {
        self.page = page
        self.max = pageSize
    }
    
    override public func path() -> String {
        return ContactsAPI.path + "/emails" +  AppConstants.DEBUG_OPTION
    }
    
    override func toDictionary() -> [String : Any]? {
        return ["Page" : page, "PageSize" : max]
    }
    
    override public func apiVersion() -> Int {
        return ContactsAPI.v_get_contact_emails
    }
    
    override func method() -> APIService.HTTPMethod {
        return .get
    }
}


class ContactEmailsResponse : ApiResponse {
    var total : Int = -1
    var contacts : [[String : Any]] = []
    override func ParseResponse (_ response: [String : Any]!) -> Bool {
        self.total = response?["Total"] as? Int ?? -1
        if let tempContacts = response?["ContactEmails"] as? [[String : Any]] {
            for contact in tempContacts {
                if let contactID = contact["ContactID"] as? String, let name = contact["Name"] as? String {
                    var found = false
                    for (index, var c) in contacts.enumerated() {
                        if let obj = c["ID"] as? String, obj == contactID {
                            found = true
                            if var emails = c["ContactEmails"] as? [[String : Any]] {
                                emails.append(contact)
                                c["ContactEmails"] = emails
                            } else {
                                c["ContactEmails"] = [contact]
                            }
                            contacts[index] = c
                        }
                    }
                    if !found {
                        let newContact : [String : Any] = [
                            "ID" : contactID,
                            "Name" : name,
                            "ContactEmails" : [contact]
                        ]
                        self.contacts.append(newContact)
                    }
                }
            }
        }
        PMLog.D( self.contacts.json(prettyPrinted: true) )
        return true
    }
}

// MARK : Get messages part
final class ContactDetailRequest<T : ApiResponse> : ApiRequest<T> {
    
    let contactID : String
    
    init(cid : String) {
        self.contactID = cid
    }

    override public func path() -> String {
        return ContactsAPI.path + "/" + self.contactID +  AppConstants.DEBUG_OPTION
    }
    
    override public func apiVersion() -> Int {
        return ContactsAPI.v_get_details
    }
    
    override func method() -> APIService.HTTPMethod {
        return .get
    }
}

//
class ContactDetailResponse : ApiResponse {
    var contact : [String : Any]?
    override func ParseResponse (_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        contact = response["Contact"] as? [String : Any]
        return true
    }
}


final class ContactEmail : Package {
    let id : String
    let email : String
    let type : String

    // e email  //    "Email": "feng@protonmail.com",
    // t type   //    "Type": "Email" //This type is raw value it is vcard type!!!
    init(e : String, t: String) {
        self.email = e
        self.type = t
        self.id = ""
    }
    
    func toDictionary() -> [String : Any]? {
        return [
            "ID" : self.id,
            "Email": self.email,
            "Type": self.type
        ]
    }
}

// 0, 1, 2, 3 // 0 for cleartext, 1 for encrypted only (not used), 2 for signed, 3 for both
enum CardDataType : Int {
    case PlainText = 0
    case EncryptedOnly = 1
    case SignedOnly = 2
    case SignAndEncrypt = 3
}

// add contacts Card object
final class CardData : Package {
    let type : CardDataType
    let data : String
    let sign : String
    
    // t   "Type": CardDataType
    // d   "Data": ""
    // s   "Signature": ""
    init(t : CardDataType, d: String, s : String) {
        self.data = d
        self.type = t
        self.sign = s
    }
    
    func toDictionary() -> [String : Any]? {
        return [
            "Data": self.data,
            "Type": self.type.rawValue,
            "Signature": self.sign
        ]
    }
}

extension Array where Element: CardData {
    func toDictionary() -> [[String : Any]] {
        var dicts = [[String : Any]]()
        for element in self {
            if let e = element.toDictionary() {
                dicts.append(e)
            }
        }
        return dicts
    }
}


final class ContactAddRequest<T : ApiResponse> : ApiRequest<T> {
    let cardsList : [[CardData]]
    init(cards: [CardData]) {
        self.cardsList = [cards]
    }
    
    init(cards: [[CardData]]) {
        self.cardsList = cards
    }
    
    override public func path() -> String {
        return ContactsAPI.path +  AppConstants.DEBUG_OPTION
    }
    
    override public func apiVersion() -> Int {
        return ContactsAPI.v_add_contacts
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
    
    override func toDictionary() -> [String : Any]? {
        var contacts : [Any] = [Any]()
       
        
        for cards in self.cardsList {
            var cards_dict : [Any] = [Any] ()
            for c in cards {
                if let dict = c.toDictionary() {
                    cards_dict.append(dict)
                }
            }
            let contact : [String : Any] = [
                "Cards": cards_dict
            ]
            contacts.append(contact)
        }
        
        return [
            "Contacts" : contacts,
            "Overwrite": 1, // when UID conflict, 0 = error, 1 = overwrite
            "Groups": 1, // import groups if present, will silently skip if group does not exist
            "Labels": 0 // import Notes: change to 0 for now , we need change to 1 later
        ]
    }
}

final class ContactAddResponse : ApiResponse {
    
    var results : [Any?] = []

    override func ParseResponse (_ response: [String : Any]!) -> Bool {
        PMLog.D( response.json(prettyPrinted: true) )
        if let responses = response["Responses"] as? [[String : Any]] {
            for res in responses {
                if let response = res["Response"] as? [String : Any] {
                    let code = response["Code"] as? Int
                    let errorMessage = response["Error"] as? String
                    let errorDetails = response["ErrorDescription"] as? String
                    
                    if code != 1000 && code != 1001 {
                        results.append(NSError.protonMailError(code ?? 1000, localizedDescription: errorMessage ?? "", localizedFailureReason: errorDetails, localizedRecoverySuggestion: nil))
                    } else {
                        results.append(response["Contact"])
                    }
                }
            }
        }
        return true
    }
}

final class ContactDeleteRequest<T : ApiResponse> : ApiRequest<T> {
    var IDs : [String] = []
    init(ids: [String]) {
        IDs = ids
    }
    
    override public func path() -> String {
        return ContactsAPI.path + "/delete" +  AppConstants.DEBUG_OPTION
    }
    
    override public func apiVersion() -> Int {
        return ContactsAPI.v_delete_contacts
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func toDictionary() -> [String : Any]?  {
        return ["IDs": IDs]
    }
}


final class ContactUpdateRequest<T : ApiResponse> : ApiRequest<T> {
    var contactID : String
    let Cards : [CardData]
    
    init(contactid: String,
         cards: [CardData]) {
        self.contactID = contactid
        self.Cards = cards
    }
    
    override public func path() -> String {
        return ContactsAPI.path + "/" + self.contactID +  AppConstants.DEBUG_OPTION
    }
    
    override public func apiVersion() -> Int {
        return ContactsAPI.v_update_contact
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func toDictionary() -> [String : Any]? {
        var cards_dict : [Any] = [Any] ()
        for c in self.Cards {
            if let dict = c.toDictionary() {
                cards_dict.append(dict)
            }
        }
        return [
            "Cards": cards_dict
        ]
    }
}

// Contact group APIs
/*
 Questions
 1. Is the contact group ordering sorted locally, or are we following the API?
 */

/// Add designated contact emails into a certain contact group
final class ContactLabelAnArrayOfContactEmailsRequest<T: ApiResponse>: ApiRequest<T>
{
    
}


/// Process the response of ContactLabelAnArrayOfContactEmailsRequest
final class ContactLabelAnArrayOfContactEmailsResponse: ApiResponse {
    override func ParseResponse (_ response: [String : Any]!) -> Bool {
        return true
    }
}


/// Remove designated contact emails from a certain contact group
final class ContactUnlabelAnArrayOfContactEmailsRequest<T: ApiResponse>: ApiRequest<T>
{
    
}


/// Process the response of ContactUnlabelAnArrayOfContactEmailsRequest
final class ContactUnlabelAnArrayOfContactEmailsResponse: ApiResponse {
    override func ParseResponse (_ response: [String : Any]!) -> Bool {
        return true
    }
}
