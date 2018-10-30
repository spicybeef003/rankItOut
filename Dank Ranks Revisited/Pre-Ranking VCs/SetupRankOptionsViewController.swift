//
//  ChooseRankTypeViewController.swift
//  Dank Ranks Revisited
//
//  Created by Tony Jiang on 8/24/18.
//  Copyright © 2018 Tony Jiang. All rights reserved.
//

import UIKit
import LGButton

class SetupRankOptionsViewController: UIViewController {
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var subsetNumberSegmented: UISegmentedControl!
    @IBOutlet weak var createRanksButtonOutlet: LGButton!
    
    var type: String!
    var myRanks: [Rank]!
    var thisRank = Rank()

    override func viewDidLoad() {
        super.viewDidLoad()
    
        questionLabel.isHidden = true
        subsetNumberSegmented.isHidden = true
        createRanksButtonOutlet.isHidden = true
    }
    
    @IBAction func rankTextsPressed(_ sender: LGButton) {
        thisRank.type = "Non-Image"
        questionLabel.text = "How many objects to rank at a time?"
        
        questionLabel.isHidden = false
        questionLabel.transform = CGAffineTransform(translationX: self.view.frame.width, y: 0)
        subsetNumberSegmented.isHidden = false
        subsetNumberSegmented.transform = CGAffineTransform(translationX: self.view.frame.width, y: 0)
        createRanksButtonOutlet.isHidden = false
        createRanksButtonOutlet.transform = CGAffineTransform(translationX: self.view.frame.width, y: 0)
        
        UIView.animate(withDuration: 0.4, animations: {
            self.questionLabel.transform = CGAffineTransform.identity
            self.subsetNumberSegmented.transform = CGAffineTransform.identity
            self.createRanksButtonOutlet.transform = CGAffineTransform.identity
        }, completion: { _ in
        })
    }
    
    @IBAction func rankImagesPressed(_ sender: LGButton) {
        thisRank.type = "Image"
        questionLabel.text = "How many images to rank at a time?"
        
        questionLabel.isHidden = false
        questionLabel.transform = CGAffineTransform(translationX: self.view.frame.width, y: 0)
        subsetNumberSegmented.isHidden = false
        subsetNumberSegmented.transform = CGAffineTransform(translationX: self.view.frame.width, y: 0)
        createRanksButtonOutlet.isHidden = false
        createRanksButtonOutlet.transform = CGAffineTransform(translationX: self.view.frame.width, y: 0)
        
        UIView.animate(withDuration: 0.4, animations: {
            self.questionLabel.transform = CGAffineTransform.identity
            self.subsetNumberSegmented.transform = CGAffineTransform.identity
            self.createRanksButtonOutlet.transform = CGAffineTransform.identity
        }, completion: { _ in
        })
    }
    
    @IBAction func createRanksPressed(_ sender: LGButton) {
        switch subsetNumberSegmented.selectedSegmentIndex {
            case 0: thisRank.numSubsets = 2
            case 1: thisRank.numSubsets = 3
            case 2: thisRank.numSubsets = 4
            default: ()
        }
        
        thisRank.dateCreated = Date()
        thisRank.creatorUniqueDeviceID = UIDevice.current.identifierForVendor!.uuidString
        
        if thisRank.type == "Non-Image" {
            self.performSegue(withIdentifier: "toCreateTextRank", sender: self)
        }
        else {
            self.performSegue(withIdentifier: "toCreateImageRank", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? EnterImagesViewController {
            destination.thisRank = thisRank
            destination.myRanks = myRanks
        }
        
        if let destination = segue.destination as? EnterTextsViewController {
            destination.thisRank = thisRank
            destination.myRanks = myRanks
        }
    }

}
