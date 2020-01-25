//
//  ColorPickerViewController.swift
//  IOTCourse
//
//  Created by Andrew Coad on 25/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit

class ColorPickerViewController: UIViewController {

    @IBOutlet weak var radialPicker: HSBColorPicker!
    @IBOutlet weak var sliderPicker: RGBColorPicker!
    
    var model: Model?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let ad = UIApplication.shared.delegate as? AppDelegate {
            self.model = ad.model
        }

        sliderPicker.addTarget(self, action: #selector(handleSliderValueChange), for: .valueChanged)
        radialPicker.addTarget(self, action: #selector(handleRadialValueChange), for: .valueChanged)
    }

    @objc private func handleSliderValueChange(sender: RGBColorPicker) {
        radialPicker.value = sender.value
        sliderPicker.value = sender.value
    }

    @objc func handleRadialValueChange(sender: HSBColorPicker) {
        radialPicker.value = sender.value
        sliderPicker.value = sender.value
    }

}
