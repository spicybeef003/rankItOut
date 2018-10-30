//
//  MyImageView2VC.swift
//  Dank Ranks Revisited
//
//  Created by Tony Jiang on 9/17/18.
//  Copyright © 2018 Tony Jiang. All rights reserved.
//

import UIKit

class MyImageView2VC: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var image: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = image
    }
    
    @IBAction func donePressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
