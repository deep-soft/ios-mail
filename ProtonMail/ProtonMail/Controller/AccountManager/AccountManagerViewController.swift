//
//  ReportBugsViewController.swift
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
import MBProgressHUD

class AccountManagerViewController: ProtonMailViewController, ViewModelProtocol, CoordinatedNew {
    private var viewModel : AccountManagerViewModel!
    private var coordinator : AccountManagerCoordinator?
    
    func set(viewModel: AccountManagerViewModel) {
        self.viewModel = viewModel
    }
    func set(coordinator: AccountManagerCoordinator) {
        self.coordinator = coordinator
    }
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    
    // MARK: - View Outlets
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        NotificationCenter.default.addObserver(forName: Notification.Name.didObtainMailboxPassword, object: nil, queue: .main) { _ in
            self.navigationController?.popToViewController(self, animated: true)
        }
        
        self.title = LocalString._account

        let cancelButton = UIBarButtonItem(title: LocalString._general_cancel_button, style: .plain, target: self, action: #selector(cancelAction))
        self.navigationItem.leftBarButtonItem = cancelButton
    }
    
    @objc internal func dismiss() {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func cancelAction(_ sender: UIBarButtonItem) {
        self.dismiss()
//        let alertController = UIAlertController(title: LocalString._general_confirmation_title,
//                                                message: nil, preferredStyle: .actionSheet)
//        alertController.addAction(UIAlertAction(title: LocalString._composer_save_draft_action,
//                                                style: .default, handler: { (action) -> Void in
//
//        }))
//
//        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
//                                                style: .cancel, handler: { (action) -> Void in
//
//        }))
//
//        alertController.addAction(UIAlertAction(title: LocalString._composer_discard_draft_action,
//                                                style: .destructive, handler: { (action) -> Void in
//                                                    self.dismiss()
//        }))
//
//        alertController.popoverPresentationController?.barButtonItem = sender
//        alertController.popoverPresentationController?.sourceRect = self.view.frame
//        present(alertController, animated: true, completion: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Private methods
    fileprivate func updateSendButtonForText(_ text: String?) {
//        sendButton.isEnabled = (text != nil) && !text!.isEmpty
    }
    
    // MARK: Actions
    
    @IBAction fileprivate func sendAction(_ sender: UIBarButtonItem) {

        self.coordinator?.go(to: .addAccount)
    }
//
//    private func send(_ text: String) {
//        let v : UIView = self.navigationController?.view ?? self.view
//        MBProgressHUD.showAdded(to: v, animated: true)
//        sendButton.isEnabled = false
//        BugDataService(api: APIService.shared).reportBug(text, completion: { error in
//            MBProgressHUD.hide(for: self.view, animated: true)
//            self.sendButton.isEnabled = true
//            if let error = error {
//                let alert = error.alertController()
//                alert.addAction(UIAlertAction(title: LocalString._general_ok_action, style: .default, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//            } else {
//                let alert = UIAlertController(title: LocalString._bug_report_received,
//                                              message: LocalString._thank_you_for_submitting_a_bug_report_we_have_added_your_report_to_our_bug_tracking_system,
//                                              preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: LocalString._general_ok_action, style: .default, handler: nil))
//                self.present(alert, animated: true, completion: {
//                    self.reset()
//                    ///TODO::fixme consider move this after clicked ok button.
//                    NotificationCenter.default.post(name: .switchView, object: nil)
//                })
//            }
//        })
//    }
}

// MARK: - UITableViewDataSource
extension AccountManagerViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sectionCount()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.rowCount(at: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let s = self.viewModel.section(at: indexPath.section)
        switch s {
        case .users:
            let cell = tableView.dequeueReusableCell(withIdentifier: "account_cell", for: indexPath)
            if let userCell = cell as? AccountManagerUserCell, let user =  self.viewModel.user(at: indexPath.row) {
                userCell.configCell(name: user.defaultDisplayName, email: user.defaultEmail)
            }
            return cell
        case .add:
            let cell = tableView.dequeueReusableCell(withIdentifier: "add_account_cell", for: indexPath)
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let s = self.viewModel.section(at: indexPath.section)
        switch s {
        case .users:
            return 60.0
        case .add:
            return 44.0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let s = self.viewModel.section(at: section)
        switch s {
        case .users:
            return 0.0
        case .add:
            return 0.0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let s = self.viewModel.section(at: section)
        switch s {
        case .users:
            return 0.5
        case .add:
            return 0.5
        }
    }
}

extension AccountManagerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let s = self.viewModel.section(at: indexPath.section)
        switch s {
        case .users: break
        case .add:
            self.coordinator?.go(to: .addAccount)
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
}
