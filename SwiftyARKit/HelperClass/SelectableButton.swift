//
//  SelectableButton.swift
//  VPARkit
//
//  Created by Viraj Patel on 06/11/17.
//  Copyright © 2017 Viraj Patel. All rights reserved.
//

import Foundation
import UIKit

class SelectableButton: UIButton {
    override var isSelected: Bool {
        didSet {
            if isSelected {
                layer.borderColor = UIColor.yellow.cgColor
                layer.borderWidth = 3
            } else {
                layer.borderWidth = 0
            }
        }
    }
}
