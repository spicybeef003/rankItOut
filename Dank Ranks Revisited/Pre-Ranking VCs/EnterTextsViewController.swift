//
//  SecondViewController.swift
//  Dank Ranks Revisited
//
//  Created by Tony Jiang on 8/24/18.
//  Copyright © 2018 Tony Jiang. All rights reserved.
//

import UIKit
import LGButton
import Disk

class EnterTextsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var projectTitleOutlet: UITextField!
    @IBOutlet weak var startRankingButtonOutlet: LGButton!
    @IBOutlet weak var premiumLabel: UILabel!
    
    var myRanks: [Rank]!
    var thisRank: Rank!
    var numObjects: Int = 0
    var textArray: [String] = []
    var thisRankIndexPathRow: Int!
    
    let customColor = UIColor(red: 2/255, green: 174/255, blue: 243/255, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if thisRank.rankFinished {
            textArray = thisRank.textArray
            numObjects = thisRank.numObj
        }
        else {
            numObjects = numObjects + thisRank.numSubsets
            textArray = textArray + [String](repeating: "", count: thisRank.numSubsets)
        }

        hideKeyboardWhenTappedAround()
        setupTableView()
        
        if !defaults.bool(forKey: "premium") {
            startRankingButtonOutlet.titleString = "Start Ranking*"
            premiumLabel.isHidden = false
        }
        else {
            startRankingButtonOutlet.titleString = "Start Ranking"
            premiumLabel.isHidden = true
        }
        
        projectTitleOutlet.layer.borderColor = customColor.cgColor
        projectTitleOutlet.layer.borderWidth = 1.5
        projectTitleOutlet.layer.cornerRadius = 8
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = .clear
        tableView.estimatedRowHeight = 50
        tableView.separatorStyle = .none
    }
    
    @objc func deleteCell(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: self.tableView)
        if let tapIndexPath = self.tableView.indexPathForRow(at: tapLocation) {
            let myAlert = UIAlertController(title: "Delete object #\(tapIndexPath.row + 1)?", message: nil, preferredStyle: .alert)
            
            let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
                self.textArray.remove(at: tapIndexPath.row)
                self.numObjects = self.numObjects - 1
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
    
    
    @IBAction func addPressed(_ sender: LGButton) {
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
                    if self.numObjects + numNewObjects > 15 {
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
                        self.numObjects = self.numObjects + numNewObjects
                        self.textArray = self.textArray + [String](repeating: "", count: numNewObjects)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
                else {
                    self.numObjects = self.numObjects + numNewObjects
                    self.textArray = self.textArray + [String](repeating: "", count: numNewObjects)
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
    
    @IBAction func deletePressed(_ sender: LGButton) {
        // new screen to select to delete
    }
    
    
    
    @objc func didFinishTyping(_ textField: UITextField) {
        let pointInTable = textField.convert(textField.bounds.origin, to: self.tableView)
        let textFieldIndexPath = self.tableView.indexPathForRow(at: pointInTable)
        textArray[textFieldIndexPath!.row] = textField.text ?? ""
        print(textArray)
    }
    
    @objc func textChanged(_ sender: AnyObject) {
        let tf = sender as! UITextField
        var resp: UIResponder = tf
        while !(resp is UIAlertController) { resp = resp.next! }
        let alert = resp as! UIAlertController
        
        if let numObj = Int(tf.text!) {
            (alert.actions[1] as UIAlertAction).isEnabled = numObj > 0
        }
    }
    
    
    @IBAction func createRankPressed(_ sender: LGButton) {
        for (index,text) in textArray.enumerated() {
            if text.isEmpty || (text.containsWhitespace && !text.isContainsLetters) {
                alert(message: "", title: "Please enter a value for object #\(index+1) or remove it" as NSString)
                shake(object: sender)
                break
            }
        }
        
        thisRank.numObj = numObjects
        thisRank.textArray = textArray
        thisRank.projectName = projectTitleOutlet.text!
        thisRank.rankFinished = false
        thisRank.currentComparisonIndex = 0
        thisRank.numTotalComparisons = 0
        thisRank.countIndex = 0
        
        if textArray.unique() != textArray {
            let myAlert = UIAlertController(title: "Proceed with duplicate entries?", message: nil, preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) { (ACTION) in
                self.goToRankingVC()
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
            DispatchQueue.global(qos: .userInitiated).async {
                self.myRanks.append(self.thisRank)
                self.thisRankIndexPathRow = self.myRanks.count - 1
                try? Disk.save(self.myRanks, to: .documents, as: "myRanks.json")
                DispatchQueue.main.async {
                    self.goToRankingVC()
                }
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
    
    
    // MARK: Tableview setup
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell1", for: indexPath) as! textObjectCell
        cell.separatorInset = .zero
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        
        cell.objectNumberLabel.text = "#\(indexPath.row + 1)"
        
        cell.objectTextField.text = textArray[indexPath.row]
        cell.objectTextField.delegate = self
        cell.objectTextField.addTarget(self, action: #selector(didFinishTyping), for: .editingDidEnd)
        cell.objectTextField.layer.borderColor = customColor.cgColor
        cell.objectTextField.layer.borderWidth = 1.5
        cell.objectTextField.layer.cornerRadius = 8
        
        cell.deleteIconOutlet.tag = indexPath.row
        let deleteTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.deleteCell))
        deleteTapGesture.delegate = self
        cell.deleteIconOutlet.addGestureRecognizer(deleteTapGesture)
        
        return cell
    }
    

}


class textObjectCell: UITableViewCell {
    @IBOutlet weak var objectNumberLabel: UILabel!
    @IBOutlet weak var objectTextField: UITextField!
    @IBOutlet weak var deleteIconOutlet: UIImageView!
    
    var numObjects: Int!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        objectNumberLabel.text = nil
        objectTextField.text = nil
    }
}

