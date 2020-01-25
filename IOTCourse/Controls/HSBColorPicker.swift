//
//  HSBColorPicker.swift
//  IOTCourse
//
//  Created by Andrew Coad on 25/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit

//
// Display related constants
fileprivate let defaultColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
fileprivate let defaultThumbDiameter: CGFloat = 32.0
fileprivate let defaultGutterWidth: CGFloat = 16.0
fileprivate let defaultSliderWidthRatio: CGFloat = 0.9

@IBDesignable
class HSBColorPicker: UIControl {

    private var circleView = UIImageView()
    private var sliderView = ColorSlider()
    private let thumbTack = ThumbTack(frame: CGRect(x: 0.0, y: 0.0,
                                                    width: defaultThumbDiameter,
                                                    height: defaultThumbDiameter))
    private var radius: CGFloat = 0.0
    //
    // Backing vars
    private var _value: UIColor = defaultColor

    // MARK: - Public properties
    //
    @IBInspectable internal var value: UIColor {
        get {
            return _value
        }
        set {
            _value = newValue
        }
    }

    // IBInspectables
    //
    @IBInspectable private let gutter: CGFloat = defaultGutterWidth

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
        circleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleCircleTap)))
        circleView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleCirclePan)))
        circleView.isUserInteractionEnabled = true

        sliderView.addTarget(self, action: #selector(handleSliderValueChanged), for: .valueChanged)

        self.addSubview(circleView)
        self.addSubview(sliderView)

        circleView.contentMode = .center
        circleView.addSubview(thumbTack)
        sliderView.channel = .mono
        sliderView.value = defaultColor
    }

    // MARK: - Rendering
    //
    override func layoutSubviews() {
        super.layoutSubviews()

        /// Circle view
        let sideLength = min(bounds.width, bounds.height - sliderView.intrinsicContentSize.height)
        circleView.frame = CGRect(x: (bounds.width - sideLength) / 2.0,
                                  y: 0.0,
                                  width: sideLength,
                                  height: sideLength)

        /// Color wheel
        radius = ((circleView.bounds.width / 2.0) - gutter).rounded(.down)
        if let f = constructFilter(radius: radius, brightness: 1.0), let foi = f.outputImage {
            circleView.image = UIImage(ciImage: foi)
        }

        /// Slider view
        let sliderWidth = bounds.width * defaultSliderWidthRatio
        sliderView.frame = CGRect(x: (bounds.width - sliderWidth) / 2.0,
                                  y: circleView.bounds.height,
                                  width: sliderWidth,
                                  height: sliderView.intrinsicContentSize.height)

        /// Thumb tack
        thumbTack.diameter = defaultThumbDiameter
        thumbTack.color = _value
        setThumbPosition(value: _value)
    }

    // MARK: - Gesture Handlers
    //
    @objc func handleCircleTap(_ sender: UITapGestureRecognizer) {

        if sender.state == .ended {

        }
    }

    @objc func handleCirclePan(_ sender: UIPanGestureRecognizer) {

        if sender.state == .began || sender.state == .changed || sender.state == .ended {

        }
    }

    @objc func handleSliderValueChanged(_ sender: ColorSlider) {

    }

    // MARK: - Private functions
    //

    /**
     Translates the `location` within the controls' view relative to a reference point and constrained by `bounds` to a new value

     - Parameter location: the X-Y coordinates within the controls' view
     - Parameter relativeTo: the reference point for the location coordinates
     - Parameter bounds: the bounding radius for the translation

     - Returns: the value for the control

     */
    private func valueForBoundedLocation(location: CGPoint, relativeTo: CGPoint, bounds: CGFloat) -> UIColor? {

        /// Location relative to circle center; traditional cartesian corodinates

        /// Normalise saturation

        /// Normalise hue; anti-clockwise direction

        /// Filter out possible -0.0 values

        /// Return new color

        return nil

    }

    /**
     Builds a filter for a color wheel of a given radial size and brightness. The color space for the wheel is extended SRGB

     - Parameter radius: The radius of the color wheel
     - Parameter brightness: The normalised brightness of the color wheel

     - Returns: An optional filter. A nil return indicates that the filter could not be constructed

     */
    private func constructFilter(radius: CGFloat, brightness: CGFloat) -> CIFilter? {
        guard let cs = CGColorSpace.init(name: CGColorSpace.extendedSRGB) else { return nil }
        
        return CIFilter(name: "CIHueSaturationValueGradient", parameters: [
            "inputColorSpace" : cs,
            "inputDither" : 0,
            "inputRadius" : radius,
            "inputSoftness" : 0,
            "inputValue" : brightness])
    }

    /**
     Moves the thumb tack to the position as determined by `value`

     - Parameter value: the current value

     */
    private func setThumbPosition(value: UIColor) {


    }

}
