//
//  RGBColorPicker.swift
//  IOTCourse
//
//  Created by Andrew Coad on 25/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit

private let defaultColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
private let numSliders = 3


@IBDesignable
class RGBColorPicker: UIControl {

    // MARK: - Private properties
    //
    private var redSlider: ColorSlider = ColorSlider()
    private var greenSlider: ColorSlider = ColorSlider()
    private var blueSlider: ColorSlider = ColorSlider()
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
           redSlider.value = newValue
           greenSlider.value = newValue
           blueSlider.value = newValue
       }
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
        redSlider.addTarget(self, action: #selector(handleSliderValueChanged), for: .valueChanged)
        greenSlider.addTarget(self, action: #selector(handleSliderValueChanged), for: .valueChanged)
        blueSlider.addTarget(self, action: #selector(handleSliderValueChanged), for: .valueChanged)

        redSlider.channel = .red
        greenSlider.channel = .green
        blueSlider.channel = .blue

        self.addSubview(redSlider)
        self.addSubview(greenSlider)
        self.addSubview(blueSlider)
    }

    // MARK: - Rendering
    //
    override func layoutSubviews() {
        super.layoutSubviews()

        let sliderHeight = bounds.height / CGFloat(numSliders)
        redSlider.frame = CGRect(x: 0.0, y: 0.0, width: bounds.width, height: sliderHeight)
        greenSlider.frame = CGRect(x: 0.0, y: sliderHeight, width: bounds.width, height: sliderHeight)
        blueSlider.frame = CGRect(x: 0.0, y: 2 * sliderHeight, width: bounds.width, height: sliderHeight)
    }

    // MARK: - Action handlers
    //
    @objc private func handleSliderValueChanged(_ sender: ColorSlider) {
        _value = sender.value
        sendActions(for: .valueChanged)
   }

}

