//
//  Attachment+Extension.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
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


import Foundation
import CoreData
import PromiseKit
import AwaitKit
import Crypto
import ProtonCore_DataModel


//TODO::fixme import header
extension Attachment {
    
    struct Attributes {
        static let entityName   = "Attachment"
        static let attachmentID = "attachmentID"
        static let isSoftDelete = "isSoftDeleted"
        static let message = "message"
    }
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: Attributes.entityName, in: context)!, insertInto: context)
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        if let localURL = localURL {
            do {
                try FileManager.default.removeItem(at: localURL as URL)
            } catch let ex as NSError {
                PMLog.D("Could not delete \(localURL) with error: \(ex)")
            }
        }
    }

    var isUploaded: Bool {
        attachmentID != "0" && attachmentID != .empty
    }
    
    // MARK: - This is private functions
    
    class func attachment(for attID: String, inManagedObjectContext context: NSManagedObjectContext) -> Attachment? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.attachmentID, matchingValue: attID) as? Attachment
    }
    
    
    var downloaded: Bool {
        return (localURL != nil) && (FileManager.default.fileExists(atPath: localURL!.path))
    }

    // Mark : public functions
    func encrypt(byKey key: Key, mailbox_pwd: String) -> (Data, URL)? {
        do {
            if let clearData = self.fileData, localURL == nil {
                try writeToLocalURL(data: clearData)
                self.fileData = nil
            }
            guard let localURL = self.localURL else {
                return nil
            }
            
            var error: NSError?
            let key = CryptoNewKeyFromArmored(key.publicKey, &error)
            if let err = error {
                throw err
            }
            
            let keyRing = CryptoNewKeyRing(key, &error)
            if let err = error {
                throw err
            }

            guard let aKeyRing = keyRing else {
                return nil
            }

            let cipherURL = localURL.appendingPathExtension("cipher")
            let keyPacket = try AttachmentStreamingEncryptor.encryptStream(localURL, cipherURL, aKeyRing, 2_000_000)

            return (keyPacket, cipherURL)
        } catch {
            return nil
        }
    }

    func sign(byKey key: Key, userKeys: [Data], passphrase: String) -> Data? {
        do {
            var pwd : String = passphrase
            if let token = key.token, let signature = key.signature { //have both means new schema. key is
                if let plainToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                    PMLog.D(signature)
                    pwd = plainToken
                    
                }
            } else if let token = key.token { //old schema with token - subuser. key is embed singed
                if let plainToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                    //TODO:: try to verify signature here embeded signature
                    pwd = plainToken
                }
            }
            
            var signature: String?
            if let fileData = fileData,
               let out = try fileData.signAttachment(byPrivKey: key.privateKey, passphrase: pwd) {
                signature = out
            } else if let localURL = localURL,
                      let out = try Data(contentsOf: localURL).signAttachment(byPrivKey: key.privateKey, passphrase: pwd) {
                signature = out
            }
            guard let signature = signature else {
                return nil
            }
            var error : NSError?
            let data = ArmorUnarmor(signature, &error)
            if error != nil {
                return nil
            }
            
            return data
        } catch {
            return nil
        }
    }
    
    func getSession(keys: [Data], mailboxPassword: String) throws -> SymmetricKey? {
        guard let keyPacket = self.keyPacket else {
            return nil //TODO:: error throw
        }
        let passphrase = self.message.cachedPassphrase ?? mailboxPassword
        guard let data: Data = Data(base64Encoded: keyPacket, options: NSData.Base64DecodingOptions(rawValue: 0)) else {
            return nil //TODO:: error throw
        }
        
        let sessionKey = try data.getSessionFromPubKeyPackage(passphrase, privKeys: keys)
        return sessionKey
    }
    
    func getSession(userKey: [Data], keys: [Key], mailboxPassword: String) throws -> SymmetricKey? {
        guard let keyPacket = self.keyPacket else {
            return nil
        }
        let passphrase = self.message.cachedPassphrase ?? mailboxPassword
        let data: Data = Data(base64Encoded: keyPacket, options: NSData.Base64DecodingOptions(rawValue: 0))!
        
        let sessionKey = try data.getSessionFromPubKeyPackage(userKeys: userKey, passphrase: passphrase, keys: keys)
        return sessionKey
    }
    
//    typealias base64AttachmentDataComplete = (_ based64String : String) -> Void
//    func base64AttachmentData(_ complete : @escaping base64AttachmentDataComplete) {
//        if let localURL = self.localURL, FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
//            complete( self.base64DecryptAttachment() )
//            return
//        }
//
//        if let data = self.fileData, data.count > 0 {
//            complete( self.base64DecryptAttachment() )
//            return
//        }
//
//        self.localURL = nil
//        sharedMessageDataService.fetchAttachmentForAttachment(self, downloadTask: { (taskOne : URLSessionDownloadTask) -> Void in }, completion: { (_, url, error) -> Void in
//            self.localURL = url;
//            complete( self.base64DecryptAttachment() )
//            if error != nil {
//                PMLog.D("\(String(describing: error))")
//            }
//        })
//    }
    
