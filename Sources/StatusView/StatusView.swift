//
//  StatusView.swift
//  StatusView
//
//  Created by Ulf Akerstedt-Inoue on 2021/09/01.
//  Copyright © 2021 hakkabon software. All rights reserved.
//

import UIKit
import Dispatch
import QuartzCore

/**
 * Displays an application-wide notification above all visible application views. The
 * notification may be aligned to the following upper parts of the screen:
 *    { top left | center top | top right }
 * or lower parts of the screen:
 *    { bottom left | center bottom | or bottom right }.
 *
 * Tagged notifications are displayed one at a time regarding their asssigned tag number.
 * This ensures that one notification instance is displayed only one at a time, not
 * showing the same notification more than once.
 *
 */
public class StatusView: UIView {

    static var applicationWindow: UIWindow?

    private static var overlayWindow: UIWindow?
    private static var overlayViewController: OverlayViewController?

    /// The host view in which status views are displayed as subviews.
    public static var hostView: UIView? = {
        overlayViewController = OverlayViewController()
        guard let keyWindow = currentWindow else { fatalError("cannot retrive current window") }
        if #available(iOS 13.0, *) {
            overlayWindow = UIWindow(windowScene: keyWindow.windowScene!)
        } else {
            overlayWindow = UIWindow(frame: UIScreen.main.bounds)
        }
        applicationWindow = keyWindow
        overlayWindow?.windowLevel = UIWindow.Level.alert
        overlayWindow?.rootViewController = overlayViewController
        overlayWindow?.isHidden = false
        overlayWindow?.isUserInteractionEnabled = true
        return overlayViewController?.overlayView
    }()

    /// Specifies location of image (if any) within the views.
    public enum ImageLocation {
        case left
        case right
    }

    /// Specifies how notification views are dismissed.
    public enum ExitType : Int {
        case dequeue, pop, slide
    }

    /// Position on screen where notification view is displayed.
    /// Note that `topLeft`, `topRight`, `bottomLeft`, `bottomRight` are meant for iPad devices only.
    public enum Position : Int {
        case top, topLeft, topRight
        case bottom, bottomLeft, bottomRight
        
        var isTop: Bool {
            return self == .top || self == .topLeft || self == .topRight
        }
        var isBottom: Bool {
            return self == .bottom || self == .bottomLeft || self == .bottomRight
        }
    }

    /// Display options for status views.
    var options: StatusOptions!

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fill
        view.isUserInteractionEnabled = false
        view.spacing = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: Constants.fontSize)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 2
        label.textAlignment = .left
        label.textColor = UIColor.labelText
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Defines the internal display states.
    enum State : Int {
        case showing, hiding, movingForward, movingBackward, visible, hidden
    }
    var state: State = State.hidden
    var isScheduledToHide: Bool = false
    var shouldForceHide: Bool = false
    private let forceHideAnimationDuration = 0.1
    private var delegate: StatusViewDelegate?

    enum AssetsColor: String {
        case backgroundColor
        case titleColor
        case subtitleColor
    }

    struct Constants {
        static var maxHeight: CGFloat  { return UIDevice.current.userInterfaceIdiom == .pad ? 70 : 50 }
        static var minWidth: CGFloat { return UIDevice.current.userInterfaceIdiom == .pad ? 180 : 150 }
        static var fontSize: CGFloat { return UIDevice.current.userInterfaceIdiom == .pad ? 17 : 13 }
        static var margin: CGFloat = 20

        static let showAnimation = "ShowAnimation"
        static let hideAnimation = "HideAnimation"
        static let moveAnimation = "MoveAnimation"
        static let propertyKey = "Animation"
    }

    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public convenience init(title: String, subtitle: String?, options: StatusOptions) {
        self.init(
            frame: CGRect(
                // temporary offscreen origin
                origin: CGPoint(
                    x: options.position.isTop ? -400 : 0,
                    y: options.position.isTop ? -400 : UIScreen.main.bounds.height
                ),
                size: StatusView.adjustSize(title: title, subtitle: subtitle, constrainedBy: options).size
            )
        )

        guard let view = StatusView.hostView else {
            fatalError("Host view cannot be nil.")
        }

        self.options = options
        self.titleLabel.attributedText = attributedTitle(title: title, subtitle: subtitle, options: options)
        self.iconView.image = options.image
        self.iconView.isHidden = options.image == nil ? true : false
        self.initialize(hostView: view, with: options)
        setupInitialFrame(for: self.options.position)
    }

    public convenience init(title: String, options: StatusOptions) {
        self.init(title: title, subtitle: nil, options: options)
    }

    // Returns an array of `StatusView` hosted in the given view.
    public class func notifications(in view: UIView) -> [StatusView] {
        return StatusViewMonitor.sharedManager.notifications(in: view)
    }
    
    // Returns the `StatusView` with given tag hosted in the given view or nil if there is no match.
    public class func notification(with tag: Int, in view: UIView) -> [StatusView]? {
        return StatusViewMonitor.sharedManager.notification(with: tag, in: view)
    }
    
    // Immediately hides all `StatusView` notifications hosted in any view.
    public class func hideAllNotifications() {
        StatusViewMonitor.sharedManager.hideAllNotifications()
    }
    
    // Immediately hides all notifications in a certain view, forgoing their secondsToShow values.
    public class func hideNotifications(in view: UIView) {
        StatusViewMonitor.sharedManager.hideNotifications(in: view)
    }
    
    // Immediately force hide all notifications, forgoing their dismissal animations.
    // Call this in viewWillDisappear: of your view controller if necessary.
    public class func forceHideAllNotifications(in view: UIView) {
        StatusViewMonitor.sharedManager.forceHideAllNotifications(in: view)
    }
    
    public func show() {
        self.delegate?.show(notification: self, hideAfter: self.options.secondsToShow)
    }
    
    public func hide() {
        self.delegate?.hide(notification: self, forced: false)
    }
    
    private func initialize(hostView view: UIView, with options: StatusOptions) {
        self.translatesAutoresizingMaskIntoConstraints = true
        self.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        self.isUserInteractionEnabled = true
        self.isHidden = false
        
        layerConfig()
        switch options.imageLocation {
        case .left:
            stackView.addArrangedSubview(iconView)
            stackView.addArrangedSubview(titleLabel)
        case .right:
            stackView.addArrangedSubview(titleLabel)
            stackView.addArrangedSubview(iconView)
        }
        self.addSubview(stackView)

        // Add self as a subview in the hosting view.
        view.addSubview(self)

        // Setup delegate to manager (monitor) object.
        self.delegate = StatusViewMonitor.sharedManager
        self.state = .hidden
    }
    
    private func layerConfig() {
        layer.backgroundColor = (UIColor.appColor(.backgroundColor) ?? UIColor.white).cgColor
        if #available(iOS 13.0, *) {
            layer.cornerCurve = .continuous
        }
        layer.cornerRadius = min(bounds.width, bounds.height) * 0.5
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0.0, height: 5)
        layer.shadowRadius = 14.0
    }
    
    override public func updateConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: Constants.margin),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -Constants.margin),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor, multiplier: 0.8),
        ])

        iconView.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        iconView.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .vertical)
                
        super.updateConstraints()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) * 0.5
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.state == .visible else { return }
        self.options.tappedBlock?(self)
        if self.options.allowTapToDismiss {
            self.delegate?.hide(notification: self, forced: false)
        }
    }
}

