//
//  AmbientLightViewController.swift
//  IOTCourse
//
//  Created by Andrew Coad on 25/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit

class AmbientLightViewController: UIViewController {
    
    @IBOutlet weak var thresholdPicker: UIPickerView!
    @IBOutlet weak var hysteresisPicker: UIPickerView!
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var offOnSwitch: UISwitch!
    
    private var model: Model?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let ad = UIApplication.shared.delegate as? AppDelegate {
            self.model = ad.model
        }

    }

    // MARK: - Private functions
    //
    private func setupControls() {

    }

    private func setupSubscriptions() {

    }

    private func enableButtons(buttons: [UIButton]) {

    }

    private func disableButtons(buttons: [UIButton]) {

    }

    // MARK: - Gesture Recogniser handler
    //
    @objc private func handlePan(sender: UIPanGestureRecognizer) {

    }

    // MARK: - UI Action Handlers
    //
    @IBAction func applyButtonTouchUpInside(_ sender: UIButton) {

    }

    @IBAction func cancelButtonTouchUpInside(_ sender: UIButton) {

    }

    @IBAction func offOnSwitchValueChanged(_ sender: UISwitch) {

    }

}

// MARK: - Picker View delegate
//
extension AmbientLightViewController : UIPickerViewDelegate {


}

// MARK: - Picker View Data Source
//
extension AmbientLightViewController : UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return 0
    }

}

// MARK: - Gesture Recogniser delegate
//
extension AmbientLightViewController : UIGestureRecognizerDelegate {

}
