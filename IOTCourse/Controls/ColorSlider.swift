//
//  ColorSlider.swift
//  IOTCourse
//
//  Created by Andrew Coad on 25/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit

//
// Color Channels
//
internal enum ColorChannel: Int, CaseIterable {
    case red
    case green
    case blue
    case mono
}

//
// Dimension constants
//
fileprivate let minimumValue: CGFloat = 0.0
fileprivate let maximumValue: CGFloat = 1.0
fileprivate let defaultHeight: CGFloat = 48.0
fileprivate let defaultTrackHeightRatio: CGFloat = (1.0 / 3.0)
fileprivate let defaultThumbHeightRatio: CGFloat = (2.0 / 3.0)
fileprivate let defaultThumbPosition: CGFloat = maximumValue
fileprivate let defaultColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

@IBDesignable
class ColorSlider: UIControl {

    //
    // Private properties
    //
    private let trackLayer: CAGradientLayer = CAGradientLayer()
    private var startColor: UIColor = UIColor.black
    private var endColor: UIColor = UIColor.white
    private var activeFrame: CGRect = CGRect.zero
    //
    // Backing vars
    private var _value: UIColor = defaultColor

    
    // MARK: - Public properties
    //
    @IBInspectable internal var value: UIColor  {
        set {
            _value = newValue
        }
        get {
            return _value
        }
    }
    internal var channel: ColorChannel = .mono
    // Adapter to work around inability to use enum as @IBInspectable
    @IBInspectable internal var channelAdapter: Int {
        get {
            return channel.rawValue
        }
        set {
            channel = ColorChannel(rawValue: newValue) ?? .mono
        }
    }
    @IBInspectable internal var endInset: CGFloat = 16.0
    @IBInspectable internal var borderWidth: CGFloat = 1.0
    @IBInspectable internal var borderColor: UIColor = UIColor.lightGray
    @IBInspectable internal var roundedEnd: Bool = true
    @IBInspectable internal var cornerRadius: CGFloat = 0.0
    //
    // Intrinsic size helpers
    var contentSize: CGSize = CGSize(width: defaultHeight, height: defaultHeight) {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    override var intrinsicContentSize: CGSize {
        return contentSize
    }

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
        self.layer.addSublayer(trackLayer)
    }

    // MARK: - Rendering
    //
    override func layoutSubviews() {
        super.layoutSubviews()

        // Ensure that width and height are integral numbers
        let trackLayerWidth = (layer.bounds.width - (endInset * 2.0)).rounded(.down)
        let trackLayerHeight = (layer.bounds.height * defaultTrackHeightRatio).rounded(.down)
        // Ensure that track is positioned at integral X and Y positions
        trackLayer.frame = CGRect(x: endInset.rounded(.down),
                                  y: (((layer.bounds.height - trackLayerHeight) / 2.0)).rounded(.down),
                                  width: trackLayerWidth,
                                  height: trackLayerHeight)

        switch channel {
        case .red:
            startColor = _value.withRedComponent(0.0)
            endColor = _value.withRedComponent(1.0)
        case .green:
            startColor = _value.withGreenComponent(0.0)
            endColor = _value.withGreenComponent(1.0)
        case .blue:
            startColor = _value.withBlueComponent(0.0)
            endColor = _value.withBlueComponent(1.0)
        case .mono:
            startColor = UIColor.black
            endColor = UIColor.white
        }

        trackLayer.colors = [startColor.cgColor, endColor.cgColor]
        trackLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        trackLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        var thisCornerRadius: CGFloat = 0.0
        
        if roundedEnd {
            thisCornerRadius = cornerRadius == 0.0 ? (trackLayerHeight / 2.0) : min((trackLayerHeight / 2.0), cornerRadius)
        }
        
        trackLayer.cornerRadius = thisCornerRadius
        trackLayer.borderColor = borderColor.cgColor
        trackLayer.borderWidth = borderWidth / UIScreen.main.scale

        activeFrame = CGRect(x: trackLayer.frame.origin.x + trackLayer.cornerRadius,
                             y: trackLayer.frame.origin.y,
                             width: trackLayer.frame.width - (2 * trackLayer.cornerRadius),
                             height: trackLayer.frame.height)
    }

    // MARK: - Action Handlers
    //
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {

    }

    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {

    }

    // MARK: - Private Functions
    //
    /**
    Translates the `location` within the controls' view as constrained by `bounds` to a new value

    - Parameter location: the X-Y coordinates relative to the controls' view
    - Parameter bounds: the bounding rectangle for the translation
    - Parameter channel: the color channel that is assigned to the control

    - Returns: the value for the control

    */
    private func valueForBoundedLocation(location: CGPoint, bounds: CGRect) -> UIColor {

        return UIColor.white
    }

    /**
    Translates a position within a slider track to an X-Y location within the controls' view
    where the Y value is centered on the slider track

    - Parameter position: the normalised position (0.0 - 1.0) within the slider track

    - Returns: a point relative to the control's view

    */
    private func locationForPosition(position: CGFloat) -> CGPoint {

        return CGPoint.zero
    }

    /**
    Moves the thumb tack to the position as determined by `color` and `channel` and sets the thumb tack color to `color`

    - Parameter thumb: a reference to a thumb tack
    - Parameter color: the current color
    - Parameter channel: the color channel that is assigned to the control

    */
    private func updateThumbTack(thumb: ThumbTack, color: UIColor, channel: ColorChannel) {

    }

}