extension StatusView {

    func showView() {
        self.delegate?.willShow(notification: self, in: self.superview!)
        self.state = .showing

        self.alpha = self.options.viewOpacity
        delayExecution(seconds: self.options.fadeInDuration) {
            let oldPoint = CGPoint(x: self.layer.position.x, y: self.layer.position.y)
            let x = oldPoint.x
            var y = oldPoint.y

            switch self.options.position {
            case .top, .topLeft, .topRight:
                y += self.bounds.size.height
                if #available(iOS 11.0, *) {
                    y += self.safeAreaInsets.top
                }
            case .bottom, .bottomLeft, .bottomRight:
                y -= self.bounds.size.height
                if #available(iOS 11.0, *) {
                    y -= self.safeAreaInsets.bottom
                }
            }
            
            // Change center of layer.
            let newPoint = CGPoint(x:x, y:y)
            self.layer.position = newPoint
            
            // Animate change.
            let moveLayer = CABasicAnimation(keyPath: "position")
            moveLayer.fromValue = NSValue(cgPoint: oldPoint)
            moveLayer.toValue = NSValue(cgPoint: newPoint)
            moveLayer.duration = self.options.showAnimationDuration
            moveLayer.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            moveLayer.delegate = self
            moveLayer.setValue(Constants.showAnimation, forKey: Constants.propertyKey)
            self.layer.add(moveLayer, forKey: Constants.showAnimation)
        }
    }
    
    /// Move the center of the notification to a new position in global coordinates.
    func hideView() {
        self.delegate?.willHide(notification: self, in: self.superview!)
        
        self.state = .hiding
        let oldPoint = self.layer.position
        var newPoint: CGPoint = .zero
        
        switch self.options.position {
        case .top, .topLeft, .topRight:
            switch self.options.exitType {
            case .dequeue:
                newPoint = CGPoint(x: oldPoint.x, y: self.superview!.bounds.size.height - self.bounds.height/2)
                if #available(iOS 11.0, *) {
                    newPoint.y -= self.safeAreaInsets.bottom
                }
            case .pop:
                newPoint = CGPoint(x: oldPoint.x, y: self.bounds.height/2)
                if #available(iOS 11.0, *) {
                    newPoint.y += self.safeAreaInsets.top
                }
            case .slide:
                newPoint = self.options.position == .topLeft ? CGPoint(x: -self.bounds.width, y: oldPoint.y) : CGPoint(x: self.superview!.bounds.width + self.bounds.width/2, y: oldPoint.y)
            }
        case .bottom, .bottomLeft, .bottomRight:
            switch self.options.exitType {
            case .dequeue:
                newPoint = CGPoint(x: oldPoint.x, y: self.bounds.height/2)
                if #available(iOS 11.0, *) {
                    newPoint.y += self.safeAreaInsets.top
                }
            case .pop:
                newPoint = CGPoint(x: oldPoint.x, y: self.superview!.bounds.size.height - self.bounds.height/2)
                if #available(iOS 11.0, *) {
                    newPoint.y -= self.safeAreaInsets.bottom
                }
            case .slide:
                    newPoint = self.options.position == .bottomLeft ? CGPoint(x: -self.bounds.width, y: oldPoint.y) : CGPoint(x: self.superview!.bounds.width + self.bounds.width/2, y: oldPoint.y)
            }
        }
        
        // Change center of layer.
        self.layer.position = newPoint
        
        // Animate change.
        let moveLayer = CABasicAnimation(keyPath: "position")
        moveLayer.fromValue = NSValue(cgPoint: oldPoint)
        moveLayer.toValue = NSValue(cgPoint: newPoint)
        moveLayer.duration = self.shouldForceHide ? self.forceHideAnimationDuration : self.options.hideAnimationDuration
        moveLayer.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        moveLayer.delegate = self
        moveLayer.setValue(Constants.hideAnimation, forKey: Constants.propertyKey)
        self.layer.add(moveLayer, forKey: Constants.hideAnimation)
    }
    
    func pushView(_ distance: CGFloat, forward: Bool, delay: Double) {
        self.state = forward ? .movingForward : .movingBackward
        let distanceToPush = self.options.position.isBottom ? -distance : distance

        // Change center of layer.
        let oldPoint = self.layer.position
        let newPoint = CGPoint(x: oldPoint.x, y: self.layer.position.y + distanceToPush)

        // Animate change.
        delayExecution(seconds: delay) {
            self.layer.position = newPoint // Assignment has to be delayed as well.
            let moveLayer = CABasicAnimation(keyPath: "position")
            moveLayer.fromValue = NSValue(cgPoint: oldPoint)
            moveLayer.toValue = NSValue(cgPoint: newPoint)
            moveLayer.duration = forward ? self.options.showAnimationDuration : self.options.hideAnimationDuration
            moveLayer.timingFunction = forward ? CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut) : CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
            moveLayer.setValue(Constants.moveAnimation, forKey: Constants.propertyKey)
            moveLayer.delegate = self
            self.layer.add(moveLayer, forKey: Constants.moveAnimation)
        }
    }

    /// Adjust top left (x,y) coordinates according to position.
    private func setupInitialFrame(for position: Position) {
        let screen: CGSize = CGSize(width: self.superview!.bounds.width, height: self.superview!.bounds.size.height)
        let (x,y): (CGFloat,CGFloat) = {
            switch self.options.position {
            case .top: return((screen.width - self.frame.width) * 0.5, -self.frame.size.height)
            case .topLeft: return(Constants.margin, -self.frame.size.height)
            case .topRight: return (screen.width - self.frame.width - Constants.margin, -self.frame.size.height)
            case .bottom: return ((screen.width - self.frame.width) * 0.5, screen.height)
            case .bottomLeft: return (Constants.margin, screen.height)
            case .bottomRight: return (screen.width - frame.size.width - Constants.margin, screen.height)
            }
        }()
        self.frame = CGRect(origin: CGPoint(x:x,y:y), size: frame.size)
    }
}

