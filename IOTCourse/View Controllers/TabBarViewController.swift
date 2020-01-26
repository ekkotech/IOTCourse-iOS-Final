//
//  TabBarViewController.swift
//  IOTCourse
//
//  Created by Andrew Coad on 26/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewControllers?.forEach { _ = $0.view }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
