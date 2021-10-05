//
//  AttachmentsTableViewController.swift
//  ProtonMail - Created on 10/16/15.
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


import UIKit
import Photos
import AssetsLibrary
import MCSwipeTableViewCell

protocol AttachmentsTableViewControllerDelegate : AnyObject {
    func attachments(_ attViewController: AttachmentsTableViewController, didFinishPickingAttachments: [Any]) -> Void
    func attachments(_ attViewController: AttachmentsTableViewController, didPickedAttachment: Attachment) -> Void
    func attachments(_ attViewController: AttachmentsTableViewController, didDeletedAttachment: Attachment) -> Void
    func attachments(_ attViewController: AttachmentsTableViewController, didReachedSizeLimitation: Int) -> Void
    func attachments(_ attViewController: AttachmentsTableViewController, error: String) -> Void
}

private struct AttachInfo {
    let objectID: String
    let name: String
    let size: Int
    let mimeType: String
    var attachmentID: String
    var isUploaded: Bool {
        attachmentID != "0" && attachmentID != .empty
    }

    init(attachment: Attachment) {
        self.objectID = attachment.objectID.uriRepresentation().absoluteString
        self.name = attachment.fileName
        self.size = attachment.fileSize.intValue
        self.mimeType = attachment.mimeType
        self.attachmentID = attachment.attachmentID
    }
}

private extension Collection where Element == AttachInfo {
    var areUploaded: Bool {
        allSatisfy { $0.isUploaded }
    }
}

class AttachmentsTableViewController: UITableViewController, AttachmentController, AccessibleView {
    
    enum AttachmentSection: Int {
        case normal = 1, inline
        
        var actionTitle : String {
            get {
                switch(self) {
                case .normal: return LocalString._normal_attachments
                case .inline: return LocalString._inline_attachments
                }
            }
        }
    }

    private var doneButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    /// AttachmentController
    var barItem: UIBarButtonItem? {
        get {
            return addButton
        }
    }
    
    weak var delegate: AttachmentsTableViewControllerDelegate?
    private(set) weak var user: UserManager?
    
    internal let kDefaultAttachmentFileSize : Int = 25 * 1000 * 1000 // 25 mb
    internal var currentAttachmentSize : Int = 0
    
    var message: Message!
    private var normalAttachments: [AttachInfo] = []
    private var inlineAttachments: [AttachInfo] = []
    var attachmentSections : [AttachmentSection] = []
    lazy var processQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    var attachments: [Attachment] {
        if let atts = self.message.attachments.allObjects as? [Attachment] {
            return atts.filter{ !$0.isSoftDeleted }
        }
        return []
    }
    
    lazy var attachmentProviders: Array<AttachmentProvider> = { [unowned self] in
        // There is no access to camera in AppExtensions, so should not include it into menu
        #if APP_EXTENSION
            return [PhotoAttachmentProvider(for: self),
                    DocumentAttachmentProvider(for: self)]
        #else
            return [PhotoAttachmentProvider(for: self),
                    CameraAttachmentProvider(for: self),
                    DocumentAttachmentProvider(for: self)]
        #endif
    }()
    
    func updateAttachments() {
            self.buildAttachments()
            self.updateAttachmentSize()
        DispatchQueue.main.async {
            self.tableView?.reloadData()
        }
    }
    
