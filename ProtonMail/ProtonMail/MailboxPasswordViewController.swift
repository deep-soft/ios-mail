//
//  MailboxPasswordViewController.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

class MailboxPasswordViewController: UIViewController {
    let animationDuration: NSTimeInterval = 0.5
    let buttonDisabledAlpha: CGFloat = 0.5
    let keyboardPadding: CGFloat = 12

    @IBOutlet weak var decryptButton: UIButton!
    @IBOutlet weak var keyboardPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var rememberButton: UIButton!
    
    struct Notification {
        static let didSignOut = "UserDataServiceDidSignOutNotification"
        static let didSignIn = "UserDataServiceDidSignInNotification"
    }
    
    var isRemembered: Bool = sharedUserDataService.isRememberMailboxPassword
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDecryptButton()
        rememberButton.selected = isRemembered
        passwordTextField.roundCorners()
        
        configureNavigationBar()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if(UIDevice.currentDevice().isLargeScreen())
        {
            passwordTextField.becomeFirstResponder()
        }
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        if (parent == nil) {
            SignInViewController.isComeBackFromMailbox = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    }
    
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        navigationController?.setNavigationBarHidden(true, animated: true)
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
    }
    
    func setupDecryptButton() {
        decryptButton.alpha = buttonDisabledAlpha
        decryptButton.roundCorners()
    }
    
    
    // MARK: - private methods
    
    func configureNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Blue_475F77
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: navigationBarTitleFont
        ]
    }
    
    func decryptPassword() {
        let password = passwordTextField.text
        
        if sharedUserDataService.isMailboxPasswordValid(password, privateKey: AuthCredential.getPrivateKey()) {
            if sharedUserDataService.isSet {
                sharedUserDataService.setMailboxPassword(password, isRemembered: self.isRemembered)
                (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            } else {
                AuthCredential.setupToken(password, isRememberMailbox: self.isRemembered)
                MBProgressHUD.showHUDAddedTo(view, animated: true)
                sharedUserDataService.fetchUserInfo() { info, error in
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    if error != nil {
                        let alertController = error!.alertController()
                        alertController.addOKAction()
                        if error!.domain == APIServiceErrorDomain && error!.code == APIErrorCode.AuthErrorCode.localCacheBad {
                            self.navigationController?.popViewControllerAnimated(true)
                        }
                    } else if info != nil {
                        sharedUserDataService.setMailboxPassword(password, isRemembered: self.isRemembered)
                        self.loadContent()
                    } else {
                        let alertController = NSError.unknowError().alertController()
                        alertController.addOKAction()
                    }
                }
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName(Notification.didSignIn, object: self)
            
        } else {
            let alert = UIAlertController(title: NSLocalizedString("Incorrect password"), message: NSLocalizedString("The mailbox password is incorrect."), preferredStyle: .Alert)
            alert.addAction((UIAlertAction.okAction()))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    private func loadContent() {
        self.loadContactsAfterInstall()
        //if sharedUserDataService.isMailboxPasswordStored {
            (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
        //} else {
//            if count(AuthCredential.getPrivateKey().trim()) > 10 {
//                self.performSegueWithIdentifier(self.mailboxSegue, sender: self)
//            }
//            else {
//                self.performSegueWithIdentifier(self.signUpKeySegue, sender: self)
//            }
       // }
    }
    
    func loadContactsAfterInstall()
    {
        sharedContactDataService.fetchContacts({ (contacts, error) -> Void in
            if error != nil {
                NSLog("\(error)")
            } else {
                NSLog("Contacts count: \(contacts!.count)")
            }
        })
    }
    
    func updateButton(button: UIButton) {
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            button.alpha = button.enabled ? 1.0 : self.buttonDisabledAlpha
        })
    }
    
    
    // MARK: - Actions
    
    @IBAction func decryptAction(sender: UIButton) {
        decryptPassword()
    }
    
    @IBAction func rememberButtonAction(sender: UIButton) {
        isRemembered = !isRemembered
        rememberButton.selected = isRemembered
    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        passwordTextField.resignFirstResponder()
    }
}


// MARK: - NSNotificationCenterKeyboardObserverProtocol

extension MailboxPasswordViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        
        keyboardPaddingConstraint.constant = 0
        
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShowNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        
        keyboardPaddingConstraint.constant = keyboardInfo.beginFrame.height + keyboardPadding
        
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}


// MARK: - UITextFieldDelegate

extension MailboxPasswordViewController: UITextFieldDelegate {
    func textFieldShouldClear(textField: UITextField) -> Bool {
        decryptButton.enabled = false
        updateButton(decryptButton)
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text as NSString
        let changedText = text.stringByReplacingCharactersInRange(range, withString: string)
        
        if textField == passwordTextField {
            decryptButton.enabled = !changedText.isEmpty
        }
        
        updateButton(decryptButton)
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if !passwordTextField.text.isEmpty {
            decryptPassword()
        }
        
        return true
    }
}
