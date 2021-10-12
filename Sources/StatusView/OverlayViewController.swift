//
//  OverlayView.swift
//  StatusView
//
//  Created by Ulf Akerstedt-Inoue on 2021/09/01.
//  Copyright © 2021 hakkabon software. All rights reserved.
//

import UIKit

class OverlayViewController: UIViewController {

    lazy var overlayView = OverlayView()

    override func loadView() {
        view = overlayView
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        view.backgroundColor = UIColor.clear
        view.isUserInteractionEnabled = true
    }
    
    override var shouldAutorotate: Bool { return true }
}