//    func fetchAttachmentBody() -> Promise<String> {
//        return Promise { seal in
//            async {
//                if let localURL = self.localURL, FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
//                    seal.fulfill(self.base64DecryptAttachment())
//                    return
//                }
//
//                if let data = self.fileData, data.count > 0 {
//                    seal.fulfill(self.base64DecryptAttachment())
//                    return
//                }
//
//                self.localURL = nil
//                sharedMessageDataService.fetchAttachmentForAttachment(self,
//                                                                      customAuthCredential: self.message.cachedAuthCredential,
//                                                                      downloadTask: { (taskOne : URLSessionDownloadTask) -> Void in },
//                                                                      completion: { (_, url, error) -> Void in
//                    self.localURL = url;
//                    seal.fulfill(self.base64DecryptAttachment())
//                    if error != nil {
//                        PMLog.D("\(String(describing: error))")
//                    }
//                })
//            }
//
//        }
//    }
    
    func base64DecryptAttachment(userInfo: UserInfo, passphrase: String) -> String {
//        let userInfo = self.message.cachedUser ?? user.userInfo
        let userPrivKeys = userInfo.userPrivateKeysArray
        let addrPrivKeys = userInfo.addressKeys
//        let passphrase = self.message.cachedPassphrase ?? user.mailboxPassword

        if let localURL = self.localURL {
            if let data : Data = try? Data(contentsOf: localURL as URL) {
                do {
                    if let key_packet = self.keyPacket {
                        if let keydata: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                            if let decryptData =
                                userInfo.isKeyV2 ?
                                    try data.decryptAttachment(keyPackage: keydata,
                                                               userKeys: userPrivKeys,
                                                               passphrase: passphrase,
                                                               keys: addrPrivKeys) :
                                    try data.decryptAttachment(keydata,
                                                               passphrase: passphrase,
                                                               privKeys: addrPrivKeys.binPrivKeysArray) {
                                let strBase64:String = decryptData.base64EncodedString(options: .lineLength64Characters)
                                return strBase64
                            }
                        }
                    }
                } catch let ex as NSError{
                    PMLog.D("\(ex)")
                }
            } else if let data = self.fileData, data.count > 0 {
                do {
                    if let key_packet = self.keyPacket {
                        if let keydata: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                            if let decryptData =
                                userInfo.isKeyV2 ?
                                    try data.decryptAttachment(keyPackage: keydata,
                                                               userKeys: userPrivKeys,
                                                               passphrase: passphrase,
                                                               keys: addrPrivKeys) :
                                    try data.decryptAttachment(keydata,
                                                               passphrase: passphrase,
                                                               privKeys: addrPrivKeys.binPrivKeysArray) {
                                let strBase64:String = decryptData.base64EncodedString(options: .lineLength64Characters)
                                return strBase64
                            }
                        }
                    }
                } catch let ex as NSError{
                    PMLog.D("\(ex)")
                }
            }
        }


        if let data = self.fileData {
            let strBase64:String = data.base64EncodedString(options: .lineLength64Characters)
            return strBase64
        }
        return ""
    }
    
    func inline() -> Bool {
        guard let headerInfo = self.headerInfo else {
            return false
        }
        
        let headerObject = headerInfo.parseObject()
        guard let inlineCheckString = headerObject["content-disposition"] else {
            return false
        }
        
        if inlineCheckString.contains("inline") {
            return true
        }
        return false
    }
    
    func contentID() -> String? {
        guard let headerInfo = self.headerInfo else {
            return nil
        }
        
        let headerObject = headerInfo.parseObject()
        guard let inlineCheckString = headerObject["content-id"] else {
            return nil
        }
        
        let outString = inlineCheckString.preg_replace("[<>]", replaceto: "")
        
        return outString
    }
    
    func disposition() -> String {
        guard let headerInfo = self.headerInfo else {
            return "attachment"
        }
        
        let headerObject = headerInfo.parseObject()
        guard let inlineCheckString = headerObject["content-disposition"] else {
            return "attachment"
        }
        
        let outString = inlineCheckString.preg_replace("[<>]", replaceto: "")
        
        return outString
    }
    
    func setupHeaderInfo(isInline: Bool, contentID: String?) {
        let disposition = isInline ? "inline": "attachment"
        let id = contentID ?? UUID().uuidString
        self.headerInfo = "{ \"content-disposition\": \"\(disposition)\",  \"content-id\": \"\(id)\" }"
    }

    func writeToLocalURL(data: Data) throws {
        let writeURL = try FileManager.default.url(for: .cachesDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true)
            .appendingPathComponent(UUID().uuidString)
        try data.write(to: writeURL)
        self.localURL = writeURL
    }

    func cleanLocalURLs() {
        if let localURL = localURL {
            try? FileManager.default.removeItem(at: localURL)
            self.localURL = nil
        }
        let cipherURL = localURL?.appendingPathExtension("cipher")
        if let cipherURL = cipherURL {
            try? FileManager.default.removeItem(at: cipherURL)
        }
    }
}

extension Collection where Element == Attachment {

