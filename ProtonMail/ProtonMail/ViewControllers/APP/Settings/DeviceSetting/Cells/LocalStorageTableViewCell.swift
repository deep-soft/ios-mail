// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import UIKit

@IBDesignable class LocalStorageTableViewCell: UITableViewCell {
    static var CellID: String {
        return "\(self)"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let parentView: UIView = self.contentView

        self.button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        self.button.setTitleColor(ColorProvider.TextNorm, for: .normal)
        self.button.backgroundColor = ColorProvider.InteractionWeak
        self.button.layer.cornerRadius = 8
        self.button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.button.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 96),
            //self.button.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -16),
            self.button.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 295),
            self.button.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16)
        ])

        self.topLabel.textColor = ColorProvider.TextNorm
        self.topLabel.font = UIFont.systemFont(ofSize: 17)
        self.topLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topLabel.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 16),
            //self.topLabel.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -104),
            //self.topLabel.widthAnchor.constraint(equalToConstant: 243),
            self.topLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16)
        ])
        
        self.middleLabel.textColor = ColorProvider.TextWeak
        self.middleLabel.font = UIFont.systemFont(ofSize: 14)
        self.middleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.middleLabel.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 48),
            //self.middleLabel.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -56),
            self.middleLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.middleLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16)
        ])
        
        self.bottomLabel.textColor = ColorProvider.TextNorm
        self.bottomLabel.font = UIFont.systemFont(ofSize: 14)
        self.bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.bottomLabel.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 102),
            //self.bottomLabel.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -22),
            self.bottomLabel.widthAnchor.constraint(equalToConstant: 263),
            //self.bottomLabel.heightAnchor.constraint(equalToConstant: 20),    top/bottom
            self.bottomLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16)
        ])
    }
    
    typealias buttonActionBlock = () -> Void
    var callback: buttonActionBlock?
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var middleLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        callback?()
    }
    
    func configCell(_ topLine: String, _ middleLine: NSMutableAttributedString, _ bottomLine: String, _ complete: buttonActionBlock?) {
        topLabel.text = topLine
        middleLabel.attributedText = middleLine
        bottomLabel.text = bottomLine
        callback = complete
        
        self.layoutIfNeeded()
    }
}

extension LocalStorageTableViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}