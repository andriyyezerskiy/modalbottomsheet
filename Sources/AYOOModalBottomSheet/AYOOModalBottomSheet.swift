import UIKit

/// Snap points to resemble the Apple Maps modal presentation interaction
public enum AYOOModalBottomSheetSnapPoint {
    case top
    case middle
    case close
}

// Delegate methods

/// Use this to communicate with parent view controller
public protocol AYOOModalBottomSheetDelegate: class {
    func modalBottomSheetMoved(to position: AYOOModalBottomSheetSnapPoint)
}

public class AYOOModalBottomSheet: UIPresentationController {
    
    public weak var modalBottomSheetDelegate: AYOOModalBottomSheetDelegate?
    
    // MARK: - Properties
    
    /// Current blur effect style
    public var blurEffectStyle: UIBlurEffect.Style = .light
    
    /// Distance between max height of view and screen
    public var topGap: CGFloat = 88
    
    /// Width of the modal presentation
    public var modalWidth: CGFloat = 0
    
    /// Determines if modal presentation support bounce
    // TODO: - Fix top bounce to avoid over view height drag
    public var bounce: Bool = false
    
    /// Corner radius and affected corners of modal presentation
    public var cornerRadius: CGFloat = 20
    public var roundedCorners: UIRectCorner = [.topLeft, .topRight]
    
    /// Presented view rect
    override public var frameOfPresentedViewInContainerView: CGRect {
        return CGRect(origin: CGPoint(x: 0, y: self.containerView!.frame.height / 2), size: CGSize(width: (self.modalWidth == 0 ? self.containerView!.frame.width : self.modalWidth), height: self.containerView!.frame.height))
    }
    
    /// Current snap point
    private var currentSnapPoint: AYOOModalBottomSheetSnapPoint = .middle
    
    /// Determines if modal presentation support drag beyond given height
    public var dragToExpand: Bool = false
    
    /// Determines if view should snap
    public var shouldSnap: Bool = false
    
    private var origin: CGPoint = .zero
    
    // MARK: - Views
    
    /// Declates the blur effect view
    private lazy var blurEffectView: UIVisualEffectView = {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: self.blurEffectStyle))
        blur.isUserInteractionEnabled = true
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blur.addGestureRecognizer(self.tapGestureRecognizer)
        return blur
    }()
    
    // MARK: - Gestures
    
    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(self.dismiss))
    }()
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.drag(_:)))
        return pan
    }()
    
    // MARK: - Init
    
    public convenience init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, modalBottomSheetDelegate: AYOOModalBottomSheetDelegate? = nil, blurEffectStyle: UIBlurEffect.Style = .light, topGap: CGFloat = 88, modalWidth: CGFloat = 0, bounce: Bool = false, cornerRadius: CGFloat = 20, dragToExpand: Bool = false, shouldSnap: Bool = false) {
        self.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.modalBottomSheetDelegate = modalBottomSheetDelegate
        self.blurEffectStyle = blurEffectStyle
        self.topGap = topGap
        self.modalWidth = modalWidth
        self.bounce = bounce
        self.cornerRadius = cornerRadius
        self.dragToExpand = dragToExpand
        self.shouldSnap = shouldSnap
    }
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    // MARK: - Lifecycle
    
    override public func dismissalTransitionWillBegin() {
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            self.blurEffectView.alpha = 0
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in
            self.blurEffectView.removeFromSuperview()
        })
    }
    
    override public func presentationTransitionWillBegin() {
        self.blurEffectView.alpha = 0
        guard let presenterView = self.containerView else { return }
        presenterView.addSubview(self.blurEffectView)
        
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            self.blurEffectView.alpha = 1
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in })
    }
    
    override public func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        guard let presentedView = self.presentedView else { return }
        
        presentedView.layer.masksToBounds = true
        presentedView.roundCorners(corners: self.roundedCorners, radius: self.cornerRadius)
        presentedView.addGestureRecognizer(self.panGesture)
    }
    
    override public func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        guard let presenterView = self.containerView else { return }
        guard let presentedView = self.presentedView else { return }
        
        presentedView.frame = self.frameOfPresentedViewInContainerView
        presentedView.frame.origin.x = (presenterView.frame.width - presentedView.frame.width) / 2
        origin = CGPoint(x: presentedView.center.x, y: presenterView.center.y + self.topGap)
        presentedView.center = origin
        
        self.blurEffectView.frame = presenterView.bounds
    }
    
    // MARK: - Actions
    
    @objc func dismiss() {
        self.presentedViewController.dismiss(animated: true, completion: nil)
    }
    
    @objc func drag(_ gesture:UIPanGestureRecognizer) {
        guard let presentedView = self.presentedView else { return }
        switch gesture.state {
        case .changed:
            self.presentingViewController.view.bringSubviewToFront(presentedView)
            let translation = gesture.translation(in: self.presentingViewController.view)
            let y = presentedView.center.y + translation.y
            
            let preventBounce: Bool = self.bounce ? true : (y - (self.topGap / 2) > self.presentingViewController.view.center.y)
            if preventBounce {
                presentedView.center = CGPoint(x: self.presentedView!.center.x, y: y)
            }
            gesture.setTranslation(CGPoint.zero, in: self.presentingViewController.view)
        case .ended:
            let height = self.presentingViewController.view.frame.height
            let position = presentedView.convert(self.presentingViewController.view.frame, to: nil).origin.y
            
            if shouldSnap {
                if position < 0 || position < (1/4 * height) {
                    self.sendToTop()
                    self.currentSnapPoint = .top
                } else if (position < (height / 2)) || (position > (height / 2) && position < (height / 3)) {
                    self.sendToMiddle()
                    self.currentSnapPoint = .middle
                } else {
                    self.currentSnapPoint = .close
                    self.dismiss()
                }
                if let d = self.modalBottomSheetDelegate {
                    d.modalBottomSheetMoved(to: self.currentSnapPoint)
                }
            } else if dragToExpand {
                // TODO: - Add logic to expand view when dragToExpand is true like Apple Music Lyric View
            } else {
                if position > (self.origin.y * 4/6) {
                    self.dismiss()
                } else {
                    self.sendToOrigin()
                }
            }
            
            gesture.setTranslation(CGPoint.zero, in: self.presentingViewController.view)
        default:
            return
        }
    }
    
    func sendToTop() {
        guard let presentedView = self.presentedView else { return }
        let topYPosition: CGFloat = (self.presentingViewController.view.center.y + CGFloat(self.topGap / 2))
        UIView.animate(withDuration: 0.25) {
            presentedView.center = CGPoint(x: presentedView.center.x, y: topYPosition)
        }
    }
    
    func sendToMiddle() {
        if let presentedView = self.presentedView {
            let y = self.presentingViewController.view.center.y * 2
            UIView.animate(withDuration: 0.25) {
                presentedView.center = CGPoint(x: presentedView.center.x, y: y)
            }
        }
    }
    
    func sendToOrigin() {
        if let presentedView = self.presentedView {
            UIView.animate(withDuration: 0.25) {
                presentedView.center = self.origin
            }
        }
    }
}

private extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

