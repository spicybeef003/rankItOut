//
//  EnterImagesViewController.swift
//  Dank Ranks Revisited
//
//  Created by Tony Jiang on 8/25/18.
//  Copyright © 2018 Tony Jiang. All rights reserved.
//

import UIKit
import ImagePicker
import Lightbox
import LGButton
import NVActivityIndicatorView
import Disk

class EnterImagesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, ImagePickerDelegate, UITextFieldDelegate, NVActivityIndicatorViewable {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var projectTitleOutlet: UITextField!
    @IBOutlet weak var startRankingButtonOutlet: LGButton!
    @IBOutlet weak var premiumLabel: UILabel!
    
    var myRanks: [Rank]!
    var thisRank: Rank!
    var numObjects: Int = 0
    var imageSets: [UIImage] = []
    var thisRankIndexPathRow: Int!
    
    var delete: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if thisRank.rankFinished {
            self.imageSets = [UIImage](repeating: UIImage(), count: self.thisRank.imageArrayData.count)
            for (index,imageData) in self.thisRank.imageArrayData.enumerated() {
                self.imageSets[index] = UIImage(data: imageData)!
            }
        }

        setupCollectionView()
        
        if !defaults.bool(forKey: "premium") {
            startRankingButtonOutlet.titleString = "Start Ranking*"
            premiumLabel.isHidden = false
        }
        else {
            startRankingButtonOutlet.titleString = "Start Ranking"
            premiumLabel.isHidden = true
        }
    }

    func setupCollectionView() {
        let cellWidth = view.frame.width/3
        let cellSize = CGSize(width: cellWidth , height: cellWidth) // make square
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical //.horizontal
        layout.itemSize = cellSize
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.backgroundColor = UIColor.clear
        collectionView.isScrollEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    @IBAction func selectPhotosPressed(_ sender: LGButton) {
        let config = Configuration()
        config.doneButtonTitle = "Done"
        config.noImagesTitle = "No images found!"
        config.recordLocation = false
        config.allowVideoSelection = false
        
        let imagePicker = ImagePickerController(configuration: config)
        if !defaults.bool(forKey: "premium") {
            imagePicker.imageLimit = 15 - numObjects
        }
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    @IBAction func deletePressed(_ sender: LGButton) {
        delete = !delete
        
        if imageSets.isEmpty {
            
        }
        else if delete {
            sender.titleString = "Done Editing"
        }
        else if !delete {
            sender.titleString = "Delete"
        }
        collectionView.reloadData()
        print(delete)
    }
    
    @IBAction func startRankingPressed(_ sender: LGButton) {
        sender.isEnabled = false
        
        if imageSets.count < thisRank.numSubsets {
            alert(message: "", title: "Please rank at least \(thisRank.numSubsets!) objects" as NSString)
            shake(object: sender)
            sender.isEnabled = true
            return
        }
        
        thisRank.numObj = imageSets.count
        thisRank.projectName = projectTitleOutlet.text!
        thisRank.rankFinished = false
        thisRank.currentComparisonIndex = 0
        thisRank.numTotalComparisons = 0
        thisRank.countIndex = 0
        
        NVActivityIndicatorView.DEFAULT_BLOCKER_BACKGROUND_COLOR = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        NVActivityIndicatorView.DEFAULT_COLOR = .white
        NVActivityIndicatorView.DEFAULT_TEXT_COLOR = .white
        NVActivityIndicatorView.DEFAULT_BLOCKER_MESSAGE = "Loading"
        startAnimating()
        DispatchQueue.global(qos: .userInitiated).async {
            self.thisRank.imageArrayData = []
            for image in self.imageSets {
                self.thisRank.imageArrayData.append(UIImageJPEGRepresentation(image, 1)!)
            }
            self.myRanks.append(self.thisRank)
            self.thisRankIndexPathRow = self.myRanks.count - 1
            
            try? Disk.save(self.myRanks, to: .documents, as: "myRanks.json")
            DispatchQueue.main.async {
                sender.isEnabled = true
                self.goToRankingVC()
            }
        }
    }
    
    func goToRankingVC() {
        let myVC = self.storyboard?.instantiateViewController(withIdentifier: "RankingViewController") as! RankingViewController
        myVC.thisRank = thisRank
        myVC.myRanks = myRanks
        myVC.thisRankIndexPathRow = thisRankIndexPathRow
        self.navigationController?.pushViewController(myVC, animated: true)
    }
    
    // MARK: setup collection view
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageSets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell:MyCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "myCell", for: indexPath) as! MyCollectionViewCell
        
        myCell.myImageView.image = imageSets[indexPath.row]
        myCell.myImageView.contentMode = .scaleAspectFill
        myCell.backgroundColor = UIColor.clear
        myCell.myImageView.layer.borderColor = UIColor.black.cgColor
        myCell.myImageView.layer.borderWidth = 1
        
        if delete {
            let image = UIImage(named: "delete")
            myCell.deleteIcon.image = image
            let loc1 = CGPoint(x: myCell.deleteIcon.frame.midX - 50, y: myCell.deleteIcon.frame.midY - 50)
            let loc2 = myCell.deleteIcon.center
            
            myCell.deleteIcon.frame.origin = loc1
            
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveLinear, animations: {
                myCell.deleteIcon.center = loc2
            }) { (success: Bool) in
                print("Done moving image")
            }
            
            myCell.deleteIcon.transform = CGAffineTransform(rotationAngle: (180.0 * .pi) / 180.0)
            UIView.animate(withDuration: 0.9, animations: {
                myCell.deleteIcon.transform = CGAffineTransform(rotationAngle: CGFloat(0))
            }, completion: { (finished) in
            })
        }
        else {
            myCell.deleteIcon.image = nil
        }
        
        return myCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if delete {
            let myAlert = UIAlertController(title: "Delete photo?", message: "", preferredStyle: UIAlertControllerStyle.alert)
            let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) { (ACTION) in
                self.imageSets.remove(at: indexPath.row)
                self.numObjects =  self.numObjects +  self.imageSets.count
                self.delete = false
                collectionView.reloadData()
            }
            let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default)
            myAlert.addAction(yesAction)
            myAlert.addAction(noAction)
            
            if let popoverController = myAlert.popoverPresentationController {
                popoverController.sourceView = self.view
            }
            self.present(myAlert, animated: true, completion: nil)
        }
        else {
            let myImageViewPage:MyImageViewController = self.storyboard?.instantiateViewController(withIdentifier: "MyImageViewController") as! MyImageViewController
            myImageViewPage.selectedImage = self.imageSets[indexPath.row]
            self.navigationController?.pushViewController(myImageViewPage, animated: true)
        }
        
    }
    
    // MARK: - ImagePickerDelegate
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        guard images.count > 0 else { return }
        
        let lightboxImages = images.map {
            return LightboxImage(image: $0)
        }
        
        let lightbox = LightboxController(images: lightboxImages, startIndex: 0)
        
        imagePicker.present(lightbox, animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        imagePicker.dismiss(animated: true, completion: nil)
        
        for image in images {
            imageSets.append(image)
        }
        numObjects = numObjects + imageSets.count
        collectionView.reloadData()
        print(imageSets.count)
    }

}


class MyCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var deleteIcon: UIImageView!
}
