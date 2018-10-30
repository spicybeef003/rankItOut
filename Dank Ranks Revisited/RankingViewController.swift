//
//  RankingViewController.swift
//  TieBreakers
//
//  Created by Jiang, Tony on 11/25/17.
//  Copyright © 2017 Jiang, Tony. All rights reserved.
//

import UIKit
import Combinatorics
import EVCloudKitDao
import KRProgressHUD
import NVActivityIndicatorView
import Disk
import SwiftMessages

class RankingViewController: UIViewController, UIPopoverPresentationControllerDelegate, UIScrollViewDelegate, NVActivityIndicatorViewable, ModifyRankingsVCDelegate {
    
    @IBOutlet weak var modifyOutlet: UIBarButtonItem!
    
    var myRanks: [Rank]!
    var thisRank: Rank!
    var thisRankIndexPathRow: Int?
    
    var uniqueID:String!
    var refSet: [(name: String, image: UIImage)]!
    
    var name:String!
    var numObj:Int!
    var numSubsets:Int!
    var textArray:[String] = [] // array of entered objects
    var shuffledArray:[String] = [] // shuffled array of entered objects
    var imageSets:[UIImage] = [] // array of entered photos
    var resizeImageSets:[UIImage] = [] // array of resized entered photos
    var shuffledImageSet:[UIImage] = [] // shuffled array of entered photos
    
    var countIndex:Int = 0 // lets you know the index of the next object to grab from the shuffledArray
    var ranks:[UILabel] = [] //holds the ranking # and placeholders objects
    var objectHolders:[UILabel] = [] //contains frame for objects to be compared
    var imageHolders:[UIImageView] = [] // contains view for images to be compared
    var initialLocation: CGPoint!
    let miniranks = ["#1","#2","#3","#4"]
    var type:String!
    
    var nextButton: UIButton!
    var previousButton: UIButton!
    var resetButton: UIButton!
    var currentStandingsButton: UIButton!
    var displayCurrentRankButton: UIButton!
    
    var finalRankArray:[String] = [] // holds final ranking
    var finalRankImageArray:[UIImage] = [] // holds final ranking for images
    var finalRankImageArrayFullSize:[UIImage] = [] // full size final images
    var miniRankResults:[String] = [] // holds results from subset comparison
    var resetMiniRankResultsArray:[String] = []
    var miniRankImageResults:[UIImage] = []
    var resetMiniRankImageResultsArray:[UIImage] = [] // use this to reset the miniRankImageResults array after each comparison
    var numTotalComparisons:Int = 0
    var currentComparisonIndex:Int!
    var remainingIndices:[Int] = [] // know when to stop comparisons for a given object
    
    var comparisonLabel:UILabel!
    var spotOccupiedInMiniRank:[Bool] = [] // holds info to know if a spot is occupied in the comparison view
    
    var arrayOfValues:[Int] = [] // holds value associated with final rank for subsets >= 3
    var allCombinations:[[String]] = [] // contains all possible combinations for c >= 3
    var previousComparisons:[[String]] = []
    var previousImageComparisons:[[UIImage]] = []
    
    var saveButton: UIBarButtonItem!
    var dispatchSave: DispatchWorkItem?
    
    var nextGroup:[String] = []
    var nextImageGroup:[UIImage] = []
    var done:Bool = false
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var publicRank: Bool! // if true, this is a shared rank and give option to see compilation
    
    var selectedImage: UIImage!
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NVActivityIndicatorView.DEFAULT_BLOCKER_BACKGROUND_COLOR = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        NVActivityIndicatorView.DEFAULT_COLOR = .white
        NVActivityIndicatorView.DEFAULT_TEXT_COLOR = .white
        NVActivityIndicatorView.DEFAULT_BLOCKER_MESSAGE = "Finalizing"
        startAnimating()
        
        if let _ = self.appDelegate.rankName {
            self.loadAppDelegateInfo()
            self.stopAnimating()
            self.publicRank = true
        }
        else {
            transferData()
            DispatchQueue.main.async {
                self.tabBarController?.tabBar.isHidden = true
                
                self.navigationItem.setHidesBackButton(true, animated: true)
                
                self.loadPlaceHolders(subsetSize: self.numSubsets)
                self.createObjectHolders(subsetSize: self.numSubsets)
                self.loadComparisonLabel()
                self.loadLowerButtons()
                self.setupRanks()
                self.stopAnimating()
            }
        }
        
