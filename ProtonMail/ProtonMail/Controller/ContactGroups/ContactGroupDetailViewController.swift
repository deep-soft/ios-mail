//
//  ContactGroupDetailViewController.swift
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

import UIKit
import PromiseKit
import MBProgressHUD
import ProtonCore_UIFoundations
import ProtonCore_PaymentsUI

class ContactGroupDetailViewController: ProtonMailViewController, ViewModelProtocol, ComposeSaveHintProtocol {

    typealias viewModelType = ContactGroupDetailVMProtocol

    var viewModel: ContactGroupDetailVMProtocol!
    
    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupDetailLabel: UILabel!
    @IBOutlet weak var sendImage: UIImageView!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    private var editBarItem: UIBarButtonItem!
    private var paymentsUI: PaymentsUI?

    private let kToContactGroupEditSegue = "toContactGroupEditSegue"
    private let kContactGroupViewCellIdentifier = "ContactGroupEditCell"

    func set(viewModel: ContactGroupDetailVMProtocol) {
        self.viewModel = viewModel
        self.viewModel.reloadView = { [weak self] in
            self?.reload()
        }
    }

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard self.viewModel.user.hasPaidMailPlan else {
            presentPlanUpgrade()
            return
        }
        guard !self.viewModel.user.isStorageExceeded else {
            LocalString._storage_exceeded.alertToastBottom()
            return
        }

        let user = self.viewModel.user
        let viewModel = ContainableComposeViewModel(msg: nil,
                                                    action: .newDraft,
                                                    msgService: user.messageService,
                                                    user: user,
                                                    coreDataContextProvider: sharedServices.get(by: CoreDataService.self))

        let contactGroupVO = ContactGroupVO(ID: self.viewModel.groupID.rawValue, name: self.viewModel.name)
        contactGroupVO.selectAllEmailFromGroup()
        viewModel.addToContacts(contactGroupVO)

        let coordinator = ComposeContainerViewCoordinator(presentingViewController: self, editorViewModel: viewModel)
        coordinator.start()
    }

    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        if self.viewModel.user.hasPaidMailPlan == false {
            presentPlanUpgrade()
            return
        }
        performSegue(withIdentifier: kToContactGroupEditSegue,
                     sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        editBarItem = UIBarButtonItem(title: LocalString._general_edit_action,
                                      style: .plain,
                                      target: self,
                                      action: #selector(self.editButtonTapped(_:)))
        let attributes = FontManager.DefaultStrong.foregroundColor(ColorProvider.InteractionNorm)
        editBarItem.setTitleTextAttributes(attributes, for: .normal)
        navigationItem.rightBarButtonItem = editBarItem

        view.backgroundColor = ColorProvider.BackgroundNorm
        tableView.backgroundColor = ColorProvider.BackgroundNorm

        headerContainerView.backgroundColor = ColorProvider.BackgroundNorm

        sendImage.image = Asset.mailSendIcon.image.withRenderingMode(.alwaysTemplate)
        sendImage.tintColor = ColorProvider.InteractionNorm

        prepareTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    private func reload() {
        let isReloadSuccessful = self.viewModel.reload()
        if isReloadSuccessful {
            self.refresh()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    private func refresh() {
        prepareHeader()
        tableView.reloadData()
    }

    private func prepareHeader() {
        groupNameLabel.attributedText = viewModel.name.apply(style: .Default)
        
        groupDetailLabel.attributedText = viewModel.getTotalEmailString().apply(style: .DefaultSmallWeek)

        groupImage.setupImage(tintColor: UIColor.white,
                              backgroundColor: UIColor.init(hexString: viewModel.color, alpha: 1))
        if let image = sendButton.imageView?.image {
            sendButton.imageView?.contentMode = .center
            sendButton.imageView?.image = UIImage.resize(image: image, targetSize: CGSize.init(width: 20, height: 20))
        }
    }

    private func prepareTable() {
        tableView.register(UINib(nibName: "ContactGroupEditViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: kContactGroupViewCellIdentifier)
        tableView.noSeparatorsBelowFooter()
        tableView.estimatedRowHeight = 60.0
        tableView.allowsSelection = false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToContactGroupEditSegue {
            let contactGroupEditViewController = segue.destination.children[0] as! ContactGroupEditViewController

            if let sender = sender as? ContactGroupDetailViewController,
                let viewModel = sender.viewModel {
                sharedVMService.contactGroupEditViewModel(
                    contactGroupEditViewController,
                    user: self.viewModel.user,
                    state: .edit,
                    groupID: viewModel.groupID.rawValue,
                    name: viewModel.name,
                    color: viewModel.color,
                    emailIDs: Set(viewModel.emails))
            } else {
                // TODO: handle error
                return
            }
        }

        if #available(iOS 13, *) {
            if let nav = segue.destination as? UINavigationController {
                nav.children[0].presentationController?.delegate = self
            }
            segue.destination.presentationController?.delegate = self
        }
    }

    private func presentPlanUpgrade() {
        self.paymentsUI = PaymentsUI(payments: self.viewModel.user.payments, clientApp: .mail, shownPlanNames: Constants.shownPlanNames)
        self.paymentsUI?.showUpgradePlan(presentationType: .modal,
                                         backendFetch: true) { _ in }
    }

}

extension ContactGroupDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.emails.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && !viewModel.emails.isEmpty {
            return LocalString._menu_contacts_title
        }
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kContactGroupViewCellIdentifier,
                                                 for: indexPath) as! ContactGroupEditViewCell
        guard let data = viewModel.emails[safe: indexPath.row] else {
            return cell
        }
        cell.config(emailID: data.emailID,
                    name: data.name,
                    email: data.email,
                    queryString: "",
                    state: .detailView)

        return cell
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let titleView = view as? UITableViewHeaderFooterView {
            titleView.textLabel?.text = titleView.textLabel?.text?.capitalized
        }
    }
}

@available (iOS 13, *)
extension ContactGroupDetailViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        reload()
    }
}
