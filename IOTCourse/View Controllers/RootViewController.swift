//
//  RootViewController.swift
//  IOTCourse
//
//  Created by Andrew Coad on 22/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit
import os

class RootViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("RootViewController in viewDidLoad", log: Log.ui, type: .info)
    }

}

