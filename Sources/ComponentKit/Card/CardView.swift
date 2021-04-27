//
//  CardView.swift
//  
//
//  Created by Jacob Whitehead on 25/04/2021.
//

import UIKit
import ThemeKit
import DeclarativeUIKit

class CardView: UIView {
    
    var hasShadow = true {
        didSet { setNeedsLayout() }
    }
    
    var isRounded = true {
        didSet { setNeedsLayout() }
    }
    
    var cardColor: ColorContext = .backgroundSecondary {
        didSet { backgroundStyle(cardColor) }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundStyle(cardColor)
        shadow(radius: hasShadow ? Theme.constant(for: .shadowRadius) : 0)
        rounded(radius: isRounded ? Theme.constant(for: .cornerRadius) : 0)
    }
    
}
