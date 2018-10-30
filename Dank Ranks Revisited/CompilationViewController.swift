//
//  CompilationViewController.swift
//  DankRanks
//
//  Created by Jiang, Tony on 12/23/17.
//  Copyright © 2017 Jiang, Tony. All rights reserved.
//

import UIKit
import LGButton

class CompilationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var shareButtonOutlet: LGButton!
    
    var scrollView = UIScrollView()
    var tableView = UITableView()
    
    var rank: RankInfoss!
    
    var tieBreaker: Int = 0
    var sortedIndexSumArray: [Int] = []
    var sortedreferenceImageSet: [UIImage] = []
    var sortedreferenceTextArray: [String] = []
    
    var selectedImage: UIImage?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.frame = CGRect(x: 0, y: self.navigationController!.navigationBar.frame.maxY + 8, width: view.frame.width, height: shareButtonOutlet.frame.minY - self.navigationController!.navigationBar.frame.maxY - 10)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = true
        view.addSubview(scrollView)
        
        tableView.frame = scrollView.frame
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "textCell")
        tableView.register(UINib(nibName: "ImageCellNib", bundle: nil), forCellReuseIdentifier: "imageCell")
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 110
        scrollView.addSubview(tableView)
        
        let numObj = rank.NumObj
        
        switch (rank.RankType) {
        case "Non-Image":
            var referenceTextArray = [String]()
            for (_,text) in rank.textArray[0..<numObj].enumerated() {
                referenceTextArray.append(text)
            }
            let textArraySets = rank.textArray.splitBy(numObj) // each set of #NumObj is one result
            var indexArray = [Int](0..<numObj)
            for (index, textArray) in textArraySets.enumerated() {
                if index != 0 {
                    for referenceName in referenceTextArray {
                        let newIndex = textArray.index(of: referenceName)
                        indexArray.append(newIndex!)
                    }
                }
            }
            
            let splitIndexArray = indexArray.splitBy(numObj)
            var firstIndexArray = splitIndexArray[0]
            for (index,nextIndexArray) in splitIndexArray.enumerated() {
                if index != 0 {
                    firstIndexArray = zip(firstIndexArray, nextIndexArray).map(+)
                }
            }
            
            let tempSortedTuples = (0..<numObj).map { (firstIndexArray[$0], referenceTextArray[$0]) }.sorted { $0.0 < $1.0 }
            
            sortedIndexSumArray = tempSortedTuples.map { $0.0 }
            let invertedIndexSumArray = sortedIndexSumArray.map({sortedIndexSumArray.max()! - $0})
            sortedreferenceTextArray = tempSortedTuples.map { $0.1 }
            
        case "Image":
            var referenceImageSet = [UIImage]()
            for (_,asset) in rank.imageArray[0..<numObj].enumerated() {
                referenceImageSet.append(asset.image()!)
            }
            let imageNameSets = rank.textArray.splitBy(numObj) // each set of #NumObj is one result
            let referenceImageNameSet = imageNameSets[0] // normalize to the first rank made
            var indexArray = [Int](0..<numObj)
            for (index, imageNameSet) in imageNameSets.enumerated() {
                if index != 0 {
                    for referenceName in referenceImageNameSet {
                        let newIndex = imageNameSet.index(of: referenceName)
                        indexArray.append(newIndex!)
                    }
                }
            }
            
            let splitIndexArray = indexArray.splitBy(numObj)
            var firstIndexArray = splitIndexArray[0]
            for (index,nextIndexArray) in splitIndexArray.enumerated() {
                if index != 0 {
                    firstIndexArray = zip(firstIndexArray, nextIndexArray).map(+)
                }
            }
            
            let tempSortedTuples = (0..<numObj).map { (firstIndexArray[$0], referenceImageSet[$0]) }.sorted { $0.0 < $1.0 }
            
            sortedIndexSumArray = tempSortedTuples.map { $0.0 }
            let invertedIndexSumArray = sortedIndexSumArray.map({sortedIndexSumArray.max()! - $0}) // point system
            sortedreferenceImageSet = tempSortedTuples.map { $0.1 }
          
        default:()
        }
        
        let compiledImage = tableView.screenshot()
        tableView.isHidden = true
        
        for i in 0...rank.Username.count {
            let font = UIFont(name: "Avenir", size: (Env.iPad ? 30 : 20))
            
            var image: UIImage!
            var titleText: String!
            if i == 0 {
                image = compiledImage
                titleText = "Compiled Rankings"
            }
            else {
                image = rank.result[i-1].image()!
                titleText = "Ranker: \(rank.Username[i-1])"
            }
            
            let title = UILabel()
            editLabel(label: title, text: titleText)
            title.font = font!
            title.frame.origin.y = 14
            title.frame.size = CGSize(width: view.frame.width * 0.8, height: 35)
            title.center.x = view.frame.width/2 + view.frame.width*CGFloat(i)
            scrollView.addSubview(title)
            
            let resizeImage = image.resizeImage(targetSize: CGSize(width: view.frame.width, height: self.tableView.contentSize.height))
            let resultView = UIImageView(frame: CGRect(x: 0 + (view.frame.width*CGFloat(i)), y: title.frame.maxY + 10, width: view.frame.width, height: tableView.contentSize.height))
            resultView.image = resizeImage
            resultView.contentMode = .scaleAspectFit
            scrollView.addSubview(resultView)
            
        }
        scrollView.contentSize = CGSize(width: view.frame.width*CGFloat(rank.Username.count+1), height: tableView.contentSize.height * 1.1)
    }
    
    // MARK: start Tableview markup
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rank.NumObj
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row > 0 {
            if sortedIndexSumArray[indexPath.row] == sortedIndexSumArray[indexPath.row-1] {
                tieBreaker = tieBreaker + 1
            }
            else {
                tieBreaker = 0
            }
        }
        
        let thisRank = String((indexPath.row+1) - tieBreaker)
        
        if rank.RankType == "Non-Image" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath)
            cell.isUserInteractionEnabled = false

            cell.textLabel?.text = "#" + thisRank + ": " + "\(sortedreferenceTextArray[indexPath.row])"
            cell.textLabel?.textColor = .black
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath) as! ImageCellNib
            cell.selectionStyle = .none
            
            cell.rankNumberLabel.text = "#" + thisRank + ":"
            
            cell.rankImageView.image = sortedreferenceImageSet[indexPath.row]
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
    
    // MARK: end Tableview markup
    
    
    @IBAction func sharePressed(_ sender: LGButton) {
        let result = scrollView.screenshot()!
        let activityViewController = UIActivityViewController(activityItems: [result], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.excludedActivityTypes = [.print, .copyToPasteboard, .assignToContact, .saveToCameraRoll, .addToReadingList, .postToFlickr, .postToVimeo, .postToTencentWeibo, .airDrop]
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func tapImageView(_ gesture: CustomGesture) {
        let indexPath = gesture.indexPath!
        selectedImage = self.sortedreferenceImageSet[indexPath.row]
        self.performSegue(withIdentifier: "toBiggerImage", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? MyImageViewController {
            destination.selectedImage = selectedImage
        }
    }
    

}

class ImageCellNib: UITableViewCell {
    @IBOutlet weak var rankImageView: UIImageView!
    @IBOutlet weak var rankNumberLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}


