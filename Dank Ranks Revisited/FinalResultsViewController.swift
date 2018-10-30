//
//  FianlResultsViewController.swift
//  DankRanks
//
//  Created by Jiang, Tony on 12/7/17.
//  Copyright © 2017 Jiang, Tony. All rights reserved.
//

import UIKit
import CloudKit
import EVCloudKitDao
import KRProgressHUD
import StoreKit
import Disk
import LGButton
import SwiftMessages
import NVActivityIndicatorView
import DHSmartScreenshot
import StoreKit
import EasyImagy


class FinalResultsViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, ShareRankPopoverViewControllerDelegate, NVActivityIndicatorViewable {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var shareButtonOutlet: LGButton!
    @IBOutlet weak var homeButtonOutlet: LGButton!
    @IBOutlet weak var compilationButtonOutlet: LGButton!
    @IBOutlet weak var changeRanksOutlet: UIBarButtonItem!
    
    var myRanks: [Rank]!
    var thisRank: Rank!
    var rankFinished: Bool!
    var newRank = true
    var rankResult: UIImage!
    
    var publicRank: Bool!
    var refSet: [(name: String, image: UIImage)]!
    
    let rankInfo = RankInfoss()
    var oldRankInfo: RankInfoss!
    var currentDeviceID: String!
    var usernamesInRank: [String] = []
    var username: String?
    var userIndex: Int? // index of previous user within rank array
    
    var existingProjectNames: [String] = [] // use this to prevent duplicate names
    var queryRunning: Int = 0
    
    var type:String!
    var finalRankArray:[String] = [] // holds final ranking
    var finalRankImageArray:[UIImage] = [] // holds final ranking for images
    var finalRankImageArrayFullSize:[UIImage] = [] // full size images
    
    var rankName: String!
    var numObj: Int!
    var numSubsets: Int!
    
    var shareButton:UIButton!
    var rateButton:UIButton!
    var rankAgainButton:UIButton!
    var finalResultsLabel:UILabel!
    
    var selectedImage: UIImage?
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        self.title = "My Rankings"
        
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 110
        tableView.delegate = self
        tableView.register(UINib(nibName: "ImageCellNib", bundle: nil), forCellReuseIdentifier: "imageCell")
        
