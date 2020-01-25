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
        
        setupSubscriptions()
    }

    // MARK: - Private functions
    //
    private func setupSubscriptions() {
        
        nc.addObserver(forName: .entityLssRgb,
                       object: nil,
                       queue: OperationQueue.main,
                       using: {notification in
                        if let payload = notification.object as? RgbPayload {
                            let newColor = UIColor(red: CGFloat(payload.rgb.red),
                                                   green: CGFloat(payload.rgb.green),
                                                   blue: CGFloat(payload.rgb.blue),
                                                   alpha: 1.0)
                            self.sliderPicker.value = newColor
                            self.radialPicker.value = newColor
                        }
        })

    }

    @objc private func handleSliderValueChange(sender: RGBColorPicker) {
        updateModel(color: sender.value)
    }

    @objc private func handleRadialValueChange(sender: HSBColorPicker) {
        updateModel(color: sender.value)
    }

    private func updateModel(color: UIColor) {
        if let md = model {
            md.set(entity: kEntityLssRgb, value: Rgb(red: Float(color.rgba.red),
                                                     green: Float(color.rgba.green),
                                                     blue: Float(color.rgba.blue)),
                   response: false)
        }
    }

}
