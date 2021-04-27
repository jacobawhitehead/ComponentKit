//
//  CardView.swift
//  
//
//  Created by Jacob Whitehead on 25/04/2021.
//

import UIKit
import ThemeKit
import DeclarativeUIKit

public class CardView: UIView {
    
    public var hasShadow = true {
        didSet { setNeedsLayout() }
    }
    
    public var isRounded = true {
        didSet { setNeedsLayout() }
    }
    
    public var cardColor: ColorContext = .backgroundSecondary {
        didSet { backgroundStyle(cardColor) }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        backgroundStyle(cardColor)
        shadow(radius: hasShadow ? Theme.constant(for: .shadowRadius) : 0)
        rounded(radius: isRounded ? Theme.constant(for: .cornerRadius) : 0)
    }
    
}

public extension UIView {
    
    func inCard(topInset: CGFloat = Theme.constant(for: .margin),
                leadingInset: CGFloat = Theme.constant(for: .margin),
                trailingInset: CGFloat = Theme.constant(for: .margin),
                bottomInset: CGFloat = Theme.constant(for: .margin)) -> CardView {
        let card = CardView()
        card.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.pin(to: card,
                 topInset: topInset,
                 leadingInset: leadingInset,
                 bottomInset: bottomInset,
                 trailingInset: trailingInset)
        return card
    }
    
}
