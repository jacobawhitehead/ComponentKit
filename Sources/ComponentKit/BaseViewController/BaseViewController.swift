//
//  BaseViewController.swift
//  
//
//  Created by Jacob Whitehead on 27/04/2021.
//

import UIKit
import ThemeKit
import DeclarativeUIKit
import Combine

open class BaseViewController: UIViewController {
    
    public var cancellables = [AnyCancellable]()
    
    private var ctaBottomAnchor: NSLayoutConstraint?

    /// To avoid repetetive callbacks.
    private var shouldNotifyAboutBottomReached = true

    /// Called when reached the bottom of the scroll view.
    /// Can happen when scroll view content size height less then scroll view frame height (called once)
    /// Or when content size more then frame's height and user scrolls down to bottom.
    open func bottomReachedAction() { }

    /// Defines spacing between content view subviews.
    public var contentSpacing: CGFloat = Theme.constant(for: .padding) {
        didSet {
            contentStackView.spacing = contentSpacing
        }
    }

    /// Defines edge margins for content view.
    public var contentViewLayoutMargins = NSDirectionalEdgeInsets(top: Theme.constant(for: .margin),
                                                           leading: Theme.constant(for: .margin),
                                                           bottom: Theme.constant(for: .margin),
                                                           trailing: Theme.constant(for: .margin)) {
        didSet {
            contentStackView.directionalLayoutMargins = contentViewLayoutMargins
        }
    }

    /// Subviews which have been added via either `addArrangedSubview` or `addArrangedViewController` functions
    public var arrangedSubviews: [UIView] {
        return contentStackView.arrangedSubviews
    }

    /// Determines whether the view controller lays out its content relative to its safe area. Defaults to true.
    public var isSafeAreaRelativeLayout: Bool = true

    // MARK: Private properties

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [scrollView])
        stackView.axis = .vertical
        return stackView
    }()

    private(set) lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor(.backgroundPrimary)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.addSubview(contentStackView)
        contentStackView.pin(to: scrollView.contentLayoutGuide)
        contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        scrollView.delegate = self
        return scrollView
    }()

    private(set) lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .vertical
        stackView.spacing = contentSpacing
        stackView.directionalLayoutMargins = contentViewLayoutMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    private var scrollViewContentSizeObservation: NSKeyValueObservation?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor(.backgroundPrimary)
        view.addSubview(mainStackView)
        mainStackView.pin(to: isSafeAreaRelativeLayout ? view.safeAreaLayoutGuide : view)
        startScrollViewBoundsObservation()
        listenToKeyboard()
    }
    
    private func addCloseButton() {
        navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .close, target: self, action: #selector(closeAction))
    }
    
    @objc func closeAction() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - Functions to add/remove subviews

public extension BaseViewController {

