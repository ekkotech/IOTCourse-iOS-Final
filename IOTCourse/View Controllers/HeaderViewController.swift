//
//  HeaderViewController.swift
//  IOTCourse
//
//  Created by Andrew Coad on 25/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit
import os

//
// Display related constants
//
let notAttachedImageName = "notAttached"
let notConnectedImageName = "notConnected"
let connectedImageName = "connected"

class HeaderViewController: UIViewController {

    @IBOutlet weak var connectStatusImage: UIImageView!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var offOnButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var luminLabel: UILabel!
    @IBOutlet weak var scanButton: UIButton!
    
    var model:Model?
    var svc:ScanViewController  = ScanViewController(nibName: "ScanViewController", bundle: nil)
    var alert: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let ad = UIApplication.shared.delegate as? AppDelegate {
            self.model = ad.model
        }

        let _ = svc.view    // Force resolution of lazy load
        setupControls()
        setupSubscriptions()
        os_log("HeaderViewController initialised", log: Log.ui, type: .info)
    }
    

    // MARK: - Private functions
    //
    private func setupControls() {
        
        svc.modalPresentationStyle = .overCurrentContext

        offOnButton.layer.borderWidth = 1.0
        offOnButton.layer.borderColor = UIColor.lightGray.cgColor
        offOnButton.layer.cornerRadius = offOnButton.frame.height / 4.0
        offOnButton.setImage(UIImage(named: "lampOn"), for: .selected)
        offOnButton.setImage(UIImage(named: "lampOff"), for: .normal)
        //
        scanButton.setImage(UIImage(named: "radar"), for: .normal)
        scanButton.setImage(UIImage(named: "radarLight"), for: .disabled)

    }

    private func setupSubscriptions() {
        
        func showMessage(heading: String?, message1: String?, message2: String?, timeout: TimeInterval?) {

            if svc.presentingViewController != nil {
            // Scan view controller is being displayed
            svc.setText(heading: heading, message1: message1, message2: message2)
            if let to = timeout {
                DispatchQueue.main.asyncAfter(deadline: .now() + to) {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
        
        nc.addObserver(forName: .bleStatus,
                       object: nil,
                       queue: OperationQueue.main,
                       using: { notification in
                        if let payload = notification.object as? BleStatusPayload {
                            switch payload.status {
                            case .onLine:
                                self.connectStatusImage.image = UIImage(named: notAttachedImageName)
                                self.scanButton.isEnabled = true
                            case .offLine:
                                self.connectStatusImage.image = UIImage(named: notAttachedImageName)
                                self.showAlert(title: "Bluetooth is off-line", message: "Please switch on in Settings")
                                self.scanButton.isEnabled = true
                            case .scanning, .retrieving:
                                let msg = payload.status == .scanning ? "Scanning..." : "Retrieving..."
                                self.connectStatusImage.image = UIImage(named: notAttachedImageName)
                                self.scanButton.isEnabled = false
                                showMessage(heading: msg, message1: nil, message2: nil, timeout: nil)
                            case .retrieveSuccess:
                                showMessage(heading: nil, message1: "Peripheral retrieved:", message2: payload.info, timeout: 2)
                            case .scanSuccess:
                                showMessage(heading: nil, message1: "Peripheral discovered:", message2: payload.info, timeout: 2)
                            case .scanTimeout:
                                self.connectStatusImage.image = UIImage(named: notAttachedImageName)
                                showMessage(heading: "Scan timed out...", message1: nil, message2: nil, timeout: 2)
                                self.scanButton.isEnabled = true
                            case .connected:
                                self.connectStatusImage.image = UIImage(named: connectedImageName)
                                self.scanButton.isEnabled = false
                            case .disconnected:
                                self.connectStatusImage.image = UIImage(named: notConnectedImageName)
                                self.scanButton.isEnabled = true
                            default:
                                break
                            }

                            self.rssiLabel.text = "---"
                        }
        })
        /*nc.addObserver(forName: .connectStatus,
                       object: nil,
                       queue: OperationQueue.main,
                       using: { notification in
                            if let payload = notification.object as? ConnectStatusPayload {
                                if payload.status == .connected {
                                    self.connectStatusImage.image = UIImage(named: connectedImageName)
                                    self.scanButton.isEnabled = false
                                }
                                else if payload.status == .disconnected {
                                    self.connectStatusImage.image = UIImage(named: notConnectedImageName)
                                    self.scanButton.isEnabled = true
                                }
                        }
        })*/
        nc.addObserver(forName: .rssiValueChanged,
                       object: nil,
                       queue: OperationQueue.main,
                       using: { notification in
                        if let payload = notification.object as? RssiValueChangedPayload {
                            self.rssiLabel.text = "\(payload.value)" + "dBm"
                        }
        })
        nc.addObserver(forName: .entityLssOffOn,
                       object: nil,
                       queue: OperationQueue.main,
                       using: { notification in
                        if let payload = notification.object as? BinaryPayload {
                            self.offOnButton.isSelected = payload.value
                        }
        })
        nc.addObserver(forName: .entityAlsLumin,
                       object: nil,
                       queue: OperationQueue.main,
                       using: { notification in
                        if let payload = notification.object as? IntegerPayload {
                            self.luminLabel.text = "\(payload.value)"
                        }
        })

    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
        alert.addAction(dismissAction)
        self.present(alert, animated: true)
    }
    
    // MARK: - IBAction handlers
    //
    @IBAction func offOnButtonTouchUpInside(_ sender: UIButton) {
        if let md = model {
            md.set(entity: kEntityLssOffOn, value: !sender.isSelected, response: false)
        }
    }
    @IBAction func scanButtonTouchUpInside(_ sender: Any) {

        if svc.presentingViewController == nil {
            svc.setAnimation(animate: true)
            present(svc, animated: true, completion: nil)
            model?.scan()
        }
    }
}
