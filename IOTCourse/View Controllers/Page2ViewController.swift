//
//  Page2ViewController.swift
//  IOTCourse
//
//  Created by Andrew Coad on 25/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import UIKit

class Page2ViewController: UIViewController {

    @IBOutlet weak var slider: ColorSlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        slider.addTarget(self, action: #selector(handleSlider), for: .valueChanged)

    }
    
    @objc private func handleSlider(sender: ColorSlider) {
        slider.value = sender.value
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