    /// Add multiple subviews inside the same vertical stack container
    func addArrangedSubviews(_ subviews: [UIView],
                             spacing: CGFloat = 0,
                             axis: NSLayoutConstraint.Axis = .vertical,
                             topInset: CGFloat = 0,
                             leftInset: CGFloat = 0,
                             bottomInset: CGFloat = 0,
                             rightInset: CGFloat = 0) {
        guard subviews.count > 0 else { return }
        let stackView = axis == .vertical ? subviews.vStack(spacing: spacing) : subviews.hStack(spacing: spacing)
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: topInset,
                                                                     leading: leftInset,
                                                                     bottom: bottomInset,
                                                                     trailing: rightInset)
        stackView.isLayoutMarginsRelativeArrangement = true
        addSubview(stackView)
    }

    /// Adds a view to subviews of scrollable content view.
    /// - Parameter view: View to add as a subview on scroll view.
    /// - Parameter topInset: Space between `view` top edge and the bottom edge of the upper subview.  Respects `contentSpacing` and  `contentLayoutMargins` values. Defaults to 0.
    /// - Parameter leftInset: Space between `view` left edge and the left margin of content view. Respects the value of `contentLayoutMargins.leading` property. Defaults to 0.
    /// - Parameter bottomInset: Space between `view` bottom edge and either top edge of the bottom subview or bottom edge of content view. Respects `contentSpacing` and  `contentLayoutMargins` property. Defaults to 0.
    /// - Parameter rightInset: Space between `view` right edge and the right edge of content view. Respects the value of `contentLayoutMargins.trailing` property. Defaults to 0.
    func addArrangedSubview(_ view: UIView,
                            topInset: CGFloat = 0,
                            leftInset: CGFloat = 0,
                            bottomInset: CGFloat = 0,
                            rightInset: CGFloat = 0) {
        if (topInset, leftInset, bottomInset, rightInset) == (0, 0, 0, 0) {
            addSubview(view)
        } else {
            let stackView = UIStackView(arrangedSubviews: [view])
            stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: topInset, leading: leftInset,
                                                                         bottom: bottomInset, trailing: rightInset)
            stackView.isLayoutMarginsRelativeArrangement = true
            addSubview(stackView)
        }
    }

    /// Adds a view managed by the specified view controller to subviews of scroll view.
    /// Specified view controller is also becomes a child of the receiver.
    func addArrangedViewController(_ viewController: UIViewController,
                                   topInset: CGFloat = 0,
                                   leftInset: CGFloat = 0,
                                   bottomInset: CGFloat = 0,
                                   rightInset: CGFloat = 0) {
        addArrangedSubview(viewController.view, topInset: topInset, leftInset: leftInset,
                           bottomInset: bottomInset, rightInset: rightInset)
        addChild(viewController)
        viewController.didMove(toParent: self)
    }

    func insertArrangedSubview(_ view: UIView,
                               at stackIndex: Int,
                               topInset: CGFloat = 0,
                               leftInset: CGFloat = 0,
                               bottomInset: CGFloat = 0,
                               rightInset: CGFloat = 0) {
        if (topInset, leftInset, bottomInset, rightInset) == (0, 0, 0, 0) {
            contentStackView.insertArrangedSubview(view, at: stackIndex)
        } else {
            let stackView = UIStackView(arrangedSubviews: [view])
            stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: topInset, leading: leftInset,
                                                                         bottom: bottomInset, trailing: rightInset)
            stackView.isLayoutMarginsRelativeArrangement = true
            contentStackView.insertArrangedSubview(view, at: stackIndex)
        }
    }

    func removeArrangedSubviews() {
        children.forEach {
            $0.willMove(toParent: nil)
            $0.removeFromParent()
        }
        contentStackView.removeAllArrangedSubviews()
    }
    
    func removeArrangedSubview(at index: Int) {
        let view = contentStackView.arrangedSubviews[index]
        contentStackView.removeArrangedSubview(view)
        view.removeFromSuperview()
    }
}

// MARK: - Utilities

public extension BaseViewController {

    /// Applies custom spacing after the specified view.
    /// - Parameters:
    ///   - spacing: spacing you want to apply
    ///   - arrangedSubview: view after the spacing specified is going to be applied
    func setCustomSpacing(_ spacing: CGFloat, after arrangedSubview: UIView) {
        contentStackView.setCustomSpacing(spacing, after: arrangedSubview)
    }
}

// MARK: - Private helpers

extension BaseViewController {

    private func startScrollViewBoundsObservation() {
        scrollViewContentSizeObservation = scrollView.observe(\.contentSize, options: .new) { [weak self] _, _ in
            guard let self = self else { return }
            self.shouldNotifyAboutBottomReached = true
            self.notifyScrolledToBottomIfNeeded(scrollView: self.scrollView)
        }
    }

    private func notifyScrolledToBottomIfNeeded(scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        guard distanceFromBottom < height else {
            shouldNotifyAboutBottomReached = true
            return
        }
        if shouldNotifyAboutBottomReached {
            bottomReachedAction()
            shouldNotifyAboutBottomReached = false
        }
    }

    private func addSubview(_ view: UIView) {
        contentStackView.addArrangedSubview(view)
    }
    
    private func listenToKeyboard() {
        
        NotificationCenter.default.publisher(for: UIApplication.keyboardWillChangeFrameNotification)
            .map { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0 }
            .sink { [weak self] keyboardHeight in
                self?.scrollView.contentInset.bottom = keyboardHeight
            }.store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0 }
            .sink { [weak self] keyboardHeight in
                self?.scrollView.contentInset.bottom = keyboardHeight
            }.store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.scrollView.contentInset.bottom = 0
            }.store(in: &cancellables)
    }
    
}

// MARK: - UIScrollViewDelegate

extension BaseViewController: UIScrollViewDelegate {

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        notifyScrolledToBottomIfNeeded(scrollView: scrollView)
    }
    
}
