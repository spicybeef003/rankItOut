//
//  ShareRankPopoverViewController.swift
//  Dank Ranks Revisited
//
//  Created by Tony Jiang on 8/31/18.
//  Copyright © 2018 Tony Jiang. All rights reserved.
//

import UIKit
import LGButton

protocol ShareRankPopoverViewControllerDelegate: class {
    func shareRank(username: String, rankname: String, isPublic: Bool)
}

class ShareRankPopoverViewController: UIViewController {

    @IBOutlet weak var popoverView: UIView!
    @IBOutlet weak var projectNameTextfield: UITextField!
    @IBOutlet weak var usernameTextfield: UITextField!
    @IBOutlet weak var publicSwitchOutlet: UISwitch!
    @IBOutlet weak var publicLabel: UILabel!
    @IBOutlet weak var publicExplanationLabel: UILabel!
    @IBOutlet weak var shareButtonOutlet: LGButton!
    
    var delegate: ShareRankPopoverViewControllerDelegate?
    
    var username: String?
    var rankname: String?
    var existingProjectNames: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        popoverView.layer.cornerRadius = 10
        
        if rankname?.count != 0 {
            projectNameTextfield.text = rankname
            projectNameTextfield.isUserInteractionEnabled = false
            publicSwitchOutlet.isHidden = true
        }
        
        if username != nil {
            usernameTextfield.text = username
            usernameTextfield.isUserInteractionEnabled = false
        }
        
        publicLabel.text = publicSwitchOutlet.isOn ? "Public rank" : "Private rank"
        publicExplanationLabel.text = publicSwitchOutlet.isOn ? "Ranks will be searchable, and results of friends can be viewed." : "Ranks will not be searchable, and results of friends cannot be viewed."
    }
    
    @IBAction func switchPressed(_ sender: UISwitch) {
        publicLabel.text = publicSwitchOutlet.isOn ? "Public rank" : "Private rank"
        publicExplanationLabel.text = publicSwitchOutlet.isOn ? "Ranks will be searchable, and results of friends can be viewed." : "Ranks will not be searchable, and results of friends cannot be viewed."
    }
    
    @IBAction func sharePressed(_ sender: LGButton) {
        if projectNameTextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { 
            alert(message: "", title: "Please name this project")
            shake(object: sender)
            return
        }
        if existingProjectNames.contains(projectNameTextfield.text!.lowercased()) {
            alert(message: "Enter another name and try again.", title: "Sorry this project name is taken!")
            shake(object: sender)
            return
        }
        if usernameTextfield.text!.isEmpty {
            alert(message: "", title: "Please enter a username to be associated with this project")
            shake(object: sender)
            return
        }
        username = usernameTextfield.text!
        rankname = projectNameTextfield.text!.lowercased()
        delegate?.shareRank(username: username!, rankname: rankname!, isPublic: publicSwitchOutlet.isOn)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPressed(_ sender: LGButton) {
        self.dismiss(animated: true, completion: nil)
    }

}