        compilationButtonOutlet.isHidden = true
        if !rankFinished {
            shareButtonOutlet.isHidden = true
            homeButtonOutlet.isHidden = true
            let doneItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.donePressed))
            self.navigationItem.rightBarButtonItem = doneItem
        }
        
        if rankFinished {
            DispatchQueue.main.async {
                self.rankResult = self.getResultWithModification()
            }
            self.currentDeviceID = UIDevice.current.identifierForVendor!.uuidString
            
            shareButtonOutlet.isHidden = false
            homeButtonOutlet.isHidden = false
            
            if !defaults.bool(forKey: "premium") {
                if var numberRanks = defaults.object(forKey: "numberRanks") as? Int {
                    if numberRanks == 7 { // every 6 or 7 ranks get asked
                        if #available( iOS 10.3,*) {
                            SKStoreReviewController.requestReview()
                        }
                        numberRanks = 0
                    }
                    numberRanks = numberRanks + 1
                    defaults.set(numberRanks, forKey: "numberRanks")
                }
                else {
                    defaults.set(1, forKey: "numberRanks")
                }
            }
            
            compilationButtonOutlet.isHidden = true
            if publicRank {
                let predicate = NSPredicate(format: "uniqueID == %@", self.thisRank.uniqueID!)
                dao.query(RankInfoss(), predicate: predicate, completionHandler: { (record, bool) in
                    if record.count > 0 {
                        self.oldRankInfo = record[0] // should only be one
                        
                        if self.oldRankInfo.uniqueDeviceID.contains(self.currentDeviceID) { // see if user already sent a rank; see if device ID is contained in array
                            for (index,deviceID) in self.oldRankInfo.uniqueDeviceID.enumerated() {
                                if deviceID == self.currentDeviceID {
                                    self.username = self.oldRankInfo.Username[index]
                                    self.userIndex = index
                                }
                            }
                            self.prepareForCompilation()
                        }
                        else if self.username == nil {
                            let textAlert = UIAlertController(title: "Please enter your username to be associated with this project", message: nil, preferredStyle: .alert)
                            
                            textAlert.addTextField { (tf:UITextField!) in
                                tf.placeholder = "Username"
                                tf.font = UIFont(name: "Helvetica Neue", size: (Env.iPad ? 24 : 16))
                                tf.addTarget(self, action: #selector(self.textChanged), for: .editingChanged)
                            }
                            
                            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
                                print("Cancel Button Pressed")
                            }
                            
                            let okAction = UIAlertAction(title: "OK", style: .default) { action in
                                self.username = textAlert.textFields![0].text!
                                
                                self.prepareForCompilation()
                            }
                            okAction.isEnabled = false
                            
                            textAlert.addAction(cancelAction)
                            textAlert.addAction(okAction)
                            
                            if let popoverController = textAlert.popoverPresentationController {
                                popoverController.sourceView = self.view
                            }
                            self.present(textAlert, animated: true, completion: nil)
                        }
                        
                        
                    }
                    return bool
                })
            }
        }
    }
    
    func getResultWithModification() -> UIImage { // change 1 pixel to avoid authtoken issue?
        var result = Image<RGBA<UInt8>>(uiImage: self.tableView.screenshot()!)
        let random1 = Int(arc4random_uniform(UInt32(255)))
        let random2 = Int(arc4random_uniform(UInt32(255)))
        let random3 = Int(arc4random_uniform(UInt32(255)))
        let random4 = Int(arc4random_uniform(UInt32(127)))
        result[0,0] = RGBA(red: random1, green: random2, blue: random3, alpha: random4)
        return result.uiImage
    }
    
    func prepareForCompilation() {
        DispatchQueue.main.async {
            self.rankResult = self.getResultWithModification()
        }
        
        self.refSet = []
        var assets = [CKAsset]() // rankInfo.imagearray
        var fileNames = [String]() // rankinfo.textarray
        
        DispatchQueue.global(qos: .userInitiated).async {
            if self.oldRankInfo.RankType == "Image" {
                for i in 0..<self.oldRankInfo.NumObj { // use the first set as reference
                    self.refSet.append((self.oldRankInfo.textArray[i], self.oldRankInfo.imageArray[i].image()!))
                }
                let refNames = self.refSet.map {($0.name)}
                let refImages = self.refSet.map {($0.image)}
                
                for finalRankImage in self.finalRankImageArray {
                    var index: Int?
                    for (i, refImage) in refImages.enumerated() {
                        let resizeRefImage = refImage.resizeImage(targetSize: finalRankImage.size)
                        if resizeRefImage.size == finalRankImage.size {
                            if self.compareImage(image: finalRankImage, image2: resizeRefImage) {
                                index = i
                                print(index)
                                //assets.append(self.oldRankInfo.imageArray[i]) //excluded because of authtoken issues with cloudkit? could't repeat ckassets?
                                fileNames.append(refNames[i])
                            }
                        }
                    }
                }
            }
            
            if self.oldRankInfo.uniqueDeviceID.contains(self.currentDeviceID) { // already sent a rank so update old rank
                let beginIndex = self.numObj * self.userIndex!
                let endIndex = self.numObj * (self.userIndex! + 1) - 1
                if self.oldRankInfo.RankType == "Image" {
                    self.oldRankInfo.textArray.replaceSubrange(beginIndex...endIndex, with: fileNames)
                    //self.oldRankInfo.imageArray.replaceSubrange(beginIndex...endIndex, with: assets)
                }
                else {
                    self.oldRankInfo.textArray.replaceSubrange(beginIndex...endIndex, with: self.finalRankArray)
                }
                self.oldRankInfo.result[self.userIndex!] = self.convertToCKAsset(image: self.rankResult)
            }
            else { // user is adding data to an established rank
                self.oldRankInfo.Username.append(self.username!)
                if self.oldRankInfo.RankType == "Image" {
                    self.oldRankInfo.textArray = self.oldRankInfo.textArray + fileNames
                    //self.oldRankInfo.imageArray = self.oldRankInfo.imageArray + assets
                }
                else {
                    self.oldRankInfo.textArray = self.oldRankInfo.textArray + self.finalRankArray
                }
                
                self.oldRankInfo.result.append(self.convertToCKAsset(image: self.rankResult))
                self.oldRankInfo.uniqueDeviceID.append(self.currentDeviceID)
            }
            
            
            dao.saveItem(self.oldRankInfo, completionHandler: { record in
                DispatchQueue.main.async {
                    self.compilationButtonOutlet.isHidden = false
                }
            })
        }
        
    }
    
    @IBAction func changeRanksPressed(_ sender: UIBarButtonItem) {
        if changeRanksOutlet.title == "Change Ranks" {
            tableView.isEditing = true
            changeRanksOutlet.title = "Done"
            changeRanksOutlet.style = .done
            if publicRank {
                self.compilationButtonOutlet.isHidden = true
            }
        }
        else {
            tableView.isEditing = false
            changeRanksOutlet.title = "Change Ranks"
            changeRanksOutlet.style = .plain
            if publicRank {
                self.prepareForCompilation()
            }
        }
    }
    
    
    @IBAction func compilationPressed(_ sender: LGButton) {
        self.performSegue(withIdentifier: "toCompilationFromFinalResults", sender: self)
    }
    
    
    @objc func donePressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func tapImageView(_ gesture: CustomGesture) {
        let indexPath = gesture.indexPath!
        selectedImage = self.finalRankImageArrayFullSize[indexPath.row]
        
        self.performSegue(withIdentifier: "toBigImage", sender: self)
    }
    
    // MARK: start Tableview markup
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return type == "Image" ? finalRankImageArray.count : finalRankArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if type == "Non-Image" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath)
            cell.selectionStyle = .none
            
            cell.textLabel?.text = "#\(indexPath.row + 1): \(finalRankArray[indexPath.row])"
            cell.textLabel?.font = UIFont.systemFont(ofSize: (Env.iPad ? 27 : 18))
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath) as! ImageCellNib
            cell.selectionStyle = .none
            
            cell.rankNumberLabel.text = "#\(indexPath.row + 1):"
            
            cell.rankImageView.image = finalRankImageArray[indexPath.row]
            cell.rankImageView.tag = indexPath.row
            cell.rankImageView.layer.borderColor = UIColor.black.cgColor
            cell.rankImageView.layer.borderWidth = 1
            
            let tapImageViewGesture = CustomGesture(target: self, action: #selector(self.tapImageView))
            tapImageViewGesture.indexPath = indexPath // Add the index path to the gesture itself
            cell.rankImageView.addGestureRecognizer(tapImageViewGesture)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {

        if type == "Image" {
            let currentImage = finalRankImageArrayFullSize[sourceIndexPath.row]
            finalRankImageArrayFullSize.remove(at: sourceIndexPath.row)
            finalRankImageArrayFullSize.insert(currentImage, at: destinationIndexPath.row)
            finalRankImageArray.remove(at: sourceIndexPath.row)
            finalRankImageArray.insert(currentImage, at: destinationIndexPath.row)
        }
        else {
            let currentText = finalRankArray[sourceIndexPath.row]
            finalRankArray.remove(at: sourceIndexPath.row)
            finalRankArray.insert(currentText, at: destinationIndexPath.row)
        }
        
        tableView.reloadData()
    }
    
    // MARK: end Tableview markup
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? MyImageViewController {
            destination.selectedImage = selectedImage
        }
        
        if let destination = segue.destination as? ShareRankPopoverViewController {
            destination.username = self.username
            destination.rankname = self.thisRank.projectName
            destination.existingProjectNames = self.existingProjectNames
            destination.delegate = self
        }
        
        if let destination = segue.destination as? CompilationViewController {
            destination.rank = oldRankInfo
        }
    }
    
    @IBAction func sharePressed(_ sender: LGButton) {
        let myAlert = UIAlertController(title: "Options", message: nil, preferredStyle: .alert)
        let inviteAction = UIAlertAction(title: "Invite a friend to rank this", style: UIAlertActionStyle.default) { (ACTION) in
            NVActivityIndicatorView.DEFAULT_BLOCKER_BACKGROUND_COLOR = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
            NVActivityIndicatorView.DEFAULT_COLOR = .white
            NVActivityIndicatorView.DEFAULT_TEXT_COLOR = .white
            NVActivityIndicatorView.DEFAULT_BLOCKER_MESSAGE = "Preparing"
            self.startAnimating()

            if let _ = self.thisRank.uniqueID {
                self.newRank = false
            }
            else {
                self.thisRank.uniqueID = UUID().uuidString
            }
            
            self.rankInfo.RankType = self.type
            self.rankInfo.NumObj = self.numObj
            self.rankInfo.numSubsets = self.numSubsets
            self.rankInfo.textArray = self.finalRankArray
            
            self.rankInfo.result.append(self.convertToCKAsset(image: self.rankResult)) // result of person's rank
            
            if self.rankInfo.RankType == "Image" {
                var assets = [CKAsset]()
                var fileNames = [String]()
                for (i, image) in self.finalRankImageArray.enumerated() {
                    let docDirPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
                    let filePath = docDirPath.appendingPathComponent("Image_\(i).jpeg")
                    if let myData = UIImageJPEGRepresentation(image,1.0) {
                        try? myData.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
                    }
                    print(filePath)
                    
                    let assetC = CKAsset(fileURL: URL(fileURLWithPath: filePath))
                    
                    assets.append(assetC)
                    fileNames.append("Image_\(i).jpeg")
                }
                self.rankInfo.imageArray = assets
                self.rankInfo.textArray = fileNames
            }
            
            dao.query(RankInfoss(), completionHandler: { (record, bool) in
                if record.count > 0 {
                    for eachRank in record { // get all project names
                        self.existingProjectNames.append(eachRank.Rankname)
                    }
                }
                return true
            })
            
            let predicate = NSPredicate(format: "uniqueID == %@", self.thisRank.uniqueID!)
            dao.query(RankInfoss(), predicate: predicate, completionHandler: { (record, bool) in
                if record.count > 0 {
                    self.oldRankInfo = record[0] // should only be one
                    
                    if self.oldRankInfo.uniqueDeviceID.contains(self.currentDeviceID) { // see if user already sent a rank; see if device ID is contained in array
                        for (index,deviceID) in self.oldRankInfo.uniqueDeviceID.enumerated() {
                            if deviceID == self.currentDeviceID {
                                self.username = self.oldRankInfo.Username[index]
                                self.userIndex = index
                            }
                        }
                        
                    }
                }
                DispatchQueue.main.async {
                    if let _ = self.username { // if username is already on the list, then user rank is already made and user has ranked so go directly to sending rank
                        if self.username!.count > 0 {
                            self.shareRank(username: self.username!, rankname: self.oldRankInfo.Rankname, isPublic: self.oldRankInfo.showPublic)
                        }
                    }
                    else { // enter username and possibly rank name
                        self.performSegue(withIdentifier: "toSharePopover", sender: self)
                    }
                    self.stopAnimating()
                }
                
                return true
            })
        }
        
        let shareResultsAction = UIAlertAction(title: "Share rank results", style: UIAlertActionStyle.default) { _ in
            DispatchQueue.main.async {
                let activityViewController = UIActivityViewController(activityItems: [self.rankResult], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                activityViewController.excludedActivityTypes = [.print, .assignToContact, .addToReadingList, .postToFlickr, .postToVimeo, .postToTencentWeibo]
                
                self.present(activityViewController, animated: true, completion: nil)
                activityViewController.completionWithItemsHandler = { activity, completed, items, error in
                    if completed {
                        SwiftMessages.show {
                            let view = MessageView.viewFromNib(layout: .cardView)
                            view.configureTheme(.success)
                            view.configureDropShadow()
                            view.configureContent(title: "Success!", body: "")
                            view.button?.isHidden = true
                            return view
                        }
                    }
                }
            }
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        myAlert.addAction(inviteAction)
        myAlert.addAction(shareResultsAction)
        myAlert.addAction(cancelAction)
        
        if let popoverController = myAlert.popoverPresentationController {
            popoverController.sourceView = self.view
        }
        self.present(myAlert, animated: true, completion: nil)
    }
    
    @IBAction func goHomePressed(_ sender: LGButton) {
        let tabbarVC = storyboard?.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        self.present(tabbarVC, animated: false, completion: nil)
    }
    
    func shareRank(username: String, rankname: String, isPublic: Bool) {
        if newRank { // upload this rank to the cloud and send out
            KRProgressHUD.show(withMessage: "Finalizing Project")
            self.thisRank.projectName = rankname
            self.thisRank.publicRank = isPublic
            
            if !self.rankInfo.Username.contains(username) {
                self.rankInfo.Username.append(username)
            }
            
            if (rankname.components(separatedBy: " ")).count > 1 { // can't have spaces for some reason?
                self.rankInfo.Rankname = (rankname.components(separatedBy: " ")).joined(separator: "_")
            }
            else {
                self.rankInfo.Rankname = rankname
            }
            
            self.rankInfo.showPublic = isPublic
            self.rankInfo.uniqueID = self.thisRank.uniqueID!
            self.rankInfo.uniqueDeviceID.append(self.currentDeviceID)
            dao.saveItem(self.rankInfo, completionHandler: { record in
                KRProgressHUD.dismiss({
                    self.shareRankMessageAndSave(result: self.rankResult)
                })
                EVLog("saved new public rank")
            })
        }
        else { // use downloaded rank and send out
            KRProgressHUD.show(withMessage: "Finalizing Project")
            if oldRankInfo.uniqueDeviceID.contains(currentDeviceID) { // already sent a rank so update old rank
                let beginIndex = self.numObj * self.userIndex!
                let endIndex = self.numObj * (self.userIndex! + 1) - 1
                oldRankInfo.textArray.replaceSubrange(beginIndex...endIndex, with: self.rankInfo.textArray)
                if oldRankInfo.RankType == "Image" {
                    oldRankInfo.imageArray.replaceSubrange(beginIndex...endIndex, with: self.rankInfo.imageArray)
                }
                oldRankInfo.result[userIndex!] = convertToCKAsset(image: self.rankResult)
            }
            else { // user is adding data to an established rank
                oldRankInfo.Username = oldRankInfo.Username + self.rankInfo.Username
                oldRankInfo.textArray = oldRankInfo.textArray + self.rankInfo.textArray
                oldRankInfo.imageArray = oldRankInfo.imageArray + self.rankInfo.imageArray
                oldRankInfo.result = oldRankInfo.result + self.rankInfo.result
                oldRankInfo.uniqueDeviceID.append(currentDeviceID)
            }
            dao.saveItem(self.oldRankInfo, completionHandler: { record in
            })
            
            DispatchQueue.global(qos: .userInitiated).async {
                let message = "What do you think of my ranks? Click the link below to try for yourself!"
                let forURLname = self.rankInfo.Rankname.replacingOccurrences(of: " ", with: "_")
                let saveFileURL = "rankd://content?rankname=\(forURLname)"
                let message2 = "\n\nIf you don't have Rank It Out, you can get it here"
                let appURL = URL(string : "itms-apps://itunes.apple.com/app/" + "id1317576365")
                let activityViewController = UIActivityViewController(activityItems: [message, self.rankResult, saveFileURL, message2, appURL!], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                activityViewController.excludedActivityTypes = [.print, .copyToPasteboard, .assignToContact, .saveToCameraRoll, .addToReadingList, .postToFlickr, .postToVimeo, .postToTencentWeibo, .airDrop]
                DispatchQueue.main.async {
                    self.networkSpinner(-1)
                    self.present(activityViewController, animated: true, completion: {
                        KRProgressHUD.dismiss()
                    })
                }
            }
            print("already voted, just passing on the rank")
        }
    }
    
    func shareRankMessageAndSave(result: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let message = "What do you think of my ranks? Click the link below to try for yourself!"
            let forURLname = self.rankInfo.Rankname.replacingOccurrences(of: " ", with: "_")
            let saveFileURL = "rankd://content?rankname=\(forURLname)"
            let message2 = "\n\nIf you don't have Rank It Out, you can get it here"
            let appURL = URL(string : "itms-apps://itunes.apple.com/app/" + "id1317576365")
            let activityViewController = UIActivityViewController(activityItems: [message, result, saveFileURL, message2, appURL!], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.excludedActivityTypes = [.print, .copyToPasteboard, .assignToContact, .saveToCameraRoll, .addToReadingList, .postToFlickr, .postToVimeo, .postToTencentWeibo, .airDrop]
            
            if Disk.exists("myRanks.json", in: .documents) { // update thisRank with new Unique ID
                var storedRanks = try! Disk.retrieve("myRanks.json", from: .documents, as: [Rank].self)
                for (index,rank) in storedRanks.enumerated() {
                    if rank.creatorUniqueDeviceID == self.currentDeviceID { // person is creator
                        if rank.dateCreated == self.thisRank.dateCreated { // match the creation via date; most likely to be unique
                            storedRanks[index] = self.thisRank
                        }
                    }
                }
                try? Disk.save(storedRanks, to: .documents, as: "myRanks.json")
            }
            
            DispatchQueue.main.async {
                self.present(activityViewController, animated: true, completion: nil)
                self.networkSpinner(-1)
            }
        }
    }
    
    @objc func rateUs(_ button: UIButton!) {
        self.rateApp(appId: "1317576365") { success in
            print("RateApp \(success)")
        }
    }
    
    func rateApp(appId: String, completion: @escaping ((_ success: Bool)->())) {
        if #available( iOS 10.3,*) {
            SKStoreReviewController.requestReview()
        }
        else {
            rateApp(appId: "id1317576365") { success in
                print("RateApp \(success)")
            }
        }
    }
    

}

extension FinalResultsViewController {
    func convertToCKAsset(image: UIImage) -> CKAsset {
        
        let i = arc4random_uniform(UInt32(10000))
        
        let docDirPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
        let filePath =  docDirPath.appendingPathComponent("Image_\(i).jpeg")
        if let data = UIImageJPEGRepresentation(image, 1.0) {
            try? data.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
        }
        
        let asset = CKAsset(fileURL: URL(fileURLWithPath: filePath))
        
        return asset
    }
    
    func networkSpinner(_ adjust: Int) {
        DispatchQueue.main.async {
            self.queryRunning = self.queryRunning + adjust
            UIApplication.shared.isNetworkActivityIndicatorVisible = self.queryRunning > 0
        }
    }
    
    func compareImage(image: UIImage, image2: UIImage) -> Bool {
        let imageData = UIImagePNGRepresentation(image)
        let imageData2 = UIImagePNGRepresentation(image2)
        if imageData == imageData2 {
            return true
        }
        return false
    }
    
    @objc func textChanged(_ sender:AnyObject) {
        let tf = sender as! UITextField
        var resp: UIResponder = tf
        while !(resp is UIAlertController) { resp = resp.next! }
        let alert = resp as! UIAlertController
        if let text = tf.text {
            (alert.actions[1] as UIAlertAction).isEnabled = (text != "" && !usernamesInRank.contains(text))
        }
        
    }
    
    @objc func textAdded(_ sender: AnyObject) {
        let tf = sender as! UITextField
        if var text = tf.text {
            if text.count > 0 {
                text = text.lowercased()
            }
        }
    }
}

class CustomGesture: UITapGestureRecognizer {
    var indexPath: IndexPath? = nil
}

class ImageCell: UITableViewCell {
    @IBOutlet weak var rankNumberLabel: UILabel!
    @IBOutlet weak var rankImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        rankNumberLabel.text = ""
        rankImageView.image = nil
    }
}

