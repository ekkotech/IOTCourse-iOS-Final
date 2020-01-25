//
//  ThumbTack.swift
//  IOTCourse
//
//  Created by Andrew Coad on 25/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit

//
// Display constants
//
// Color related
fileprivate let defaultOuterAlpha: CGFloat = 0.8
fileprivate let defaultInnerAlpha: CGFloat = 1.0
fileprivate let defaultInnerColor: UIColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: defaultInnerAlpha)
fileprivate let defaultOuterColorDark: UIColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: defaultOuterAlpha)
fileprivate let defaultOuterColorLight: UIColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: defaultOuterAlpha)
fileprivate let autoDarkenThreshold: CGFloat = 0.9
// Size related
fileprivate let defaultDiameter: CGFloat = 28.0
fileprivate let defaultInnerDiameterRatio: CGFloat = 0.6
fileprivate let defaultLineWidth: CGFloat = 1.0

@IBDesignable
class ThumbTack: UIView {

    // MARK: - Private properties
    //
    private let innerCircle: CALayer = CALayer()
    private var isDark: Bool = false

    // MARK: - Public properties
    //
    @IBInspectable internal var borderWidth: CGFloat = defaultLineWidth
    @IBInspectable internal var borderColor: UIColor = UIColor.lightGray
    @IBInspectable internal var color: UIColor = defaultInnerColor {
        didSet {
            innerCircle.backgroundColor = color.cgColor
            adjustBackground()
        }
    }
    @IBInspectable internal var autoDarken: Bool = true
    @IBInspectable var diameter: CGFloat = defaultDiameter

    // MARK: - Initialisation
    //
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        layer.addSublayer(innerCircle)
    }

    // MARK: - Rendering
    //
    override func layoutSubviews() {
        super.layoutSubviews()

        layer.bounds = CGRect(x: 0.0, y: 0.0, width: diameter, height: diameter)
        layer.cornerRadius = diameter / 2.0
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        layer.backgroundColor = isDark ? defaultOuterColorDark.cgColor : defaultOuterColorLight.cgColor

        let id = diameter * defaultInnerDiameterRatio
        innerCircle.bounds = CGRect(x: 0.0, y: 0.0, width: id, height: id)
        innerCircle.cornerRadius = id / 2.0
        innerCircle.backgroundColor = color.cgColor
        innerCircle.position = CGPoint(x: layer.bounds.width / 2.0, y: layer.bounds.height / 2.0)
    }

    // MARK: - Private functions
    //

    /**
    Transitions the thumb tack outer circle background color between light and dark modes

    */
    private func adjustBackground() {

        if (color.lightness >= autoDarkenThreshold) && !isDark {
            isDark = true
            #if TARGET_INTERFACE_BUILDER
            layer.backgroundColor = defaultOuterColorDark.cgColor
            #else
            let animation = CABasicAnimation(keyPath: "backgroundColor")
            animation.fromValue = defaultOuterColorLight.cgColor
            layer.backgroundColor = defaultOuterColorDark.cgColor
            layer.add(animation, forKey: "backgroundColor")
            #endif
        }
        else if (color.lightness < autoDarkenThreshold) && isDark {
            isDark = false
            #if TARGET_INTERFACE_BUILDER
            layer.backgroundColor = defaultOuterColorLight.cgColor
            #else
            let animation = CABasicAnimation(keyPath: "backgroundColor")
            animation.fromValue = defaultOuterColorDark.cgColor
            layer.backgroundColor = defaultOuterColorLight.cgColor
            layer.add(animation, forKey: "backgroundColor")
            #endif
        }
    }

}
