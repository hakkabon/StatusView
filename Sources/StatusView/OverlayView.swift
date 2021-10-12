//
//  Overlay.swift
//  StatusView
//
//  Created by Ulf Akerstedt-Inoue on 2021/09/01.
//  Copyright © 2021 hakkabon software. All rights reserved.
//

import UIKit

class OverlayView : UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        // Only intercept touch events destined for subviews in overlay.
        for subview in subviews {
            // See if the hit is anywhere in our view hierarchy (overlay window).
            if let hitView = subview.hitTest(self.convert(point, to: subview), with: event) {
                if let notification = hitView as? StatusView {
                    return notification
                }
            }
        }
        
        // In all other cases, just relay it to window (main window) underneath.
        guard let applicationWindow = StatusView.applicationWindow else { return nil }
        return applicationWindow.hitTest(point, with: event)
    }
}
