//
//  RootViewController.swift
//  IOTCourse
//
//  Created by Andrew Coad on 22/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {

    @IBOutlet weak var leftButtonSwitch: UISwitch!
    @IBOutlet weak var rightButtonSwitch: UISwitch!
    @IBOutlet weak var redLedLabel: UILabel!
    @IBOutlet weak var greenLedLabel: UILabel!
    @IBOutlet weak var redLedButton: UIButton!
    @IBOutlet weak var greenLedButton: UIButton!
    
    var model: Model?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let ad = UIApplication.shared.delegate as? AppDelegate {
            self.model = ad.model
        }
        setupControls()
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        // Red Led
        nc.addObserver(forName: .entityRedLed,
                       object: nil,
                       queue: OperationQueue.main,
                       using: { notification in
                        if let payload = notification.object as? BinaryPayload {
                            self.redLedLabel.backgroundColor = payload.value == true ? UIColor.red : UIColor.clear
                            self.redLedButton.isSelected = payload.value
                        }
        })
        // Green Led
        nc.addObserver(forName: .entityGreenLed,
                       object: nil,
                       queue: OperationQueue.main,
                       using: { notification in
                        if let payload = notification.object as? BinaryPayload {
                            self.greenLedLabel.backgroundColor = payload.value == true ? UIColor.green : UIColor.clear
                            self.greenLedButton.isSelected = payload.value
                        }
        })
        
    }

    // MARK: - Private functions
    //
    private func setupControls() {
        redLedButton.accessibilityLabel = kEntityRedLed
        greenLedButton.accessibilityLabel = kEntityGreenLed
     
        redLedButton.layer.borderColor = UIColor.gray.cgColor
        redLedButton.layer.borderWidth = 1
        redLedButton.layer.cornerRadius = 4
     
        greenLedButton.layer.borderColor = UIColor.gray.cgColor
        greenLedButton.layer.borderWidth = 1
        greenLedButton.layer.cornerRadius = 4
     
        redLedLabel.layer.borderColor = UIColor.gray.cgColor
        redLedLabel.layer.borderWidth = 1
        redLedLabel.layer.cornerRadius = 4
        redLedLabel.clipsToBounds = true

        greenLedLabel.layer.borderColor = UIColor.gray.cgColor
        greenLedLabel.layer.borderWidth = 1
        greenLedLabel.layer.cornerRadius = 4
        greenLedLabel.clipsToBounds = true
    }
    
    // MARK: - UI Action Handlers
    //
    @IBAction func ledButtonTouchUpInside(_ sender: UIButton) {
        guard let md = model, let topic = sender.accessibilityLabel else { return }
        
        md.set(entity: topic, value: !sender.isSelected, response: false)
    }
    
}

