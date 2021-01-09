//
//  ScanViewController.swift
//  IOTCourse
//
//  Created by Andrew Coad on 07/01/2021.
//  Copyright © 2021 Andrew Coad. All rights reserved.
//

import UIKit

class ScanViewController: UIViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var heading: UILabel!
    @IBOutlet weak var message1: UILabel!
    @IBOutlet weak var message2: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var dismissButton: UIButton!

    @IBAction func dismissButtonTouchUpInside(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupControls()
    }

    // MARK: - Private functions
    //
    private func setupControls() {
        
        contentView.layer.cornerRadius = 8
        if #available(iOS 13, *) {
            spinner.style = .medium
        } else {
            spinner.style = .gray
        }
    }

    // MARK: - Public API
    //
    func setText(heading: String?, message1: String?, message2: String?) {
        if let h = heading { self.heading.text = h }
        if let m1 = message1 { self.message1.text = m1 }
        if let m2 = message2 { self.message2.text = m2 }
    }
    
    func setAnimation(animate: Bool) {
        animate == true ? spinner.startAnimating() : spinner.stopAnimating()
    }

}
