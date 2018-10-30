//
//  MyImageViewController.swift
//  DankRanks
//
//  Created by Jiang, Tony on 12/6/17.
//  Copyright © 2017 Jiang, Tony. All rights reserved.
//

import UIKit

class MyImageViewController: UIViewController {
    
    @IBOutlet weak var myImageView: UIImageView!
    var selectedImage:UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        myImageView.image = selectedImage
        myImageView.backgroundColor = UIColor.clear
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
