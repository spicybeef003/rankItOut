//
//  Helper.swift
//  
//
//  Created by Jiang, Tony on 12/16/17.
//

import UIKit
import CloudKit
import EVReflection
import EVCloudKitDao

let defaults = UserDefaults.standard

let dao: EVCloudKitDao = EVCloudKitDao.publicDB
let dao2 = EVCloudKitDao.publicDBForContainer("iCloud.com.TianProductions.DankRanks")

class Rank: Codable {
    var projectName: String = ""
    var currentComparisonIndex: Int = 0
    var numTotalComparisons: Int = 0
    var countIndex: Int = 0
    var type: String = ""
    var numObj: Int!
    var numSubsets: Int!
    var dateCreated: Date?
    var rankFinished: Bool = false
    
    var textArray: [String] = [] // will hold image names if image type
    var shuffledTexArray: [String] = []
    var nextGroup: [String] = []
    var finalRankTextArray: [String] = []
    
    var imageArrayData: [Data] = []
    var shuffledImageArrayData: [Data] = []
    var finalRankSmallSizeImageArrayData: [Data] = []
    var finalRankFullSizeImageArrayData: [Data] = []
    var nextImageGroupIndexes: [Int] = []
    
    var uniqueID: String?
    var creatorUniqueDeviceID: String?
    var publicRank: Bool = false
}

class RankInfoss: CKDataObject {
    var Username: [String] = []
    var Rankname: String = ""
    var RankType: String = ""
    var NumObj: Int = 0
    var numSubsets: Int = 0
    var textArray: [String] = [] // will hold image names if image type for compilation purposes
    var imageArray: [CKAsset] = [] 
    
    var result: [CKAsset] = []
    var showPublic: Bool = true
    var uniqueID: String = ""
    var uniqueDeviceID: [String] = []
}


public extension CKAsset {
    public func image() -> UIImage? {
        if let data = try? Data(contentsOf: self.fileURL) {
            return UIImage(data: data)
        }
        return nil
    }
    
}