        modifyOutlet.title = numSubsets == 2 ? "Add" : "Modify"
    }
    
    @IBAction func modifyPressed(_ sender: UIBarButtonItem) {
        self.savePressed(nil)
        self.performSegue(withIdentifier: "toModifyRanks", sender: self)
    }
    
    func transferData() {
        name = thisRank.projectName
        numObj = thisRank.numObj
        numSubsets = thisRank.numSubsets
        textArray = thisRank.textArray
        type = thisRank.type
        currentComparisonIndex = thisRank.currentComparisonIndex
        numTotalComparisons = thisRank.numTotalComparisons
        finalRankArray = thisRank.finalRankTextArray
        shuffledArray = thisRank.shuffledTexArray
        nextGroup = thisRank.nextGroup
        countIndex = thisRank.countIndex
        publicRank = thisRank.publicRank
        
        self.finalRankImageArray = [UIImage](repeating: UIImage(), count: self.thisRank.finalRankSmallSizeImageArrayData.count)
        for (index,imageData) in self.thisRank.finalRankSmallSizeImageArrayData.enumerated() {
            self.finalRankImageArray[index] = UIImage(data: imageData)!
        }
        self.finalRankImageArrayFullSize = [UIImage](repeating: UIImage(), count: self.thisRank.finalRankFullSizeImageArrayData.count)
        for (index,imageData) in self.thisRank.finalRankFullSizeImageArrayData.enumerated() {
            self.finalRankImageArrayFullSize[index] = UIImage(data: imageData)!
        }
        self.imageSets = [UIImage](repeating: UIImage(), count: self.thisRank.imageArrayData.count)
        for (index,imageData) in self.thisRank.imageArrayData.enumerated() {
            self.imageSets[index] = UIImage(data: imageData)!
        }
        self.shuffledImageSet = [UIImage](repeating: UIImage(), count: self.thisRank.shuffledImageArrayData.count)
        for (index,imageData) in self.thisRank.shuffledImageArrayData.enumerated() {
            self.shuffledImageSet[index] = UIImage(data: imageData)!
        }
    }
    
    
    @IBAction func endComparisonPressed(_ sender: UIBarButtonItem) {
        let myAlert = UIAlertController(title: "Options", message: nil, preferredStyle: .alert)
        let pauseAction = UIAlertAction(title: "Pause Ranking", style: UIAlertActionStyle.default) { (ACTION) in
            self.savePressed(nil)
            let tabbarVC = self.storyboard?.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
            self.present(tabbarVC, animated: false, completion: nil)
        }
        let stopAction = UIAlertAction(title: "End Ranking", style: UIAlertActionStyle.default) { _ in
            let stopAlert = UIAlertController(title: "Prematurely stop ranking? This can't be reversed.", message: nil, preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) { (ACTION) in
                if !self.finalRankArray.isEmpty || !self.finalRankImageArray.isEmpty {
                    if self.type == "Image" && self.numSubsets != 2 {
                        let count = self.arrayOfValues.count
                        let tempSortedTuples = (0..<count).map { (self.arrayOfValues[$0], self.imageSets[$0]) }.sorted { $0.0 > $1.0 }
                        
                        self.finalRankImageArrayFullSize = tempSortedTuples.map { $0.1 }
                    }
                    self.thisRank.rankFinished = true
                    self.myRanks[self.thisRankIndexPathRow!] = self.thisRank
                    DispatchQueue.global(qos: .userInitiated).async {
                        try? Disk.save(self.myRanks, to: .documents, as: "myRanks.json")
                        self.savePressed(nil)
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "toRankingResults", sender: self)
                        }
                    }
                }
                else {
                    self.alert(message: "Too early to end comparisons!", title: "Alert!")
                }
            }
            let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default)
            stopAlert.addAction(yesAction)
            stopAlert.addAction(noAction)
            
            if let popoverController = stopAlert.popoverPresentationController {
                popoverController.sourceView = self.view
            }
            self.present(stopAlert, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        myAlert.addAction(pauseAction)
        myAlert.addAction(stopAction)
        myAlert.addAction(cancelAction)
        
        if let popoverController = myAlert.popoverPresentationController {
            popoverController.sourceView = self.view
        }
        self.present(myAlert, animated: true, completion: nil)
    }
    
    @IBAction func savePressed(_ sender: UIBarButtonItem?) {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.thisRank.type == "Image" {
                var finalRankFullSizeImageArrayData: [Data] = []
                var finalRankSmallSizeImageArrayData: [Data] = []
                for image in self.finalRankImageArrayFullSize {
                    finalRankFullSizeImageArrayData.append(UIImageJPEGRepresentation(image, 1)!)
                }
                
                for image in self.finalRankImageArray {
                    finalRankSmallSizeImageArrayData.append(UIImageJPEGRepresentation(image, 1)!)
                }
                
                var shuffledImageArrayData: [Data] = []
                var imageArrayData: [Data] = []
                for (index,image) in self.imageSets.enumerated() {
                    shuffledImageArrayData.append(UIImageJPEGRepresentation(self.shuffledImageSet[index], 1)!)
                    imageArrayData.append(UIImageJPEGRepresentation(image, 1)!)
                }
                
                var nextImageGroupIndexes: [Int] = []
                for image in self.nextImageGroup {
                    nextImageGroupIndexes.append(self.compareImage(image: image, imageArray: self.resizeImageSets))
                }
                
                self.thisRank.finalRankFullSizeImageArrayData = finalRankFullSizeImageArrayData
                self.thisRank.finalRankSmallSizeImageArrayData = finalRankSmallSizeImageArrayData
                self.thisRank.shuffledImageArrayData = shuffledImageArrayData
                self.thisRank.imageArrayData = imageArrayData
                self.thisRank.nextImageGroupIndexes = nextImageGroupIndexes
            }
            else {
                self.thisRank.finalRankTextArray = self.finalRankArray
                self.thisRank.shuffledTexArray = self.shuffledArray
                self.thisRank.nextGroup = self.nextGroup
            }
            
            self.thisRank.currentComparisonIndex = self.currentComparisonIndex
            self.thisRank.numTotalComparisons = self.numTotalComparisons
            self.thisRank.countIndex = self.countIndex
            
            self.myRanks[self.thisRankIndexPathRow!] = self.thisRank
            
            DispatchQueue.main.async {
                try? Disk.save(self.myRanks, to: .documents, as: "myRanks.json")
                SwiftMessages.show {
                    let view = MessageView.viewFromNib(layout: .statusLine)
                    view.configureTheme(.success)
                    view.configureDropShadow()
                    view.configureContent(title: "Success!", body: "Saved!")
                    return view
                }
            }
        }
    }
    
    func modifiedRankings(newRank: Rank, newArrayOfValues: [Int]) {
        thisRank = newRank
        arrayOfValues = newArrayOfValues
        transferData()
        
        if self.thisRank.numTotalComparisons > 0 { // user has loaded saved data
            switch (self.numSubsets, self.type) {
            case (2, "Non-Image"):
                self.createNextComparison(textArray: [self.finalRankArray[self.currentComparisonIndex], self.shuffledArray[self.countIndex-1]], imageArray: self.imageSets, numNewObjects: 0)
            case (2, "Image"):
                self.createNextComparison(textArray: self.textArray, imageArray: [self.finalRankImageArray[self.currentComparisonIndex], self.shuffledImageSet[self.countIndex-1]], numNewObjects: 0)
            case (_, "Non-Image"):
                let nextImageGroup: [UIImage] = []
                self.createNextComparison(textArray: self.nextGroup, imageArray: nextImageGroup, numNewObjects: 0)
            case (_, "Image"):
                self.resizeImageSets = [UIImage](repeating: UIImage(), count: self.imageSets.count)
                for (index, image) in self.imageSets.enumerated() {
                    self.resizeImageSets[index] = image.resizeImage(targetSize: CGSize(width: self.view.frame.width/3, height: self.view.frame.height/4))
                }
                self.shuffledImageSet = self.resizeImageSets.shuffled()
                
                self.nextImageGroup = []
                for index in self.thisRank.nextImageGroupIndexes {
                    self.nextImageGroup.append(self.resizeImageSets[index])
                }
                self.createNextComparison(textArray: self.nextGroup, imageArray: self.nextImageGroup, numNewObjects: 0)
            default: ()
            }
        }
        else { // 1st comparison
            self.countIndex = 0
            if self.type == "Non-Image" {
                self.shuffledArray = self.textArray.shuffled() // shuffle input objects
                self.createFirstComparison(textArray: self.shuffledArray, imageArray: self.imageSets, subsetSize: self.numSubsets) // set up 1st comparison to get started
            }
            else if self.type == "Image" {
                self.resizeImageSets = [UIImage](repeating: UIImage(), count: self.imageSets.count)
                for (index, image) in self.imageSets.enumerated() {
                    self.resizeImageSets[index] = image.resizeImage(targetSize: CGSize(width: self.view.frame.width/3, height: self.view.frame.height/4))
                }
                self.shuffledImageSet = self.resizeImageSets.shuffled()
                self.createFirstComparison(textArray: self.textArray, imageArray: self.shuffledImageSet, subsetSize: self.numSubsets) // set up 1st comparison to get started
            }
        }
    }
    
    func setupRanks() {
        DispatchQueue.main.async {
            // initialize the mini subset rank array
            for _ in 0..<self.numSubsets {
                self.miniRankResults.append("")
                self.resetMiniRankResultsArray.append("")
            }
            self.miniRankImageResults = [UIImage](repeating: UIImage(), count: self.numSubsets)
            self.resetMiniRankImageResultsArray = [UIImage](repeating: UIImage(), count: self.numSubsets)
            self.resizeImageSets = [UIImage](repeating: UIImage(), count: self.imageSets.count)
            
            // initialize the spot occupation for mini rank array
            for _ in 0...(self.numSubsets-1) {
                self.spotOccupiedInMiniRank.append(false)
            }
            for _ in self.numSubsets...(self.numSubsets*2-1) {
                self.spotOccupiedInMiniRank.append(true)
            }
            
            // initialize the array value in case subset = 3
            if self.arrayOfValues.count < self.numObj {
                for _ in 0..<self.numObj {
                    self.arrayOfValues.append(0)
                }
            }
            
            if self.thisRank.numTotalComparisons > 0 { // user has loaded saved data
                switch (self.numSubsets, self.type) {
                case (2, "Non-Image"):
                    self.createNextComparison(textArray: [self.finalRankArray[self.currentComparisonIndex], self.shuffledArray[self.countIndex-1]], imageArray: self.imageSets, numNewObjects: 0)
                case (2, "Image"):
                    self.createNextComparison(textArray: self.textArray, imageArray: [self.finalRankImageArray[self.currentComparisonIndex], self.shuffledImageSet[self.countIndex-1]], numNewObjects: 0)
                case (_, "Non-Image"):
                    let nextImageGroup: [UIImage] = []
                    self.createNextComparison(textArray: self.nextGroup, imageArray: nextImageGroup, numNewObjects: 0)
                case (_, "Image"):
                    for (index, image) in self.imageSets.enumerated() {
                        self.resizeImageSets[index] = image.resizeImage(targetSize: CGSize(width: self.view.frame.width/3, height: self.view.frame.height/4))
                        self.shuffledImageSet[index] = self.shuffledImageSet[index].resizeImage(targetSize: CGSize(width: self.view.frame.width/3, height: self.view.frame.height/4))
                    }
                    for index in self.thisRank.nextImageGroupIndexes {
                        self.nextImageGroup.append(self.resizeImageSets[index])
                    }
                    self.createNextComparison(textArray: self.nextGroup, imageArray: self.nextImageGroup, numNewObjects: 0)
                default: ()
                }
            }
            else { // 1st comparison
                self.countIndex = 0
                if self.type == "Non-Image" {
                    self.shuffledArray = self.textArray.shuffled() // shuffle input objects
                    self.createFirstComparison(textArray: self.shuffledArray, imageArray: self.imageSets, subsetSize: self.numSubsets) // set up 1st comparison to get started
                }
                else if self.type == "Image" {
                    for (index, image) in self.imageSets.enumerated() {
                        self.resizeImageSets[index] = image.resizeImage(targetSize: CGSize(width: self.view.frame.width/3, height: self.view.frame.height/4))
                    }
                    self.shuffledImageSet = self.resizeImageSets.shuffled()
                    self.createFirstComparison(textArray: self.textArray, imageArray: self.shuffledImageSet, subsetSize: self.numSubsets) // set up 1st comparison to get started
                }
            }
        }
        
    }
    
    func loadAppDelegateInfo() {
        if Disk.exists("myRanks.json", in: .documents) {
            self.myRanks = try! Disk.retrieve("myRanks.json", from: .documents, as: [Rank].self)
        }
        else {
            self.myRanks = []
            try? Disk.save(self.myRanks, to: .documents, as: "myRanks.json")
        }
        
        var rankName = appDelegate.rankName
        if (rankName!.components(separatedBy: "_")).count > 1 {
            rankName = (rankName!.components(separatedBy: "_")).joined(separator: " ")
        }
        let predicate = NSPredicate(format: "Rankname == %@", rankName!)
        
        dao.query(RankInfoss(), predicate: predicate, completionHandler: { results, bool in
            var rankInfo: RankInfoss!
            if results.count != 0 {
                rankInfo = results[0] // all should have the same arrays, just diff order; dont allow duplicate names
            }
            else {
                DispatchQueue.main.async {
                    KRProgressHUD.set(deadlineTime: 4.5)
                    KRProgressHUD.set(font: UIFont.systemFont(ofSize: Env.iPad ? 24 : 16))
                    KRProgressHUD.showError(withMessage: "Could not find Ranking Project")
                    let homeVC = self.storyboard?.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
                    self.present(homeVC, animated: false, completion: nil)
                }
                return false
            }
            
            self.type = rankInfo.RankType
            
            self.refSet = []
            if self.type == "Image" {
                for i in 0..<rankInfo.NumObj { // use the first set as reference
                    self.imageSets.append(rankInfo.imageArray[i].image()!)
                    self.refSet.append((rankInfo.textArray[i], rankInfo.imageArray[i].image()!))
                }
            }
            
            self.name = rankInfo.Rankname
            self.numObj = rankInfo.NumObj
            self.numSubsets = rankInfo.numSubsets
            self.textArray = Array(rankInfo.textArray[0..<rankInfo.numSubsets]) // use first set as reference
            self.uniqueID = rankInfo.uniqueID
            
            self.thisRank = self.convertStructures(rank: rankInfo)
            
            self.currentComparisonIndex = 0
            self.myRanks.append(self.thisRank)
            self.thisRankIndexPathRow = self.myRanks.count - 1
            
            self.loadPlaceHolders(subsetSize: self.numSubsets)
            self.createObjectHolders(subsetSize: self.numSubsets)
            self.loadLowerButtons()
            self.loadComparisonLabel()
            self.setupRanks()
            
            return bool
        }, errorHandler: { error in
            EVLog("<--- ERROR query Message")
        })
    }
    
    @objc func nextBatch(_ sender: UIButton!) {
        flipVC(firstView: self.view, secondView: self.view)
        prepareNextComparison()
    }
    
    
    @objc func reset(_ sender: UIButton!) {
        for (index, object) in objectHolders.enumerated() {
            object.center = ranks[index+numSubsets].center
        }
        
        for i in 0...(numSubsets-1) { //reset the array
            spotOccupiedInMiniRank[i] = false
        }
        for j in numSubsets...(numSubsets*2-1) {
            spotOccupiedInMiniRank[j] = true
        }
    }
    
    func createObjectHolders(subsetSize: Int) {
        DispatchQueue.main.async {
            let x = self.view.frame.width/5*3
            let yint = self.view.frame.height/7
            var spacer:CGFloat = 0
            let width = self.view.frame.width/4
            let height = width
            
            if self.type == "Non-Image" {
                for i in 0...(subsetSize-1) { // permanent object holders, only text will change
                    self.objectHolders.append(UILabel(frame: CGRect(x: x, y: yint + spacer, width: width, height: height)))
                    self.objectHolders[i].layer.borderColor = UIColor.black.cgColor
                    self.objectHolders[i].layer.borderWidth = 1
                    self.objectHolders[i].backgroundColor = UIColor.lightGray
                    self.objectHolders[i].textColor = UIColor.white
                    self.objectHolders[i].textAlignment = .center
                    self.objectHolders[i].adjustsFontSizeToFitWidth = true
                    self.objectHolders[i].numberOfLines = 0
                    self.objectHolders[i].minimumScaleFactor = 0.3
                    spacer = spacer + yint + self.view.frame.height/25
                    self.view.addSubview(self.objectHolders[i])
                    
                    let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.dragged(_:)))
                    self.objectHolders[i].addGestureRecognizer(gesture)
                    self.objectHolders[i].isUserInteractionEnabled = true
                }
            }
            else if self.type == "Image" {
                for i in 0...(subsetSize-1) { // permanent object holders, only image will change
                    self.imageHolders.append(UIImageView(frame: CGRect(x: x, y: yint + spacer, width: width, height: height)))
                    self.imageHolders[i].layer.borderColor = UIColor.black.cgColor
                    self.imageHolders[i].layer.borderWidth = 1
                    self.imageHolders[i].backgroundColor = UIColor.lightGray
                    self.imageHolders[i].contentMode = .scaleAspectFill
                    self.imageHolders[i].clipsToBounds = true
                    spacer = spacer + yint + self.view.frame.height/25
                    self.view.addSubview(self.imageHolders[i])
                    
                    let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.dragged(_:)))
                    self.imageHolders[i].addGestureRecognizer(gesture)
                    self.imageHolders[i].isUserInteractionEnabled = true
                    
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped))
                    self.imageHolders[i].addGestureRecognizer(tapGesture)
                }
            }
        }
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        selectedImage = (sender.view as! UIImageView).image!
        self.performSegue(withIdentifier: "showBigImage", sender: self)
    }
    
    func createFirstComparison(textArray: [String], imageArray: [UIImage], subsetSize: Int) {
        //reset position and add text to object holders
        
        if !imageArray.isEmpty { // image case
            for (index, object) in imageHolders.enumerated() {
                object.center = ranks[index+subsetSize].center
                object.image = imageArray[index]
                countIndex = countIndex + 1
            }
        }
        else if imageArray.isEmpty { // object case
            for (index, object) in objectHolders.enumerated() {
                object.center = ranks[index+subsetSize].center
                object.text = textArray[index]
                object.font = UIFont(name: "Avenir", size: 16)
                countIndex = countIndex + 1
            }
        }
    }

    
    func createNextComparison(textArray: [String], imageArray: [UIImage], numNewObjects: Int) {
        
        //reset position and add text to object holders
        if imageArray.count > 0 { // image case
            DispatchQueue.main.async {
                for (index, object) in self.imageHolders.enumerated() {
                    object.center = self.ranks[index+self.numSubsets].center
                    object.image = imageArray[index]
                }
            }
            
        }
        else if imageArray.isEmpty { // object case
            for (index, object) in objectHolders.enumerated() {
                object.center = ranks[index+numSubsets].center
                object.text = textArray[index]
                object.font = UIFont(name: "Avenir", size: 16)
            }
        }
        
        for i in 0...(numSubsets-1) { //reset the array
            spotOccupiedInMiniRank[i] = false
        }
        for j in numSubsets...(numSubsets*2-1) {
            spotOccupiedInMiniRank[j] = true
        }
        
        countIndex = countIndex + numNewObjects //
    }
    
    @objc func dragged(_ gesture: UIPanGestureRecognizer) {
        let label = gesture.view!
        
        switch gesture.state {
        case .began:
            initialLocation = gesture.view?.center
        case .changed:
            let translation = gesture.translation(in: self.view)
            label.center = CGPoint(x: label.center.x + translation.x, y: label.center.y + translation.y)
            gesture.setTranslation(CGPoint.zero, in: self.view)
        case .ended:
            let index = calcDistance(center: label.center, labels: ranks)
            if index == 99 || spotOccupiedInMiniRank[index] { // not enough movement or spot is occupied
                label.center = initialLocation
            }
            else {
                label.center = ranks[index].center
                // index < numSubsets means a rank has occured; index > numSubsets returns object to start location on right
                if index < numSubsets {
                    if type == "Image" {
                        miniRankImageResults[index] = (gesture.view as! UIImageView).image! //enter the image into the minirankresult array
                    }
                    else if type == "Non-Image" {
                        miniRankResults[index] = (gesture.view as! UILabel).text! //enter the rank into the minirankresult array
                    }
                }
                spotOccupiedInMiniRank[index] = true
                for i in 0...(numSubsets*2-1) {
                    if initialLocation == ranks[i].center {
                        spotOccupiedInMiniRank[i] = false // origin of object is now empty
                        if i < numSubsets {
                            miniRankResults[i] = "" //reset the index to nil
                            miniRankImageResults[i] = UIImage()
                        }
                    }
                }
            }
            print(miniRankResults)
            print(miniRankImageResults)
        default: ()
        }
        
    }
    
    func calcDistance(center: CGPoint, labels: [UILabel]) -> Int { // calculate distance between object and ranking placeholder
        for (index, label) in labels.enumerated() {
            let dx = abs(center.x - label.frame.midX)
            let dy = abs(center.y - label.frame.midY)
            if dx <= label.frame.width/4*3 && dy <= label.frame.height/4*3 {
                return index
            }
        }
        return 99
    
    }
    
    func loadPlaceHolders(subsetSize: Int) {
        DispatchQueue.main.async {
            let x = self.view.frame.width/8
            let xRight = self.view.frame.width/5*3
            let yint = self.view.frame.height/7
            var spacer:CGFloat = 0
            var spacer2:CGFloat = 0
            let width = self.view.frame.width/4
            let height = width
            
            for i in 0...(subsetSize-1) { // left place holders
                self.ranks.append(UILabel(frame: CGRect(x: x, y: yint + spacer, width: width, height: height)))
                self.addBorder(label: self.ranks[i])
                spacer = spacer + yint + self.view.frame.height/25
                self.view.addSubview(self.ranks[i])
                
                let number = UILabel()
                number.text = self.miniranks[i]
                number.font = UIFont(name: "Pacifico-Regular", size: 24)
                number.sizeToFit()
                number.center.y = self.ranks[i].center.y
                number.frame.origin = CGPoint(x: self.ranks[i].frame.minX - number.frame.width - 8, y: number.frame.minY)
                self.view.addSubview(number)
            }
            
            for i in subsetSize...(subsetSize*2-1) { // object place holders on right
                self.ranks.append(UILabel(frame: CGRect(x: xRight, y: yint + spacer2, width: width, height: height)))
                self.addBorder(label: self.ranks[i])
                spacer2 = spacer2 + yint + self.view.frame.height/25
                self.view.addSubview(self.ranks[i])
            }
        }
        
        
    }
    
    func addBorder(label: UILabel) {
        let border = CAShapeLayer();
        border.strokeColor = UIColor.black.cgColor;
        border.fillColor = nil;
        border.lineDashPattern = [4, 4];
        border.path = UIBezierPath(rect: label.bounds).cgPath
        border.frame = label.bounds;
        label.layer.addSublayer(border)
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.font = UIFont(name: "Pacifico-Regular", size: 24)
    }
    
    func prepareNextComparison() {
        print(countIndex)
        switch (numSubsets, type) {
        case (2, "Non-Image"):
            let numObjectsRankedInFinal = finalRankArray.count
            if miniRankResults.contains(where: {$0.isEmpty}) {
                alert(message: "", title: "Please rank the current objects before proceeding to the next set of objects")
                shake(object: self.nextButton)
            }
            if numObj == 2 {
                finalRankArray = miniRankResults
                finishedComparing()
            }
            else if numTotalComparisons == 0 {
                finalRankArray = miniRankResults
                if numObj == 2 {
                    finishedComparing()
                }
                else {
                    createNextComparison(textArray: [finalRankArray[0],shuffledArray[countIndex]], imageArray: imageSets, numNewObjects: 1)
                    remainingIndices = [1]
                    
                    numTotalComparisons = numTotalComparisons + 1
                    miniRankResults = resetMiniRankResultsArray // reset mini rank resets
                    currentComparisonIndex = 0 // this is the index of the object being compared to the new object
                }
            }
            else if numTotalComparisons != 0 {
                if miniRankResults[0] == shuffledArray[countIndex-1] { //new object is #1 in current comparison;
                    if remainingIndices.isEmpty || (currentComparisonIndex < remainingIndices.min()!) { // this means we're done comparing this object
                        finalRankArray.insert(miniRankResults[0], at: currentComparisonIndex)
                        
                        // Prepare new rank
                        remainingIndices = Array(0..<finalRankArray.count)
                        
                        if (numObjectsRankedInFinal % 2 == 0) {
                            currentComparisonIndex = numObjectsRankedInFinal/2 // odd # ranked now; this is index of next object being compard with new object
                        }
                        else if (numObjectsRankedInFinal % 2 == 1) {
                            let upper = finalRankArray.count/2
                            let lower = (finalRankArray.count/2)-1
                            currentComparisonIndex = lower + Int(arc4random_uniform(UInt32(upper - lower))) //random index surrounding #objects/2
                        }
                        
                        if finalRankArray.count == numObj {
                            finishedComparing()
                        }
                        else {
                            createNextComparison(textArray: [finalRankArray[currentComparisonIndex], shuffledArray[countIndex]], imageArray: imageSets, numNewObjects: 1) //  compare with middle seed
                        }
                        
                        if let nix = remainingIndices.index(of: currentComparisonIndex) { // remove this index from possible remaining indices
                            remainingIndices.remove(at: nix)
                        }
                        numTotalComparisons = numTotalComparisons + 1
                        miniRankResults = resetMiniRankResultsArray // reset mini rank resets
                    }
                    else { // not done comparing here
                        remainingIndices = remainingIndices.filter{ $0 < currentComparisonIndex }
                        
                        
                        if remainingIndices.count == 1 {
                            currentComparisonIndex = remainingIndices[0] // choose remaining middle index
                        }
                        else if remainingIndices.count % 2 == 0 {
                            let upper = remainingIndices.count/2
                            let lower = (remainingIndices.count/2)-1
                            currentComparisonIndex = remainingIndices[lower + Int(arc4random_uniform(UInt32(upper - lower)))] //random index surrounding n/2
                        }
                        else if remainingIndices.count % 2 == 1 {
                            currentComparisonIndex = remainingIndices[(remainingIndices.count-1)/2] // choose remaining middle index
                        }
                        
                        if let nix = remainingIndices.index(of: currentComparisonIndex) { // remove this index from possible remaining indices
                            remainingIndices.remove(at: nix)
                        }
                        createNextComparison(textArray: [finalRankArray[currentComparisonIndex], shuffledArray[countIndex-1]], imageArray: imageSets, numNewObjects: 0)
                        numTotalComparisons = numTotalComparisons + 1
                        miniRankResults = resetMiniRankResultsArray // reset mini rank resets
                    }
                }
                else if miniRankResults[1] == shuffledArray[countIndex-1] { //new object is #2 in current comparison;
                    if remainingIndices.isEmpty || (currentComparisonIndex > remainingIndices.max()!) { // this means we're done comparing this object
                        finalRankArray.insert(miniRankResults[1], at: currentComparisonIndex+1)
                        
                        // Prepare new rank
                        remainingIndices = Array(0..<finalRankArray.count)
                        
                        if (numObjectsRankedInFinal % 2 == 0) {
                            currentComparisonIndex = numObjectsRankedInFinal/2 // odd # ranked now; this is index of next object being compard with new object
                        }
                        else if (numObjectsRankedInFinal % 2 == 1) {
                            let upper = finalRankArray.count/2
                            let lower = (finalRankArray.count/2)-1
                            currentComparisonIndex = lower + Int(arc4random_uniform(UInt32(upper - lower))) //random index surrounding #objects/2
                        }
                        
                        if finalRankArray.count == numObj {
                            finishedComparing()
                        }
                        else {
                            createNextComparison(textArray: [finalRankArray[currentComparisonIndex], shuffledArray[countIndex]], imageArray: imageSets, numNewObjects: 1) //  compare with middle seed
                        }
                        
                        if let nix = remainingIndices.index(of: currentComparisonIndex) { // remove this index from possible remaining indices
                            remainingIndices.remove(at: nix)
                        }
                        numTotalComparisons = numTotalComparisons + 1
                        miniRankResults = resetMiniRankResultsArray // reset mini rank resets
                    }
                    else { // not done comparing here
                        remainingIndices = remainingIndices.filter{ $0 > currentComparisonIndex }
                        print(remainingIndices)
                        
                        if remainingIndices.count == 1 {
                            currentComparisonIndex = remainingIndices[0] // choose remaining middle index
                        }
                        else if remainingIndices.count % 2 == 0 {
                            let upper = remainingIndices.count/2
                            let lower = (remainingIndices.count/2)-1
                            currentComparisonIndex = remainingIndices[lower + Int(arc4random_uniform(UInt32(upper - lower)))] //random index surrounding n/2
                        }
                        else if remainingIndices.count % 2 == 1 {
                            currentComparisonIndex = remainingIndices[(remainingIndices.count-1)/2] // choose remaining middle index
                        }
                        
                        if let nix = remainingIndices.index(of: currentComparisonIndex) { // remove this index from possible remaining indices
                            remainingIndices.remove(at: nix)
                        }
                        createNextComparison(textArray: [finalRankArray[currentComparisonIndex], shuffledArray[countIndex-1]], imageArray: imageSets, numNewObjects: 0)
                        numTotalComparisons = numTotalComparisons + 1
                        miniRankResults = resetMiniRankResultsArray // reset mini rank resets
                    }
                }
            }
            
            comparisonLabel.text = "Comparisons made: \(numTotalComparisons)"
            
        case (2, "Image"): // algorithm: check if current comparison is done, incorporate this data, initiate next comparison
            let numObjectsRankedInFinal = finalRankImageArray.count
            if compareImage(image: UIImage(), imageArray: miniRankImageResults) >= 0 {
                alert(message: "", title: "Please rank the current images before proceeding to the next set of images")
                shake(object: self.nextButton)
                return
            }
            if numObj == 2 {
                finalRankImageArray = miniRankImageResults
                finishedComparing()
            }
            else if numTotalComparisons == 0 {
                finalRankImageArray = miniRankImageResults
                if numObj == 2 {
                    finishedComparing()
                }
                createNextComparison(textArray: textArray, imageArray: [finalRankImageArray[0],shuffledImageSet[countIndex]], numNewObjects: 1)
                remainingIndices = [1]
                
                numTotalComparisons = numTotalComparisons + 1
                miniRankImageResults = resetMiniRankImageResultsArray // reset mini rank resets
                currentComparisonIndex = 0 // this is the index of the object being compared to the new object
            }
            else if numTotalComparisons != 0 {
                if miniRankImageResults[0] == shuffledImageSet[countIndex-1] { //new object is #1 in current comparison;
                    if remainingIndices.isEmpty || (currentComparisonIndex < remainingIndices.min()!) { // this means we're done comparing this object
                        finalRankImageArray.insert(miniRankImageResults[0], at: currentComparisonIndex)
                        
                        // Prepare new rank
                        remainingIndices = Array(0..<finalRankImageArray.count)
                        
                        if (numObjectsRankedInFinal % 2 == 0) {
                            currentComparisonIndex = numObjectsRankedInFinal/2 // odd # ranked now; this is index of next object being compard with new object
                        }
                        else if (numObjectsRankedInFinal % 2 == 1) {
                            let upper = finalRankImageArray.count/2
                            let lower = (finalRankImageArray.count/2)-1
                            currentComparisonIndex = lower + Int(arc4random_uniform(UInt32(upper - lower))) //random index surrounding #objects/2
                        }
                        
                        if finalRankImageArray.count == numObj {
                            finishedComparing()
                        }
                        else {
                            createNextComparison(textArray: textArray, imageArray: [finalRankImageArray[currentComparisonIndex],shuffledImageSet[countIndex]], numNewObjects: 1) //  compare with middle seed
                        }
                        
                        if let nix = remainingIndices.index(of: currentComparisonIndex) { // remove this index from possible remaining indices
                            remainingIndices.remove(at: nix)
                        }
                        numTotalComparisons = numTotalComparisons + 1
                        miniRankImageResults = resetMiniRankImageResultsArray // reset mini rank resets
                    }
                    else { // not done comparing here
                        remainingIndices = remainingIndices.filter{ $0 < currentComparisonIndex }
                        
                        if remainingIndices.count == 1 {
                            currentComparisonIndex = remainingIndices[0] // choose remaining middle index
                        }
                        else if remainingIndices.count % 2 == 0 {
                            let upper = remainingIndices.count/2
                            let lower = (remainingIndices.count/2)-1
                            currentComparisonIndex = remainingIndices[lower + Int(arc4random_uniform(UInt32(upper - lower)))] //random index surrounding n/2
                        }
                        else if remainingIndices.count % 2 == 1 {
                            currentComparisonIndex = remainingIndices[(remainingIndices.count-1)/2] // choose remaining middle index
                        }
                        
                        if let nix = remainingIndices.index(of: currentComparisonIndex) { // remove this index from possible remaining indices
                            remainingIndices.remove(at: nix)
                        }
                        createNextComparison(textArray: textArray, imageArray: [finalRankImageArray[currentComparisonIndex],shuffledImageSet[countIndex-1]], numNewObjects: 0)
                        numTotalComparisons = numTotalComparisons + 1
                        miniRankImageResults = resetMiniRankImageResultsArray // reset mini rank resets
                    }
                }
                else if miniRankImageResults[1] == shuffledImageSet[countIndex-1] { //new object is #2 in current comparison;
                    if remainingIndices.isEmpty || (currentComparisonIndex > remainingIndices.max()!) { // this means we're done comparing this object
                        finalRankImageArray.insert(miniRankImageResults[1], at: currentComparisonIndex+1)
                        
                        // Prepare new rank
                        remainingIndices = Array(0..<finalRankImageArray.count)
                        
                        if (numObjectsRankedInFinal % 2 == 0) {
                            currentComparisonIndex = numObjectsRankedInFinal/2 // odd # ranked now; this is index of next object being compard with new object
                        }
                        else if (numObjectsRankedInFinal % 2 == 1) {
                            let upper = finalRankImageArray.count/2
                            let lower = (finalRankImageArray.count/2)-1
                            currentComparisonIndex = lower + Int(arc4random_uniform(UInt32(upper - lower))) //random index surrounding #objects/2
                        }
                        
                        if finalRankImageArray.count == numObj {
                            finishedComparing()
                        }
                        else {
                            createNextComparison(textArray: textArray, imageArray: [finalRankImageArray[currentComparisonIndex],shuffledImageSet[countIndex]], numNewObjects: 1) //  compare with middle seed
                        }
                        
                        if let nix = remainingIndices.index(of: currentComparisonIndex) { // remove this index from possible remaining indices
                            remainingIndices.remove(at: nix)
                        }
                        numTotalComparisons = numTotalComparisons + 1
                        miniRankImageResults = resetMiniRankImageResultsArray // reset mini rank resets
                    }
                    else { // not done comparing here
                        remainingIndices = remainingIndices.filter{ $0 > currentComparisonIndex }
                        print(remainingIndices)
                        
                        if remainingIndices.count == 1 {
                            currentComparisonIndex = remainingIndices[0] // choose remaining middle index
                        }
                        else if remainingIndices.count % 2 == 0 {
                            let upper = remainingIndices.count/2
                            let lower = (remainingIndices.count/2)-1
                            currentComparisonIndex = remainingIndices[lower + Int(arc4random_uniform(UInt32(upper - lower)))] //random index surrounding n/2
                        }
                        else if remainingIndices.count % 2 == 1 {
                            currentComparisonIndex = remainingIndices[(remainingIndices.count-1)/2] // choose remaining middle index
                        }
                        
                        if let nix = remainingIndices.index(of: currentComparisonIndex) { // remove this index from possible remaining indices
                            remainingIndices.remove(at: nix)
                        }
                        createNextComparison(textArray: textArray, imageArray: [finalRankImageArray[currentComparisonIndex],shuffledImageSet[countIndex-1]], numNewObjects: 0)
                        numTotalComparisons = numTotalComparisons + 1
                        miniRankImageResults = resetMiniRankImageResultsArray // reset mini rank resets
                    }
                }
            }
            
            comparisonLabel.text = "Comparisons made: \(numTotalComparisons)"
            
        case (3, "Non-Image"):
            if miniRankResults.contains(where: {$0.isEmpty}) {
                alert(message: "", title: "Please rank the current objects before proceeding to the next set of objects")
                shake(object: self.nextButton)
            }
            else {
                let rank1Index = textArray.index(of: miniRankResults[0]) //#1
                let rank2Index = textArray.index(of: miniRankResults[1]) //#2
                let rank3Index = textArray.index(of: miniRankResults[2]) //#3
                arrayOfValues[rank2Index!] = (arrayOfValues[rank2Index!] > (arrayOfValues[rank3Index!] + 1)) ? arrayOfValues[rank2Index!] : (arrayOfValues[rank3Index!] + 1)
                arrayOfValues[rank1Index!] = (arrayOfValues[rank1Index!] > (arrayOfValues[rank2Index!] + 1)) ? arrayOfValues[rank1Index!] : (arrayOfValues[rank2Index!] + 1)
                
                // final array is the textarray sorted by array of values
                let count = arrayOfValues.count
                let sortedTuples = (0..<count).map { (arrayOfValues[$0], textArray[$0]) }.sorted { $0.0 > $1.0 }
                
                let sortedArrayValues = sortedTuples.map { $0.0 }
                finalRankArray = sortedTuples.map { $0.1 }
                
                var counts: [Int: Int] = [:]
                sortedArrayValues.forEach { counts[$0, default: 0] += 1 } // get frequency of values to break up ties
                
                (nextGroup, nextImageGroup, done) = minimizeDifference(tempTextArray: textArray, tempImageArray: imageSets, tempArrayOfValues: arrayOfValues)
                if done {
                    finishedComparing()
                }
                else {
                    createNextComparison(textArray: nextGroup, imageArray: nextImageGroup, numNewObjects: 0) // next comparison
                }
                
                miniRankResults = resetMiniRankResultsArray // reset mini results
                numTotalComparisons = numTotalComparisons + 1
                
                comparisonLabel.text = "Comparisons made: \(numTotalComparisons)"
            }
        case (3, "Image"):
            if compareImage(image: UIImage(), imageArray: miniRankImageResults) >= 0 {
                alert(message: "", title: "Please rank the current images before proceeding to the next set of images")
                shake(object: self.nextButton)
            }
            else {
                let rank1Index = compareImage(image: miniRankImageResults[0], imageArray: resizeImageSets) //#1
                let rank2Index = compareImage(image: miniRankImageResults[1], imageArray: resizeImageSets) //#2
                let rank3Index = compareImage(image: miniRankImageResults[2], imageArray: resizeImageSets) //#3
                arrayOfValues[rank2Index] = (arrayOfValues[rank2Index] > (arrayOfValues[rank3Index] + 1)) ? arrayOfValues[rank2Index] : (arrayOfValues[rank3Index] + 1)
                arrayOfValues[rank1Index] = (arrayOfValues[rank1Index] > (arrayOfValues[rank2Index] + 1)) ? arrayOfValues[rank1Index] : (arrayOfValues[rank2Index] + 1)
                
                // final array is the textarray sorted by array of values
                let count = arrayOfValues.count
                let sortedTuples = (0..<count).map { (arrayOfValues[$0], resizeImageSets[$0]) }.sorted { $0.0 > $1.0 }
                
                let sortedArrayValues = sortedTuples.map { $0.0 }
                finalRankImageArray = sortedTuples.map { $0.1 }
                
                var counts: [Int: Int] = [:]
                sortedArrayValues.forEach { counts[$0, default: 0] += 1 } // get frequency of values to break up ties
                
                (nextGroup, nextImageGroup, done) = minimizeDifference(tempTextArray: textArray, tempImageArray: resizeImageSets, tempArrayOfValues: arrayOfValues)
                if done {
                    let myAlert = UIAlertController(title: "Done!", message: "", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Show me the final results", style: UIAlertActionStyle.default) { (ACTION) in
                        let tempSortedTuples = (0..<count).map { (self.arrayOfValues[$0], self.imageSets[$0]) }.sorted { $0.0 > $1.0 }
                        
                        self.finalRankImageArrayFullSize = tempSortedTuples.map { $0.1 }
                        
                        for image in self.finalRankImageArrayFullSize {
                            self.thisRank.finalRankFullSizeImageArrayData.append(UIImageJPEGRepresentation(image, 1)!)
                        }
                        
                        self.performSegue(withIdentifier: "toRankingResults", sender: self)
                    }
                    myAlert.addAction(okAction)
                    
                    if let popoverController = myAlert.popoverPresentationController {
                        popoverController.sourceView = self.view
                    }
                    self.present(myAlert, animated: true, completion: nil)
                }
                else {
                    createNextComparison(textArray: nextGroup, imageArray: nextImageGroup, numNewObjects: 0) // next comparison
                }
                
                miniRankImageResults = resetMiniRankImageResultsArray // reset mini results
                numTotalComparisons = numTotalComparisons + 1
                
                comparisonLabel.text = "Comparisons made: \(numTotalComparisons)"
            }
        case (4, "Non-Image"):
            if miniRankResults.contains(where: {$0.isEmpty}) {
                alert(message: "", title: "Please rank the current objects before proceeding to the next set of objects")
                shake(object: self.nextButton)
            }
            else {
                let rank1Index = textArray.index(of: miniRankResults[0]) //#1
                let rank2Index = textArray.index(of: miniRankResults[1]) //#2
                let rank3Index = textArray.index(of: miniRankResults[2]) //#3
                let rank4Index = textArray.index(of: miniRankResults[3]) //#3
                arrayOfValues[rank3Index!] = (arrayOfValues[rank3Index!] > (arrayOfValues[rank4Index!] + 1)) ? arrayOfValues[rank3Index!] : (arrayOfValues[rank4Index!] + 1)
                arrayOfValues[rank2Index!] = (arrayOfValues[rank2Index!] > (arrayOfValues[rank3Index!] + 1)) ? arrayOfValues[rank2Index!] : (arrayOfValues[rank3Index!] + 1)
                arrayOfValues[rank1Index!] = (arrayOfValues[rank1Index!] > (arrayOfValues[rank2Index!] + 1)) ? arrayOfValues[rank1Index!] : (arrayOfValues[rank2Index!] + 1)
                
                // final array is the textarray sorted by array of values
                let count = arrayOfValues.count
                let sortedTuples = (0..<count).map { (arrayOfValues[$0], textArray[$0]) }.sorted { $0.0 > $1.0 }
                
                let sortedArrayValues = sortedTuples.map { $0.0 }
                finalRankArray = sortedTuples.map { $0.1 }
                
                var counts: [Int: Int] = [:]
                sortedArrayValues.forEach { counts[$0, default: 0] += 1 } // get frequency of values to break up ties
                
                (nextGroup, nextImageGroup, done) = minimizeDifference(tempTextArray: textArray, tempImageArray: imageSets, tempArrayOfValues: arrayOfValues)
                if done {
                    finishedComparing()
                }
                else {
                    createNextComparison(textArray: nextGroup, imageArray: nextImageGroup, numNewObjects: 0) // next comparison
                }
                
                miniRankResults = resetMiniRankResultsArray // reset mini results
                numTotalComparisons = numTotalComparisons + 1
                
                comparisonLabel.text = "Comparisons made: \(numTotalComparisons)"
            }
        case (4, "Image"):
            if compareImage(image: UIImage(), imageArray: miniRankImageResults) >= 0 {
                alert(message: "", title: "Please rank the current images before proceeding to the next set of images")
                shake(object: self.nextButton)
            }
            else {
                let rank1Index = compareImage(image: miniRankImageResults[0], imageArray: resizeImageSets) //#1
                let rank2Index = compareImage(image: miniRankImageResults[1], imageArray: resizeImageSets) //#2
                let rank3Index = compareImage(image: miniRankImageResults[2], imageArray: resizeImageSets) //#3
                let rank4Index = compareImage(image: miniRankImageResults[3], imageArray: resizeImageSets) //#4
                arrayOfValues[rank3Index] = (arrayOfValues[rank3Index] > (arrayOfValues[rank4Index] + 1)) ? arrayOfValues[rank3Index] : (arrayOfValues[rank4Index] + 1)
                arrayOfValues[rank2Index] = (arrayOfValues[rank2Index] > (arrayOfValues[rank3Index] + 1)) ? arrayOfValues[rank2Index] : (arrayOfValues[rank3Index] + 1)
                arrayOfValues[rank1Index] = (arrayOfValues[rank1Index] > (arrayOfValues[rank2Index] + 1)) ? arrayOfValues[rank1Index] : (arrayOfValues[rank2Index] + 1)
                
                // final array is the textarray sorted by array of values
                let count = arrayOfValues.count
                let sortedTuples = (0..<count).map { (arrayOfValues[$0], resizeImageSets[$0]) }.sorted { $0.0 > $1.0 }
                
                let sortedArrayValues = sortedTuples.map { $0.0 }
                finalRankImageArray = sortedTuples.map { $0.1 }
                
                var counts: [Int: Int] = [:]
                sortedArrayValues.forEach { counts[$0, default: 0] += 1 } // get frequency of values to break up ties
                
                (nextGroup, nextImageGroup, done) = minimizeDifference(tempTextArray: textArray, tempImageArray: resizeImageSets, tempArrayOfValues: arrayOfValues)
                if done {
                    let myAlert = UIAlertController(title: "Done!", message: "", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Show me the final results", style: UIAlertActionStyle.default) { (ACTION) in
                        let tempSortedTuples = (0..<count).map { (self.arrayOfValues[$0], self.imageSets[$0]) }.sorted { $0.0 > $1.0 }
                        
                        self.finalRankImageArrayFullSize = tempSortedTuples.map { $0.1 }
                        
                        for image in self.finalRankImageArrayFullSize {
                            self.thisRank.finalRankFullSizeImageArrayData.append(UIImageJPEGRepresentation(image, 1)!)
                        }
                        
                        self.performSegue(withIdentifier: "toRankingResults", sender: self)
                    }
                    myAlert.addAction(okAction)
                    
                    if let popoverController = myAlert.popoverPresentationController {
                        popoverController.sourceView = self.view
                    }
                    self.present(myAlert, animated: true, completion: nil)
                }
                else {
                    createNextComparison(textArray: nextGroup, imageArray: nextImageGroup, numNewObjects: 0) // next comparison
                }
                
                miniRankImageResults = resetMiniRankImageResultsArray // reset mini results
                numTotalComparisons = numTotalComparisons + 1
                
                comparisonLabel.text = "Comparisons made: \(numTotalComparisons)"
            }
        default: ()
        }
    }
    
    func minimizeDifference(tempTextArray: [String], tempImageArray: [UIImage], tempArrayOfValues: [Int]) -> ([String], [UIImage], Bool) {
        var nextGroup:[String] = []
        var nextImageGroup:[UIImage] = []
        if (tempArrayOfValues.unique() == tempArrayOfValues) { //|| numTotalComparisons > numObj*5/numSubsets { // if each item has it's own unique value OR we've done XX comparisons, end it
            return (nextGroup, nextImageGroup, true)
        }
        
        let groupings = Combinatorics.combinationsWithoutRepetitionFrom(arrayOfValues, taking: numSubsets)
        var deltaValue:[Int] = []
        for (_,group) in groupings.enumerated() {
            switch (numSubsets) {
            case 2:
                let deltaA = abs(group[0]-group[1])
                deltaValue.append(deltaA)
            case 3:
                let deltaA = abs(group[0]-group[1])
                let deltaB = abs(group[1]-group[2])
                let deltaC = abs(group[0]-group[2])
                deltaValue.append(deltaA + deltaB + deltaC)
            case 4:
                let permute = Combinatorics.permutationsWithoutRepetitionFrom(group, taking: 2)
                var delta = 0
                for combo in permute {
                    delta = delta + abs(combo[0] - combo[1])
                }
                deltaValue.append(delta)
            default: ()
            }
        }
        
        let count = deltaValue.count
        let sortedTuples = (0..<count).map { (deltaValue[$0], groupings[$0]) }.sorted { $0.0 < $1.0 }
        
        let sortedDeltaValue = sortedTuples.map { $0.0 }
        let sortedGroupings = sortedTuples.map { $0.1 }
        
        var dummy = 0
        var i = 0
        while dummy <= 0 {
            dummy = 1
            var tempTextArray2 = tempTextArray
            var tempImageArray2 = tempImageArray
            var tempArrayOfValues2 = tempArrayOfValues
            nextGroup = []
            nextImageGroup = []
            
            let minimumValueGroup = sortedGroupings[i]
            for (_, value) in minimumValueGroup.enumerated() {
                if type == "Non-Image" {
                    let arrayIndex = tempArrayOfValues2.index(of: value) // randomly choose an object that has one of the min values; array values are aligned with textArray
                    nextGroup.append(tempTextArray2[arrayIndex!])
                    
                    tempTextArray2.remove(at: arrayIndex!) // remove this obj so we don't choose again
                    tempArrayOfValues2.remove(at: arrayIndex!)
                }
                else if type == "Image" {
                    let arrayIndex = tempArrayOfValues2.index(of: value)
                    nextImageGroup.append(tempImageArray2[arrayIndex!])
                    
                    tempImageArray2.remove(at: arrayIndex!) // remove this obj so we don't choose again
                    tempArrayOfValues2.remove(at: arrayIndex!)
                }
                
            }
        }
        
        print(sortedDeltaValue)
        print("next Group: \(nextGroup) img grp: \(nextImageGroup)")
        return (nextGroup, nextImageGroup, false)

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }
    }
    
    func loadLowerButtons() {
        DispatchQueue.main.async {
            let width = self.view.frame.width/10*3
            let height = self.view.frame.height/12
            let spacer: CGFloat = 15
            
            self.resetButton = UIButton(type: .system)
            self.resetButton.frame = CGRect(x: self.view.frame.width/40*1, y: self.view.frame.height - height - spacer, width: width, height: height)
            self.editButton(button: self.resetButton, text: "Reset Comparison", font: 16)
            self.resetButton.titleLabel?.numberOfLines = 2
            self.resetButton.addTarget(self, action: #selector(self.reset), for: .touchUpInside)
            
            self.currentStandingsButton = UIButton(type: .system)
            self.currentStandingsButton.frame = CGRect(x: self.view.frame.width/40*14, y: self.view.frame.height - height - spacer, width: width, height: height)
            self.editButton(button: self.currentStandingsButton, text: "Current Standings", font: 16)
            self.currentStandingsButton.addTarget(self, action: #selector(self.getCurrentStandings), for: .touchUpInside)
            self.currentStandingsButton.titleLabel?.numberOfLines = 2
            self.currentStandingsButton.backgroundColor = .red
            
            self.nextButton = UIButton(type: .system)
            self.nextButton.frame = CGRect(x: self.view.frame.width/40*27, y: self.view.frame.height - height - spacer, width: width, height: height)
            self.editButton(button: self.nextButton, text: "Next Comparison", font: 16)
            self.nextButton.titleLabel?.numberOfLines = 2
            self.nextButton.addTarget(self, action: #selector(self.nextBatch), for: .touchUpInside)
        }
        
    }
    
    func loadComparisonLabel() {
        DispatchQueue.main.async {
            let xint:CGFloat = 0
            let yint = self.navigationController!.navigationBar.frame.maxY
            let width = self.view.frame.width
            let height = self.ranks[0].frame.minY - self.navigationController!.navigationBar.frame.maxY
            
            self.comparisonLabel = UILabel(frame: CGRect(x: xint, y: yint, width: width, height: height))
            self.editLabel(label: self.comparisonLabel, text: "Comparisons made: \(self.numTotalComparisons)")
        }
        
    }
    
    @objc func getCurrentStandings(_ button: UIButton!) {
        if !finalRankArray.isEmpty || !finalRankImageArray.isEmpty {
            let popoverContent = self.storyboard?.instantiateViewController(withIdentifier: "FinalResultsViewController") as? FinalResultsViewController
            popoverContent?.rankFinished = false
            popoverContent?.finalRankArray = finalRankArray
            popoverContent?.refSet = refSet
            popoverContent?.finalRankImageArray = finalRankImageArray
            popoverContent?.finalRankImageArrayFullSize = finalRankImageArrayFullSize
            popoverContent?.type = type
            //popoverContent?.numTotalComparisons = numTotalComparisons
            
            let nav = UINavigationController(rootViewController: popoverContent!)
            nav.modalPresentationStyle = .popover
            let popover = nav.popoverPresentationController
            popoverContent?.preferredContentSize = CGSize(width: view.frame.width, height: view.frame.height/5*3)
            popover?.permittedArrowDirections = .down
            popover?.delegate = self
            popover?.sourceView = button
            popover?.sourceRect = button.bounds
            popover?.backgroundColor = UIColor.clear
            
            self.present(nav, animated: true, completion: nil)
        }
        else {
            // no ranks made yet
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Force popover style
        return .none
    }
    
    func flipVC(firstView: UIView, secondView: UIView) {
        let transitionOptions: UIViewAnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]
        
        UIView.transition(with: firstView, duration: 0.25, options: transitionOptions, animations: {
        })
        
        UIView.transition(with: secondView, duration: 0.25, options: transitionOptions, animations: {
        })
    }
    
    func finishedComparing() {
        if thisRank.type == "Non-Image" {
            thisRank.finalRankTextArray = finalRankArray
        }
        
        thisRank.rankFinished = true
        
        finalRankImageArrayFullSize = finalRankImageArray // dunno how to get original size images
        
        self.savePressed(nil)
        
        let myAlert = UIAlertController(title: "Done!", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Show me the final results", style: UIAlertActionStyle.default) { (ACTION) in
            self.performSegue(withIdentifier: "toRankingResults", sender: self)
        }
        myAlert.addAction(okAction)
        
        if let popoverController = myAlert.popoverPresentationController {
            popoverController.sourceView = self.view
        }
        self.present(myAlert, animated: true, completion: nil)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nc = segue.destination as? UINavigationController {
            if let destination = nc.topViewController as? MyImageView2VC {
                destination.image = selectedImage
            }
        }
        
        if let destination = segue.destination as? FinalResultsViewController {
            destination.rankName = name
            destination.type = thisRank.type
            destination.numObj = numObj
            destination.numSubsets = numSubsets
            destination.rankFinished = true
            destination.myRanks = myRanks
            destination.thisRank = thisRank
            destination.publicRank = publicRank
            
            if type == "Non-Image" {
                destination.finalRankArray = finalRankArray
            }
            else if type == "Image" {
                destination.finalRankImageArray = finalRankImageArray
                if numSubsets == 2 {
                    finalRankImageArrayFullSize = finalRankImageArray // dunno how to get original size images
                }
                destination.finalRankImageArrayFullSize = finalRankImageArrayFullSize
                destination.refSet = refSet
            }
            
        }
        
        if let nc = segue.destination as? UINavigationController {
            if let destination = nc.topViewController as? ModifyRankingsVC {
                destination.type = thisRank.type
                destination.numObj = numObj
                destination.numSubsets = numSubsets
                destination.rankFinished = false
                destination.thisRank = thisRank
                destination.textArray = textArray
                destination.nextGroup = nextGroup
                destination.nextImageGroupIndices = thisRank.nextImageGroupIndexes
                destination.imageSet = imageSets
                destination.shuffledImageSet = shuffledImageSet
                destination.shuffledTextArray = shuffledArray
                destination.arrayOfValues = arrayOfValues
                destination.currentComparisonIndex = currentComparisonIndex
                destination.countIndex = countIndex
                destination.delegate = self
                
                if type == "Non-Image" {
                    destination.finalRankArray = finalRankArray
                }
                else if type == "Image" {
                    destination.finalRankImageArray = finalRankImageArray
                    if numSubsets == 2 {
                        finalRankImageArrayFullSize = finalRankImageArray // dunno how to get original size images
                    }
                    destination.finalRankImageArrayFullSize = finalRankImageArrayFullSize
                }
            }
        }
    }
    
}


