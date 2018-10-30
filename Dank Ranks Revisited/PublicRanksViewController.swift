//
//  PublicRanksViewController.swift
//  Dank Ranks Revisited
//
//  Created by Tony Jiang on 8/28/18.
//  Copyright © 2018 Tony Jiang. All rights reserved.
//

import UIKit
import CloudKit
import EVCloudKitDao
import Disk
import ReachabilityLib

class PublicRanksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var searchActive: Bool = false
    
    var queryRunning: Int = 0
    var ranks: [RankInfoss] = []
  
    var loadingLabel = UILabel()
    var noResultsLabel = UILabel()
    var failSearchLabel = UILabel()
    
    var counter: Int = 0
    var numCycles: Int = 0
    var timer = Timer()
    
    let reachability = Reachability()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer.invalidate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let index = tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: index, animated: true)
        }
        
        ranks = []
        self.tableView.reloadData()
        
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.animateLoadingLabel), userInfo: nil, repeats: true)
        
        if !reachability.isInternetAvailable(){
            alert(message: "Please check your internet connection.", title: "Internet connection is not available")
        }
        else {
           performSearch("")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedAround()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = .clear
        tableView.separatorColor = .black
        let px: CGFloat = 0.5
        let frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: px)
        let line = UIView(frame: frame)
        self.tableView.tableHeaderView = line
        line.backgroundColor = self.tableView.separatorColor
        
        searchBar.placeholder = "Name of project"
        searchBar.delegate = self
        searchBar.backgroundColor = .clear
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        
        self.loadingLabel.text = "Loading..."
        self.loadingLabel.textColor = UIColor.black
        self.loadingLabel.textAlignment = .center
        self.loadingLabel.font = UIFont(name: "Avenir", size: (Env.iPad ? 30 : 20))
        self.loadingLabel.numberOfLines = 0
        self.loadingLabel.lineBreakMode = .byWordWrapping
        self.loadingLabel.adjustsFontSizeToFitWidth = true
        self.loadingLabel.minimumScaleFactor = 0.5
        self.loadingLabel.frame.size = CGSize(width: self.view.frame.width*0.9, height: self.view.frame.height/4)
        self.loadingLabel.center = CGPoint(x: self.view.frame.width/2, y: self.view.frame.height/5*2)
        self.loadingLabel.isHidden = true
        self.view.addSubview(loadingLabel)
        
        self.noResultsLabel.text = "No results match the name searched"
        self.noResultsLabel.textColor = UIColor.black
        self.noResultsLabel.textAlignment = .center
        self.noResultsLabel.font = UIFont(name: "Avenir", size: (Env.iPad ? 30 : 20))
        self.noResultsLabel.numberOfLines = 0
        self.noResultsLabel.lineBreakMode = .byWordWrapping
        self.noResultsLabel.adjustsFontSizeToFitWidth = true
        self.noResultsLabel.minimumScaleFactor = 0.5
        self.noResultsLabel.frame.size = CGSize(width: self.view.frame.width*0.9, height: self.view.frame.height/4)
        self.noResultsLabel.center = CGPoint(x: self.view.frame.width/2, y: self.view.frame.height/5*2)
        self.noResultsLabel.isHidden = true
        self.view.addSubview(noResultsLabel)
        
        self.failSearchLabel.text = "Could not complete search. Please try again."
        self.failSearchLabel.textColor = UIColor.black
        self.failSearchLabel.textAlignment = .center
        self.failSearchLabel.font = UIFont(name: "Avenir", size: (Env.iPad ? 30 : 20))
        self.failSearchLabel.numberOfLines = 0
        self.failSearchLabel.lineBreakMode = .byWordWrapping
        self.failSearchLabel.adjustsFontSizeToFitWidth = true
        self.failSearchLabel.minimumScaleFactor = 0.5
        self.failSearchLabel.frame.size = CGSize(width: self.view.frame.width*0.9, height: self.view.frame.height/4)
        self.failSearchLabel.center = CGPoint(x: self.view.frame.width/2, y: self.view.frame.height/5*2)
        self.failSearchLabel.isHidden = true
        self.view.addSubview(failSearchLabel)
    }
    
    @objc func animateLoadingLabel() {
        if numCycles == 10 {
            self.timer.invalidate()
            self.loadingLabel.isHidden = true
            self.failSearchLabel.isHidden = false
        }
        
        switch counter {
        case 0: self.loadingLabel.text = "Loading."
        case 1: self.loadingLabel.text = "Loading.."
        case 2: self.loadingLabel.text = "Loading..."
        default: ()
        }
        counter = (counter + 1) % 3
        numCycles += 1
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        performSearch(self.searchBar.text!)
        searchActive = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performSearch(self.searchBar.text!)
    }
    
    func performSearch(_ searchText: String) {
        self.tableView.isUserInteractionEnabled = false
        
        if ranks.count == 0 {
            self.loadingLabel.isHidden = false
            self.timer.fire()
        }
        self.noResultsLabel.isHidden = true
        self.failSearchLabel.isHidden = true
        
        EVLog("Filter for \(searchText)")
        networkSpinner(1)
        let predicate1 = NSPredicate(format: "Rankname BEGINSWITH %@", searchText)
        let predicate2 = NSPredicate(format: "showPublic == %@", NSNumber(booleanLiteral: true))
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
        EVCloudKitDao.publicDB.query(RankInfoss(), predicate: compoundPredicate, completionHandler: { results, isFinished in
            EVLog("query for '\(searchText)' result count = \(results.count)")
            
            DispatchQueue.main.async {
                self.ranks = results
                if results.count != 0 {
                    self.loadingLabel.isHidden = true
                    self.noResultsLabel.isHidden = true
                    self.networkSpinner(-1)
                    self.tableView.isUserInteractionEnabled = true
                    self.failSearchLabel.isHidden = true
                }
                else {
                    self.loadingLabel.isHidden = true
                    self.noResultsLabel.isHidden = false
                    self.failSearchLabel.isHidden = true
                }
                self.timer.invalidate()
                self.tableView.reloadData()
            }
            
            return (self.ranks.count < 500)
        }, errorHandler: { error in
            EVLog("ERROR in query for words \(searchText)")
            self.networkSpinner(-1)
            DispatchQueue.main.async {
                self.loadingLabel.isHidden = true
                self.noResultsLabel.isHidden = false
                self.tableView.isUserInteractionEnabled = true
            }
        })
    }
    
    func networkSpinner(_ adjust: Int) {
        self.queryRunning = self.queryRunning + adjust
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = self.queryRunning > 0
        }
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ranks.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rank = ranks[indexPath.row]
        if rank.uniqueDeviceID.contains(UIDevice.current.identifierForVendor!.uuidString) {
            let myAlert = UIAlertController(title: "Options", message: "", preferredStyle: .alert)
            let compilationAction = UIAlertAction(title: "See Compiled Rank Results", style: UIAlertActionStyle.default) { (ACTION) in
                self.performSegue(withIdentifier: "toCompilation", sender: self)
            }
            let rankAction = UIAlertAction(title: "Rank again", style: UIAlertActionStyle.default) { (ACTION) in
                self.goToRank(rank: rank)
            }
            let shareAction = UIAlertAction(title: "Share Ranking", style: UIAlertActionStyle.default) { (ACTION) in
                let message = "What do you think of this rank? Click the link below to try for yourself!"
                let forURLname = rank.Rankname.replacingOccurrences(of: " ", with: "_")
                let saveFileURL = "rankd://content?rankname=\(forURLname)"
                let message2 = "\n\nIf you don't have Rank It Out, you can get it here"
                let appURL = URL(string : "itms-apps://itunes.apple.com/app/" + "id1317576365")
                let activityViewController = UIActivityViewController(activityItems: [message, saveFileURL, message2, appURL!], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                activityViewController.excludedActivityTypes = [.print, .copyToPasteboard, .assignToContact, .saveToCameraRoll, .addToReadingList, .postToFlickr, .postToVimeo, .postToTencentWeibo, .airDrop]
                self.present(activityViewController, animated: true, completion: nil)
                DispatchQueue.main.async {
                    self.networkSpinner(-1)
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                tableView.deselectRow(at: indexPath, animated: true)
            }
            myAlert.addAction(compilationAction)
            myAlert.addAction(rankAction)
            myAlert.addAction(shareAction)
            myAlert.addAction(cancelAction)
            
            if let popoverController = myAlert.popoverPresentationController {
                popoverController.sourceView = self.view
            }
            self.present(myAlert, animated: true, completion: nil)
        }
        else {
            if defaults.bool(forKey: "secondSearch") {
                let myAlert = UIAlertController(title: "Options", message: nil, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Rank this", style: UIAlertActionStyle.default) { (ACTION) in
                    self.goToRank(rank: rank)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
                
                myAlert.addAction(okAction)
                myAlert.addAction(cancelAction)
                
                if let popoverController = myAlert.popoverPresentationController {
                    popoverController.sourceView = self.view
                }
                self.present(myAlert, animated: true, completion: nil)
            }
            else { // first time
                let myAlert = UIAlertController(title: "Notification", message: "Successful completion of any project allows you to see the compiled results!", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (ACTION) in
                    defaults.set(true, forKey: "secondSearch")
                    self.goToRank(rank: rank)
                }
                myAlert.addAction(okAction)
                
                if let popoverController = myAlert.popoverPresentationController {
                    popoverController.sourceView = self.view
                }
                self.present(myAlert, animated: true, completion: nil)
            }
        }
        
    }
    
    func goToRank(rank: RankInfoss) {
        var myRanks: [Rank] = []
        if Disk.exists("myRanks.json", in: .documents) {
            myRanks = try! Disk.retrieve("myRanks.json", from: .documents, as: [Rank].self)
        }
        else {
            myRanks = []
            try? Disk.save(myRanks, to: .documents, as: "myRanks.json")
        }
        
        let thisRank = self.convertStructures(rank: rank)
        
        var imageSets: [UIImage] = []
        if thisRank.type == "Image" {
            let firstImageSet = rank.imageArray[0..<thisRank.numObj]
            for image in firstImageSet {
                imageSets.append(image.image()!)
            }
        }
        
        myRanks.append(thisRank)
        let thisRankIndexPathRow = myRanks.count - 1
        
        var publicRank = false
        if rank.showPublic {
            publicRank = true
            thisRank.publicRank = true
        }
        
        let myVC = self.storyboard?.instantiateViewController(withIdentifier: "RankingViewController") as! RankingViewController
        myVC.myRanks = myRanks
        myVC.thisRank = thisRank
        myVC.thisRankIndexPathRow = thisRankIndexPathRow
        myVC.imageSets = imageSets
        myVC.publicRank = publicRank
        self.navigationController?.pushViewController(myVC, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell1", for: indexPath) as! ResultCell
        cell.backgroundColor = .clear
        cell.separatorInset = .zero
        
        let fontStyle = UIFont(name: "Avenir", size: (Env.iPad ? 24 : 18))
        let rank = ranks[indexPath.row]
        
        cell.rankName.text = rank.Rankname
        cell.rankName.font = UIFont(name: "Avenir", size: (Env.iPad ? 36 : 24))
        cell.sizeToFit()
        
        cell.rankType.text = "Type: \(rank.RankType)"
        cell.rankType.font = fontStyle
        
        cell.objectNum.text = "\(rank.NumObj) objects"
        cell.objectNum.font = fontStyle
        
        if rank.Username.count == 1 {
            cell.numTimesRanked.text = "Ranked by \(rank.Username.count) user"
        }
        else {
            cell.numTimesRanked.text = "Ranked by \(rank.Username.count) users"
        }
        cell.numTimesRanked.font = fontStyle
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destination = segue.destination as? CompilationViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                let rank = ranks[indexPath.row]
                destination.rank = rank
            }
        }
        
    }
}

class ResultCell: UITableViewCell {
    @IBOutlet weak var rankType: UILabel!
    @IBOutlet weak var rankName: UILabel!
    @IBOutlet weak var objectNum: UILabel!
    @IBOutlet weak var numTimesRanked: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        rankType.text = ""
        rankName.text = ""
        objectNum.text = ""
        numTimesRanked.text = ""
    }
}

