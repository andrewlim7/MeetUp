//
//  EventData.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 18/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import Foundation
import FirebaseDatabase

class EventData {
    
    var eid : String
    var name : String
    var userID : String
    var timestamp : Date
    var title : String
    var description : String
    var startAt: String
    var endAt: String
    var imageURL: URL?
    var category : String
    var lat : Double
    var long : Double
    
    init?(snapshot: DataSnapshot){
        
        self.eid = snapshot.key
        
        guard
            let dictionary = snapshot.value as? [String:Any],
            let validName = dictionary["name"] as? String,
            let validUserID = dictionary["userID"] as? String,
            let validTimestamp = dictionary["timestamp"] as? Double,
            let validTitle = dictionary["eventTitle"] as? String,
            let validDescription = dictionary["eventDescription"] as? String,
            let validStartAt = dictionary["eventStartAt"] as? String,
            let validEndAt = dictionary["eventEndAt"] as? String,
            let validCategory = dictionary["eventCategory"] as? String,
            let validLat = dictionary["lat"] as? Double,
            let validLong = dictionary["long"] as? Double
        else { return nil }
        
        name = validName
        userID = validUserID
        timestamp = Date(timeIntervalSince1970: validTimestamp)
        title = validTitle
        description = validDescription
        startAt = validStartAt
        endAt = validEndAt
        category = validCategory
        lat = validLat
        long = validLong
        
        if let validImageURL = dictionary["imageURL"] as? String{
            imageURL = URL(string: validImageURL)
        }
        
    }
    
    
    
}
