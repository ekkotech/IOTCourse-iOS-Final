//
//  AmbientLightViewController.swift
//  IOTCourse
//
//  Created by Andrew Coad on 25/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit

private let buttonBorderColor = UIColor(red: 109.0/255, green: 109.0/255, blue: 109.0/255, alpha: 1.0)  // Mid-grey
private let buttonBorderWidth: CGFloat = 1.0
private let buttonCornerRadiusDivisor: CGFloat = 4.0
private let buttonNormalBgColor = UIColor.white
private let buttonSelectedBgColor = UIColor(red: 45.0/255, green: 123.0/255, blue: 158.0/255, alpha: 1.0)   // Dark blue
private let buttonSelectedTitleColor = UIColor.white
private let buttonNormalTitleColor = UIColor(red: 45.0/255, green: 123.0/255, blue: 158.0/255, alpha: 1.0)

class AmbientLightViewController: UIViewController {
    
    @IBOutlet weak var thresholdPicker: UIPickerView!
    @IBOutlet weak var hysteresisPicker: UIPickerView!
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var offOnSwitch: UISwitch!
    
    private var model: Model?
    private var priorState: (threshRow: Int, hystRow: Int) = (0, 0)

    override func viewDidLoad() {
        super.viewDidLoad()

        if let ad = UIApplication.shared.delegate as? AppDelegate {
            self.model = ad.model
        }

        thresholdPicker.delegate = self
        thresholdPicker.dataSource = self
        hysteresisPicker.delegate = self
        hysteresisPicker.dataSource = self
        
        setupControls()
        setupSubscriptions()
    }

    // MARK: - Private functions
    //
    private func setupControls() {
        applyButton.layer.borderColor = buttonBorderColor.cgColor
        applyButton.layer.borderWidth = buttonBorderWidth
        applyButton.layer.cornerRadius = applyButton.layer.bounds.height / buttonCornerRadiusDivisor
        applyButton.setTitleColor(buttonNormalTitleColor, for: .normal)
        applyButton.setTitleColor(buttonSelectedTitleColor, for: .selected)
        applyButton.titleLabel?.backgroundColor = UIColor.clear
        applyButton.tintColor = UIColor.clear
        applyButton.isEnabled = false
        applyButton.isSelected = false

        cancelButton.layer.borderColor = buttonBorderColor.cgColor
        cancelButton.layer.borderWidth = buttonBorderWidth
        cancelButton.layer.cornerRadius = cancelButton.layer.bounds.height / buttonCornerRadiusDivisor
        cancelButton.setTitleColor(buttonNormalTitleColor, for: .normal)
        cancelButton.setTitleColor(buttonSelectedTitleColor, for: .selected)
        cancelButton.titleLabel?.backgroundColor = UIColor.clear
        cancelButton.tintColor = UIColor.clear
        cancelButton.isEnabled = false
        cancelButton.isSelected = false

        let pgr1 = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pgr1.delegate = self
        thresholdPicker.addGestureRecognizer(pgr1)
        let pgr2 = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pgr2.delegate = self
        hysteresisPicker.addGestureRecognizer(pgr2)
    }

    private func setupSubscriptions() {
        nc.addObserver(forName: .entityAlsThresh,
                       object: nil,
                       queue: OperationQueue.main,
                       using: { notification in
                        if let payload = notification.object as? IntegerPayload {
                            self.thresholdPicker.selectRow(payload.value - alsThreshMinValue,
                                                            inComponent: 0,
                                                            animated: true)
                            self.disableButtons(buttons: [self.applyButton, self.cancelButton])
                        }
        })
        nc.addObserver(forName: .entityAlsHyst,
                       object: nil,
                       queue: OperationQueue.main,
                       using: { notification in
                        if let payload = notification.object as? IntegerPayload {
                            self.hysteresisPicker.selectRow(payload.value - alsHystMinValue,
                                                            inComponent: 0,
                                                            animated: true)
                            self.disableButtons(buttons: [self.applyButton, self.cancelButton])
                        }
        })
        nc.addObserver(forName: .entityAlsOffOn,
                       object: nil,
                       queue: OperationQueue.main,
                       using: {notification in
                        if let payload = notification.object as? BinaryPayload {
                            self.offOnSwitch.isOn = payload.value
                            self.thresholdPicker.isUserInteractionEnabled = payload.value
                            self.hysteresisPicker.isUserInteractionEnabled = payload.value
                        }
        })
    }

    private func enableButtons(buttons: [UIButton]) {
        buttons.forEach {
            $0.isEnabled = true
            $0.isSelected = true
            $0.backgroundColor = buttonSelectedBgColor
        }
    }

    private func disableButtons(buttons: [UIButton]) {
        buttons.forEach {
            $0.isEnabled = false
            $0.isSelected = false
            $0.backgroundColor = buttonNormalBgColor
        }
    }

    // MARK: - Gesture Recogniser handler
    //
    @objc private func handlePan(sender: UIPanGestureRecognizer) {
        if sender.state == .began && applyButton.isEnabled == false {
            priorState = (thresholdPicker.selectedRow(inComponent: 0), hysteresisPicker.selectedRow(inComponent: 0))
            enableButtons(buttons: [applyButton, cancelButton])
        }
    }

    // MARK: - UI Action Handlers
    //
    @IBAction func applyButtonTouchUpInside(_ sender: UIButton) {
        if let md = model {
            md.set(entity: kEntityAlsThresh,
                   value: thresholdPicker.selectedRow(inComponent: 0) + alsThreshMinValue,
                   response: false)
            md.set(entity: kEntityAlsHyst,
                   value: hysteresisPicker.selectedRow(inComponent: 0) + alsHystMinValue,
                   response: false)
            disableButtons(buttons: [applyButton, cancelButton])
            priorState = (0, 0)
        }
    }

    @IBAction func cancelButtonTouchUpInside(_ sender: UIButton) {
        thresholdPicker.selectRow(priorState.threshRow, inComponent: 0, animated: true)
        hysteresisPicker.selectRow(priorState.hystRow, inComponent: 0, animated: true)
        disableButtons(buttons: [applyButton, cancelButton])
    }

    @IBAction func offOnSwitchValueChanged(_ sender: UISwitch) {
        if let md = model {
            md.set(entity: kEntityAlsOffOn, value: sender.isOn, response: false)
        }
    }

}

// MARK: - Picker View delegate
//
extension AmbientLightViewController : UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == thresholdPicker {
            return "\(row + alsThreshMinValue)"
        }
        else if pickerView == hysteresisPicker {
            return "\( row + alsHystMinValue )"
        }
        
        return nil
    }

}

// MARK: - Picker View Data Source
//
extension AmbientLightViewController : UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == thresholdPicker {
            return (alsThreshMaxValue - alsThreshMinValue) + 1
        }
        else if pickerView == hysteresisPicker {
            return (alsHystMaxValue - alsHystMinValue) + 1
        }
        
        return 0
    }

}

// MARK: - Gesture Recogniser delegate
//
extension AmbientLightViewController : UIGestureRecognizerDelegate {
    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