@available(iOS 9.0, *)
extension StatusView : CAAnimationDelegate {
    
    /// CA animation stopped at this point.
    /// - Parameters:
    ///   - animation: reference to the animation
    ///   - flag: flag indicating completion of animation (which is always false)
    public func animationDidStop(_ animation: CAAnimation, finished flag: Bool) {
        let animationKind = animation.value(forKey: Constants.propertyKey) as! String

        // Show animation ended.
        if animationKind == Constants.showAnimation {
            self.delegate?.didShow(notification: self, in: self.superview!)
            self.state = .visible
        }
        // Hide animation ended.
        else if animationKind == Constants.hideAnimation {
            UIView.animate(withDuration: self.shouldForceHide ? self.forceHideAnimationDuration : self.options.fadeOutDuration, delay: 0.0, options: .curveLinear, animations: {() -> Void in
                self.alpha = 0.0
            }, completion: {(_ finished: Bool) -> Void in
                self.state = .hidden
                self.delegate?.didHide(notification: self, in: self.superview!)
                NotificationCenter.default.removeObserver(self)
                self.removeFromSuperview()
            })
        }
        // Move animation ended.
        else if animationKind == Constants.moveAnimation {
            self.state = .visible
        }
    }
}

@available(iOS 9.0, *)
extension StatusView {
    