    func buildAttachments() {
        let attachments = self.attachments.sorted(by: { $0.objectID.uriRepresentation().lastPathComponent > $1.objectID.uriRepresentation().lastPathComponent })
        attachments.forEach { att in
            if att.objectID.isTemporaryID {
                att.managedObjectContext?.performAndWait {
                    try? att.managedObjectContext?.obtainPermanentIDs(for: [att])
                }
            }
        }
        normalAttachments = attachments.filter { !$0.inline() }.map { AttachInfo(attachment: $0) }
        inlineAttachments = attachments.filter { $0.inline() }.map { AttachInfo(attachment: $0) }

        attachmentSections.removeAll()
        if !normalAttachments.isEmpty {
            attachmentSections.append(.normal)
        }
        if !inlineAttachments.isEmpty {
            attachmentSections.append(.inline)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.doneButton = UIBarButtonItem(title: LocalString._general_done_button, style: UIBarButtonItem.Style.plain, target: self, action: #selector(AttachmentsTableViewController.doneAction(_:)))
        self.navigationItem.leftBarButtonItem = doneButton
        
        self.tableView.register(UINib(nibName: "\(AttachmentTableViewCell.self)", bundle: nil),
                                forCellReuseIdentifier: AttachmentTableViewCell.Constant.identifier)
        self.tableView.separatorStyle = .none
        
        if let navigationController = navigationController {
            configureNavigationBar(navigationController)
            setNeedsStatusBarAppearanceUpdate()
        }
        
        self.clearsSelectionOnViewWillAppear = false
        
        updateAttachments()
        generateAccessibilityIdentifiers()

        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(self.attachmentUploaded(noti:)),
                         name: .attachmentUploaded,
                         object: nil)
    }
    
    func configureNavigationBar(_ navigationController: UINavigationController) {
        let navigationBarTitleFont = Fonts.h2.light
        let textAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: navigationBarTitleFont
        ]
        if #available(iOS 13, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.largeTitleTextAttributes = textAttributes
            navBarAppearance.titleTextAttributes = textAttributes
            navBarAppearance.backgroundColor = UIColor.ProtonMail.Nav_Bar_Background

            navigationController.navigationBar.standardAppearance = navBarAppearance
            navigationController.navigationBar.compactAppearance = navBarAppearance
            navigationController.navigationBar.scrollEdgeAppearance = navBarAppearance
            navigationController.navigationBar.tintColor = UIColor.white
        } else {
            navigationController.navigationBar.barStyle = UIBarStyle.black
            navigationController.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.tintColor = UIColor.white
            
            navigationController.navigationBar.titleTextAttributes = textAttributes
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.updateAttachmentSize()
        
        if #available(iOS 13.0, *) { // fix the gap between navigationbar and view
            navigationController?.navigationBar.setNeedsLayout()
        }
    }
    
    override var shouldAutorotate : Bool {
        return true
    }

    func setup(user: UserManager) {
        self.user = user
    }

    internal func updateAttachmentSize () {
        self.currentAttachmentSize = self.attachments.reduce(into: 0) {
            $0 += $1.fileSize.intValue
        }
    }
    
    @IBAction func doneAction(_ sender: AnyObject) {
        self.delegate?.attachments(self, didFinishPickingAttachments: attachments)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addAction(_ sender: UIBarButtonItem) {
        if self.user?.isStorageExceeded ?? false {
            LocalString._storage_exceeded.alertToastBottom(view: self.view)
            return
        }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        
        self.attachmentProviders.map{ $0.alertAction }.forEach(alertController.addAction)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: UIAlertAction.Style.cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func showSizeErrorAlert( _ didReachedSizeLimitation: Int) {
        DispatchQueue.main.async {
            self.showErrorAlert(LocalString._the_total_attachment_size_cant_be_bigger_than_25mb)
        }
    }
    
    func showErrorAlert( _ error: String) {
        let alert = error.alertController()
        alert.addOKAction()
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return attachmentSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch attachmentSections[section] {
        case .normal: return normalAttachments.count
        case .inline: return inlineAttachments.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AttachmentTableViewCell.Constant.identifier, for: indexPath) as! AttachmentTableViewCell

        var attachment: AttachInfo?
        let secontItem = attachmentSections[indexPath.section]
        switch secontItem {
        case .normal: attachment = normalAttachments[indexPath.row]
        case .inline: attachment = inlineAttachments[indexPath.row]
        }
        
        if let att = attachment {
            cell.configCell(att.name, fileSize: att.size, showSpinner: !att.isUploaded)
            let crossView = UILabel()
            crossView.text = LocalString._general_remove_button
            crossView.sizeToFit()
            crossView.textColor = UIColor.white
            cell.defaultColor = UIColor.lightGray
            cell.setSwipeGestureWith(crossView, color: .red, mode: MCSwipeTableViewCellMode.exit, state: MCSwipeTableViewCellState.state3  ) { [weak self] (cell, state, mode) -> Void in
                guard let `self` = self else { return }
                guard let cell = cell, let indexp = self.tableView.indexPath(for: cell) else {
                    return
                }
                guard indexp.section < self.attachmentSections.count else {
                    return
                }
                
                var attInfo: AttachInfo!
                switch self.attachmentSections[indexp.section] {
                case .normal:
                    attInfo = self.normalAttachments[indexp.row]
                case .inline:
                    attInfo = self.inlineAttachments[indexp.row]
                }

                if let att = self.attachments.first(where: { $0.objectID.uriRepresentation().absoluteString ==  attInfo.objectID }) {
                    self.delegate?.attachments(self, didDeletedAttachment: att)
                    if let _ = self.attachments.firstIndex(of: att) {
                        self.updateAttachments()
                    }
                }
            }
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return attachmentSections[section].actionTitle
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = Fonts.h6.regular
        header.textLabel?.textColor = UIColor.gray
    }
}

extension AttachmentsTableViewController {
    @objc
    private func attachmentUploaded(noti: Notification) {
        guard let objecrID = noti.userInfo?["objectID"] as? String,
              let _ = noti.userInfo?["attachmentID"] as? String else {
            return
        }

        var indexPath: IndexPath?
        if let normalAttIndex = normalAttachments.firstIndex(where: { $0.objectID == objecrID }),
           let indexOfNormal = attachmentSections.firstIndex(of: .normal) {
            indexPath = IndexPath(row: normalAttIndex, section: indexOfNormal)
        } else if let inlineAttIndex = inlineAttachments.firstIndex(where: { $0.objectID == objecrID }),
                  let indexOfInline = attachmentSections.firstIndex(of: .inline){
            indexPath = IndexPath(row: inlineAttIndex, section: indexOfInline)
        }
        if let indexPath = indexPath {
            let cell = (tableView.cellForRow(at: indexPath) as?  AttachmentTableViewCell)
            cell?.stopSpinner()
        }
    }
}

extension AttachmentsTableViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        configureNavigationBar(navigationController)
    }
}
