//
//  ModifyRankingsVC.swift
//  Dank Ranks Revisited
//
//  Created by Tony Jiang on 9/16/18.
//  Copyright © 2018 Tony Jiang. All rights reserved.
//

import UIKit
import ImagePicker
import Lightbox

protocol ModifyRankingsVCDelegate: class {
    func modifiedRankings(newRank: Rank, newArrayOfValues: [Int])
}

class ModifyRankingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, ImagePickerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addOutlet: UIBarButtonItem!
    
    var thisRank: Rank!
    var rankFinished: Bool!
    var newRank = true
    var rankResult: UIImage!
    
    var queryRunning: Int = 0
    
    var type: String!
    var textArray: [String] = []
    var shuffledTextArray: [String] = []
    
    var imageSet: [UIImage] = []
    var shuffledImageSet: [UIImage] = []
    var finalRankArray: [String] = [] // holds final ranking
    var finalRankImageArray: [UIImage] = [] // holds final ranking for images
    var finalRankImageArrayFullSize: [UIImage] = []
    var nextGroup: [String] = []
    var nextImageGroupIndices: [Int] = []
    var arrayOfValues: [Int] = []
    
    var countIndex: Int!
    var currentComparisonIndex: Int!
    
    var rankName: String!
    var numObj: Int!
    var numSubsets: Int!
    
    var delegate: ModifyRankingsVCDelegate?
    
    var activeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        
        addOutlet.title = type == "Image" ? "Add Image(s)" : "Add Object(s)"
    }
    
    @objc func deleteCell(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: self.tableView)
        if let tapIndexPath = self.tableView.indexPathForRow(at: tapLocation) {
            if let cell = self.tableView.cellForRow(at: tapIndexPath) as? textObjectCell {
                if let text = cell.objectTextField.text {
                    let myAlert = UIAlertController(title: "Delete object #\(tapIndexPath.row + 1)?", message: nil, preferredStyle: .alert)
                    
                    let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
                        if let index = self.textArray.index(of: text) {
                            self.textArray.remove(at: index)
                            self.arrayOfValues.remove(at: index)
                        }
                        
                        if let index = self.shuffledTextArray.index(of: text) {
                            self.shuffledTextArray.remove(at: index)
                        }
                        
                        if let index = self.finalRankArray.index(of: text) {
                            self.finalRankArray.remove(at: index)
                        }
                        
                        if let index = self.nextGroup.index(of: text) {
                            self.nextGroup.remove(at: index)
                            for obj in self.textArray {
                                if !self.nextGroup.contains(obj) {
                                    self.nextGroup.insert(obj, at: index)
                                    break
                                }
                            }
                        }
                        
                        self.numObj = self.numObj - 1
                        DispatchQueue.main.async {
                            let range = NSMakeRange(0, self.tableView.numberOfSections)
                            let sections = NSIndexSet(indexesIn: range)
                            self.tableView.reloadSections(sections as IndexSet, with: .automatic)
                        }
                    }
                    
                    let cancelAction = UIAlertAction(title: "No", style: .default) { _ in
                    }
                    
                    myAlert.addAction(yesAction)
                    myAlert.addAction(cancelAction)
                    
                    if let popoverController = myAlert.popoverPresentationController {
                        popoverController.sourceView = self.view
                    }
                    self.present(myAlert, animated: true, completion: nil)
                }
            }
            
            if let cell = self.tableView.cellForRow(at: tapIndexPath) as? ImageCellDeleteNib {
                if let _ = cell.picOutlet.image {
                    let myAlert = UIAlertController(title: "Delete object #\(tapIndexPath.row + 1)?", message: nil, preferredStyle: .alert)
                    
                    let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
                        
                        self.imageSet.remove(at: tapIndexPath.row)
                        self.arrayOfValues.remove(at: tapIndexPath.row)
                        
                        if self.nextImageGroupIndices.contains(tapIndexPath.row) {
                            for (i,_) in self.imageSet.enumerated() {
                                if !self.nextImageGroupIndices.contains(i) {
                                    self.nextImageGroupIndices[self.nextImageGroupIndices.index(of: tapIndexPath.row)!] = i
                                    break
                                }
                            }
                        }
                        
                        for (j, nextImageGroupIndex) in self.nextImageGroupIndices.enumerated() {
                            if tapIndexPath.row < nextImageGroupIndex { // shift indices down
                                self.nextImageGroupIndices[j] = nextImageGroupIndex - 1
                            }
                        }
                        
                        self.numObj = self.numObj - 1
                        DispatchQueue.main.async {
                            let range = NSMakeRange(0, self.tableView.numberOfSections)
                            let sections = NSIndexSet(indexesIn: range)
                            self.tableView.reloadSections(sections as IndexSet, with: .automatic)
                        }
                    }
                    
                    let cancelAction = UIAlertAction(title: "No", style: .default) { _ in
                    }
                    
                    myAlert.addAction(yesAction)
                    myAlert.addAction(cancelAction)
                    
                    if let popoverController = myAlert.popoverPresentationController {
                        popoverController.sourceView = self.view
                    }
                    self.present(myAlert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func donePressed(_ sender: UIBarButtonItem) {
        if let tf = activeTextField {
            tf.resignFirstResponder()
        }
        
        thisRank.nextGroup = nextGroup
        thisRank.textArray = textArray
        thisRank.shuffledTexArray = shuffledTextArray
        thisRank.finalRankTextArray = finalRankArray
        thisRank.numObj = numObj
        thisRank.countIndex = countIndex
        
        if type == "Image" {
            var imageArrayData: [Data] = []
            for (index,image) in imageSet.enumerated() {
                imageArrayData.append(UIImageJPEGRepresentation(image, 1)!)
            }
       
            self.thisRank.imageArrayData = imageArrayData
            self.thisRank.nextImageGroupIndexes = nextImageGroupIndices
        }
        
        self.delegate?.modifiedRankings(newRank: thisRank, newArrayOfValues: arrayOfValues)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addPressed(_ sender: UIBarButtonItem) {
        if type == "Image" {
            let config = Configuration()
            config.doneButtonTitle = "Done"
            config.noImagesTitle = "No images found!"
            config.recordLocation = false
            config.allowVideoSelection = false
            
            let imagePicker = ImagePickerController(configuration: config)
            if !defaults.bool(forKey: "premium") {
                imagePicker.imageLimit = 15 - numObj
            }
            imagePicker.delegate = self
            
            present(imagePicker, animated: true, completion: nil)
        }
        else {
            let textAlert = UIAlertController(title: "Add how many objects?", message: nil, preferredStyle: .alert)
            
            textAlert.addTextField { (tf:UITextField!) in
                tf.delegate = self
                tf.placeholder = "# objects to add"
                tf.font = UIFont(name: "Helvetica Neue", size: 16)
                tf.keyboardType = .numberPad
                tf.addTarget(self, action: #selector(self.textChanged), for: .editingChanged)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
                print("Cancel Button Pressed")
            }
            
            let okAction = UIAlertAction(title: "OK", style: .default) { action in
                if let numNewObjects = Int(textAlert.textFields![0].text!) {
                    if !defaults.bool(forKey: "premium") {
                        if self.numObj + numNewObjects > 15 {
                            let myAlert = UIAlertController(title: "Go premium to rank up to 60 items.", message: nil, preferredStyle: .alert)
                            
                            let yesAction = UIAlertAction(title: "Go Premium", style: .cancel) { _ in
                                let vc = SettingsViewController()
                                vc.purchase(purchase: RegisteredPurchase.bingle)
                            }
                            
                            let cancelAction = UIAlertAction(title: "Cancel", style: .default) { _ in
                            }
                            
                            myAlert.addAction(cancelAction)
                            myAlert.addAction(yesAction)
                            
                            if let popoverController = myAlert.popoverPresentationController {
                                popoverController.sourceView = self.view
                            }
                            self.present(myAlert, animated: true, completion: nil)
                        }
                        else {
                            self.numObj = self.numObj + numNewObjects
                            
                            self.textArray = self.textArray + [String](repeating: "", count: numNewObjects)
                            self.shuffledTextArray = self.shuffledTextArray + [String](repeating: "", count: numNewObjects)
                            if self.numSubsets != 2 {
                                self.finalRankArray = self.finalRankArray + [String](repeating: "", count: numNewObjects)
                            }
                            self.arrayOfValues = self.arrayOfValues + [Int](repeating: 0, count: numNewObjects)
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                    else {
                        self.numObj = self.numObj + numNewObjects
                        
                        self.textArray = self.textArray + [String](repeating: "", count: numNewObjects)
                        self.shuffledTextArray = self.shuffledTextArray + [String](repeating: "", count: numNewObjects)
                        if self.numSubsets != 2 {
                            self.finalRankArray = self.finalRankArray + [String](repeating: "", count: numNewObjects)
                        }
                        self.arrayOfValues = self.arrayOfValues + [Int](repeating: 0, count: numNewObjects)
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
            
            textAlert.addAction(cancelAction)
            textAlert.addAction(okAction)
            
            if let popoverController = textAlert.popoverPresentationController {
                popoverController.sourceView = self.view
            }
            self.present(textAlert, animated: true, completion: nil)
        }
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 110
        tableView.delegate = self
        tableView.register(UINib(nibName: "ImageCellDeleteNib", bundle: nil), forCellReuseIdentifier: "imageCell")
    }

    // MARK: start Tableview markup
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return type == "Image" ? imageSet.count : textArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if type == "Non-Image" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath) as! textObjectCell
            cell.selectionStyle = .none
            
            cell.objectNumberLabel.text = "#\(indexPath.row + 1)"
            
            let customColor = UIColor(red: 2/255, green: 174/255, blue: 243/255, alpha: 1)
            
            cell.objectTextField.text = textArray[indexPath.row]
            cell.objectTextField.delegate = self
            cell.objectTextField.addTarget(self, action: #selector(didFinishTyping), for: .editingDidEnd)
            cell.objectTextField.layer.borderColor = customColor.cgColor
            cell.objectTextField.layer.borderWidth = 1.5
            cell.objectTextField.layer.cornerRadius = 8
            cell.objectTextField.tag = indexPath.row
            
            if numSubsets == 2 {
                cell.deleteIconOutlet.image = nil
            }
            else if textArray.count > (numSubsets - 1) {
                cell.deleteIconOutlet.image = UIImage(named: "deleteIcon")!
                cell.deleteIconOutlet.tag = indexPath.row
                let deleteTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.deleteCell))
                deleteTapGesture.delegate = self
                cell.deleteIconOutlet.addGestureRecognizer(deleteTapGesture)
            }
            else {
                cell.deleteIconOutlet.image = nil
            }
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath) as! ImageCellDeleteNib
            cell.selectionStyle = .none
            
            cell.ranklabel.text = "#\(indexPath.row + 1):"
            
            cell.picOutlet.image = imageSet[indexPath.row]
            cell.picOutlet.tag = indexPath.row
            cell.picOutlet.layer.borderColor = UIColor.black.cgColor
            cell.picOutlet.layer.borderWidth = 1
            
            if numSubsets == 2 {
                cell.deleteIcon.image = nil
            }
            else if imageSet.count > (numSubsets - 1) {
                cell.deleteIcon.image = UIImage(named: "deleteIcon")!
                cell.deleteIcon.tag = indexPath.row
                let deleteTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.deleteCell))
                deleteTapGesture.delegate = self
                cell.deleteIcon.addGestureRecognizer(deleteTapGesture)
            }
            else {
                cell.deleteIcon.image = nil
            }
            
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
            imageSet.append(image)
            shuffledImageSet.append(image)
            if self.numSubsets != 2 {
                finalRankImageArray.append(image.resizeImage(targetSize: CGSize(width: self.view.frame.width/3, height: self.view.frame.height/4)))
                finalRankImageArrayFullSize.append(image)
            }
            
        }
        
        numObj = numObj + images.count
        self.arrayOfValues = self.arrayOfValues + [Int](repeating: 0, count: images.count)
        
        tableView.reloadData()
    }
    
    // MARK: Textfield delegate
    @objc func textChanged(_ sender: AnyObject) {
        let tf = sender as! UITextField
        var resp: UIResponder = tf
        while !(resp is UIAlertController) { resp = resp.next! }
        let alert = resp as! UIAlertController
        if let numObj = Int(tf.text!) {
            (alert.actions[1] as UIAlertAction).isEnabled = numObj > 0
        }
    }
    
    @objc func didFinishTyping(_ textField: UITextField) {
        let pointInTable = textField.convert(textField.bounds.origin, to: self.tableView)
        let textFieldIndexPath = self.tableView.indexPathForRow(at: pointInTable)
        let oldText = textArray[textFieldIndexPath!.row]
        
        if let index = nextGroup.index(of: oldText) {
            nextGroup[index] = textField.text ?? ""
        }
        
        if let index = shuffledTextArray.index(of: oldText) {
            shuffledTextArray[index] = textField.text ?? ""
        }
        
        if let index = finalRankArray.index(of: oldText) {
            finalRankArray[index] = textField.text ?? ""
        }
        
        textArray[textFieldIndexPath!.row] = textField.text ?? ""
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeTextField = textField
    }
}

class ImageCellDeleteNib: UITableViewCell {
    @IBOutlet weak var picOutlet: UIImageView!
    @IBOutlet weak var ranklabel: UILabel!
    @IBOutlet weak var deleteIcon: UIImageView!
}