    /// Adjust size of notification depending on the amount of text, constraining width and max height.
    /// - Parameters:
    ///   - title: title string for which the adjusted height is calculated
    ///   - subtitle: subtitle string for which the adjusted height is calculated
    ///   - width: maximum width
    static func adjustSize(title: String, subtitle: String?, constrainedBy options: StatusOptions) -> CGRect {
        let str = title + "\n" + (subtitle ?? "")
        var rect = boundingRect(of: str, constraining: options.width, font: UIFont.boldSystemFont(ofSize: Constants.fontSize))

        // Clamp height value.
        rect.size.height = Constants.maxHeight < rect.size.height ? Constants.maxHeight : rect.size.height

        // Approximate width value.
        var width = rect.size.width
        width += options.image != nil ? 2 * rect.size.height : 0
        rect.size.width = (Constants.minWidth ... options.width).clamp(width)

        print("view width: \(options.width) ADJUSTED SIZE: \(rect)")
        return rect
    }

    /// Returns a bounding rectangle of given text and font constrained by the given width.
    /// - Parameters:
    ///   - text: text for which the bounding rect is calculated
    ///   - width: constraining width limit for bounding rect calculation
    ///   - font: font used for bounding rect calculation
    /// - Note: To render the string in multiple lines, specify `usesLineFragmentOrigin` in options.
    static func boundingRect(of text: String, constraining width: CGFloat, font: UIFont) -> CGRect {
        let limits = CGSize(width: width, height: .greatestFiniteMagnitude)
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let rect = text.count == 0 ?
            CGRect(origin: .zero, size: CGSize(width: width, height: 0)) :
            text.boundingRect(with: limits, options: options, attributes: [NSAttributedString.Key.font: font], context: nil)
        return rect
    }
    
    private func attributedTitle(title: String, subtitle: String?, options: StatusOptions) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(attributedText(string: title, alignment: options.alignment, assetColor: .titleColor, defaultColor: .black))
        result.append(NSAttributedString(string: "\n"))
        if let subtitle = subtitle {
            result.append(attributedText(string: subtitle, alignment: options.alignment, assetColor: .subtitleColor, defaultColor: .darkGray))
        }
        return result
    }

    private func attributedText(string: String, alignment: NSTextAlignment, assetColor: AssetsColor, defaultColor: UIColor) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
       paragraphStyle.alignment = alignment
       paragraphStyle.lineBreakMode = .byTruncatingTail
       
       let attributes: [NSAttributedString.Key: Any] = [
           .foregroundColor: UIColor.appColor(assetColor) ?? defaultColor,
           .font: UIFont.boldSystemFont(ofSize: Constants.fontSize),
           .paragraphStyle: paragraphStyle
       ]
       return NSAttributedString(string: string, attributes: attributes)
    }

    /// Delay execution with the given amount in seconds.
    /// - Parameters:
    ///   - delay: Intended delay in seconds.
    ///   - closure: Block of code to be executed after the delay has expired.
    /// - Note: It dispatches execution on the main thread.
    private func delayExecution(seconds delay: Double, closure: @escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
}

extension UIColor {
    static var labelText: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                return .label
            }
        } else {
            return UIColor.white
        }
    }

    static func appColor(_ name: StatusView.AssetsColor) -> UIColor? {
         return UIColor(named: name.rawValue)
    }
}

/// Current keyWindow
private var currentWindow: UIWindow? = {
    if #available(iOS 13.0, *) {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return windowScene?.windows.first
    } else {
        return UIApplication.shared.keyWindow
    }
}()

extension ClosedRange {
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}
