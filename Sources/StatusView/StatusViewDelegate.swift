//
//  StatusViewDelegate.swift
//  StatusView
//
//  Created by Ulf Akerstedt-Inoue on 2021/09/01.
//  Copyright © 2021 hakkabon software. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
public protocol StatusViewDelegate {
    func show(notification view: StatusView, hideAfter delay: TimeInterval)
    func willShow(notification view: StatusView, in hostView: UIView)
    func didShow(notification view: StatusView, in hostView: UIView)
    func hide(notification view: StatusView, forced: Bool)
    func willHide(notification view: StatusView, in hostView: UIView)
    func didHide(notification view: StatusView, in hostView: UIView)
}
