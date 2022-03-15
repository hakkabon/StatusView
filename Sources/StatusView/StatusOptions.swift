//
//  StatusOptions.swift
//  StatusView
//
//  Created by Ulf Akerstedt-Inoue on 2021/09/01.
//  Copyright © 2021 hakkabon software. All rights reserved.
//

import UIKit

public protocol StatusOptions {

    // Initial position of notification.
    var position: StatusView.Position { get }

    // Adjusts the width of a notification view.
    var width: CGFloat { get }

    // Alignment of text in the notification view.
    var alignment: NSTextAlignment { get }

    // Image displayed left or right in the notification view.
    var image: UIImage? { get }

    // Location of image within the notification view.
    var imageLocation: StatusView.ImageLocation { get }

    // Specifies duration of fade-in animation of a notification.
    var fadeInDuration: Double { get }
    
    // Specifies duration of fade-out animation of a notification.
    var fadeOutDuration: Double { get }
    
    // Specifies duration of move-in-to-display-slot animation of a notification.
    var showAnimationDuration: Double { get }
    
    // Specifies duration of move-out-of-display-slot animation of a notification.
    var hideAnimationDuration: Double { get }
    
    // Specifies duration of display of a notification.
    var secondsToShow: Double { get }
    
    // Current opacity of notifier.
    var viewOpacity: CGFloat { get }
    
    // Allows for denying dismissal of notifier at tap event.
    var allowTapToDismiss: Bool { get }

    // Specifies how notification views are dismissed.
    var exitType: StatusView.ExitType { get }

    // Allows for specifying a code block for execution at tap event.
    var tappedBlock: ((StatusView) -> Void)?  { get }
}

@available(iOS 9.0, *)
public extension StatusOptions {

    // Initial position of notification.
    var position: StatusView.Position { return StatusView.Position.top }

    var width: CGFloat { return UIScreen.main.bounds.width - 2 * 20 }
    var alignment: NSTextAlignment { return .center }
    var image: UIImage? { return nil }
    var imageLocation: StatusView.ImageLocation { return .left }
    var fadeInDuration: Double { return  0.25 }
    var fadeOutDuration: Double  { return  0.2 }
    var showAnimationDuration: Double { return  0.25 }
    var hideAnimationDuration: Double { return  0.2 }
    var secondsToShow: Double { return 10.0 }
    var viewOpacity: CGFloat { return 1 }
    var allowTapToDismiss: Bool  { return true }
    var exitType: StatusView.ExitType  { return StatusView.ExitType.pop }
    var tappedBlock: ((StatusView) -> Void)? { return nil }
}