    var areUploaded: Bool {
        allSatisfy { $0.isUploaded }
    }
}

protocol AttachmentConvertible {
    var dataSize: Int { get }
    func toAttachment (_ message:Message, fileName : String, type:String, stripMetadata: Bool) -> Promise<Attachment?>
}

// THIS IS CALLED FOR CAMERA
extension UIImage: AttachmentConvertible {
    var dataSize: Int {
        return self.toData().count
    }
    private func toData() -> Data! {
        return self.jpegData(compressionQuality: 0)
    }
    func toAttachment (_ message:Message, fileName : String, type:String, stripMetadata: Bool) -> Promise<Attachment?> {
        return Promise { seal in
            guard let context = message.managedObjectContext else {
                assert(false, "Context improperly destroyed")
                seal.fulfill(nil)
                return
            }
            CoreDataService.shared.enqueue(context: context) { (context) in
                if let fileData = self.toData() {
                    let attachment = Attachment(context: context)
                    attachment.attachmentID = "0"
                    attachment.fileName = fileName
                    attachment.mimeType = "image/jpg"
                    attachment.fileData = nil
                    attachment.fileSize = fileData.count as NSNumber
                    attachment.isTemp = false
                    attachment.keyPacket = ""
                    let dataToWrite = stripMetadata ? fileData.strippingExif() : fileData
                    try? attachment.writeToLocalURL(data: dataToWrite)
                
                    attachment.message = message
                    
                    let number = message.numAttachments.int32Value
                    let newNum = number > 0 ? number + 1 : 1
                    message.numAttachments = NSNumber(value: max(newNum, Int32(message.attachments.count)))
                    
                    var error: NSError? = nil
                    error = context.saveUpstreamIfNeeded()
                    if error != nil {
                        PMLog.D("toAttachment () with error: \(String(describing: error))")
                    }
                    seal.fulfill(attachment)
                }
            }
        }
    }
}

// THIS IS CALLED FOR INLINE AND PHOTO_LIBRARY AND DOCUMENT
extension Data: AttachmentConvertible {
    var dataSize: Int {
        return self.count
    }
    func toAttachment (_ message:Message, fileName : String, stripMetadata: Bool) -> Promise<Attachment?> {
        return self.toAttachment(message, fileName: fileName, type: "image/jpg", stripMetadata: stripMetadata)
    }
    
    func toAttachment (_ message:Message, fileName : String, type:String, stripMetadata: Bool) -> Promise<Attachment?> {
        return Promise { seal in
            guard let context = message.managedObjectContext else {
                assert(false, "Context improperly destroyed")
                seal.fulfill(nil)
                return
            }
            CoreDataService.shared.enqueue(context: context) { (context) in
                let attachment = Attachment(context: context)//TODO:: need check context nil or not instead of !
                attachment.attachmentID = "0"
                attachment.fileName = fileName
                attachment.mimeType = type
                attachment.fileData = nil
                attachment.fileSize = self.count as NSNumber
                attachment.isTemp = false
                attachment.keyPacket = ""
                try? attachment.writeToLocalURL(data: stripMetadata ? self.strippingExif() : self)
                attachment.message = message
                
                let number = message.numAttachments.int32Value
                let newNum = number > 0 ? number + 1 : 1
                message.numAttachments = NSNumber(value: Swift.max(newNum, Int32(message.attachments.count)))
                
                var error: NSError? = nil
                error = attachment.managedObjectContext?.saveUpstreamIfNeeded()
                if error != nil {
                    PMLog.D(" toAttachment () with error: \(String(describing: error))")
                }
                seal.fulfill(attachment)
            }
        }
    }
}

// THIS IS CALLED FROM SHARE EXTENSION
extension URL: AttachmentConvertible {
    func toAttachment(_ message: Message, fileName: String, type: String, stripMetadata: Bool) -> Promise<Attachment?> {
        return Promise { seal in
            guard let context = message.managedObjectContext else {
                assert(false, "Context improperly destroyed")
                seal.fulfill(nil)
                return
            }
            CoreDataService.shared.enqueue(context: context) { (context) in
                let attachment = Attachment(context: context)
                attachment.attachmentID = "0"
                attachment.fileName = fileName
                attachment.mimeType = type
                attachment.fileData = nil
                attachment.fileSize = NSNumber(value: self.dataSize)
                attachment.isTemp = false
                attachment.keyPacket = ""
                attachment.localURL = stripMetadata ? self.strippingExif() : self
                
                attachment.message = message
                
                let number = message.numAttachments.int32Value
                let newNum = number > 0 ? number + 1 : 1
                message.numAttachments = NSNumber(value: max(newNum, Int32(message.attachments.count)))
                
                var error: NSError? = nil
                error = attachment.managedObjectContext?.saveUpstreamIfNeeded()
                if error != nil {
                    PMLog.D(" toAttachment () with error: \(String(describing: error))")
                }
                seal.fulfill(attachment)
            }
        }
    }
    
    var dataSize: Int {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: self.path),
            let size = attributes[.size] as? NSNumber else
        {
            return 0
        }
        return size.intValue
    }
}
