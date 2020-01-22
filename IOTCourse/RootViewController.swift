//
//  RootViewController.swift
//  IOTCourse
//
//  Created by Andrew Coad on 22/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {

    var model: Model?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let ad = UIApplication.shared.delegate as? AppDelegate {
            self.model = ad.model
        }
    }


}

