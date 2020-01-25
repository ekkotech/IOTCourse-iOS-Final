//
//  HeaderViewController.swift
//  IOTCourse
//
//  Created by Andrew Coad on 25/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit

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
    
    var model: Model?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let ad = UIApplication.shared.delegate as? AppDelegate {
            self.model = ad.model
        }

        setupControls()
        setupSubscriptions()
    }
    

    // MARK: - Private functions
    //
    private func setupControls() {
        
        offOnButton.layer.borderWidth = 1.0
        offOnButton.layer.borderColor = UIColor.lightGray.cgColor
        offOnButton.layer.cornerRadius = offOnButton.frame.height / 4.0
        offOnButton.setImage(UIImage(named: "lampOn"), for: .selected)
        offOnButton.setImage(UIImage(named: "lampOff"), for: .normal)

    }

    private func setupSubscriptions() {
        nc.addObserver(forName: .bleStatus,
                       object: nil,
                       queue: OperationQueue.main,
                       using: { notification in
                        if let payload = notification.object as? BleStatusPayload {
                            if payload.status == .ready {
                                self.connectStatusImage.image = UIImage(named: notConnectedImageName)
                            }
                            else {
                                self.connectStatusImage.image = UIImage(named: notAttachedImageName)
                            }
                            self.rssiLabel.text = "---"
                        }
        })
        nc.addObserver(forName: .connectStatus,
                       object: nil,
                       queue: OperationQueue.main,
                       using: { notification in
                            if let payload = notification.object as? ConnectStatusPayload {
                                if payload.status == .connected {
                                    self.connectStatusImage.image = UIImage(named: connectedImageName)
                                }
                                else if payload.status == .disconnected {
                                    self.connectStatusImage.image = UIImage(named: notConnectedImageName)
                                }
                        }
        })
        nc.addObserver(forName: .rssiValueChanged,
                       object: nil,
                       queue: OperationQueue.main,
                       using: { notification in
                        if let payload = notification.object as? RssiValueChangedPayload {
                            self.rssiLabel.text = "\(payload.value)" + "dBm"
                        }
        })

    }

}
