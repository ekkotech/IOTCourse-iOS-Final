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

}
