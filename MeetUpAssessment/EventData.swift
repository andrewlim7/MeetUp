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
    var eventTitle : String
    var eventDescription : String?
    var eventStartAt: String
    var eventEndAt: String
    var imageURL: URL?
    var eventCategory : String
    var address : String?
    var lat : Double?
    var long : Double?
    var participants : [String:Any]?
    
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
            let validCategory = dictionary["eventCategory"] as? String
        else { return nil }
        
        name = validName
        userID = validUserID
        timestamp = Date(timeIntervalSince1970: validTimestamp)
        eventTitle = validTitle
        eventDescription = validDescription
        eventStartAt = validStartAt
        eventEndAt = validEndAt
        eventCategory = validCategory
        
        
        if let validAddress = dictionary["locationAddress"] as? String{
            address = validAddress
        }
        
        if let validLat = dictionary["lat"] as? Double{
            lat = validLat
        }
        
        if let validLong = dictionary["long"] as? Double{
            long = validLong
        }
    
        if let validImageURL = dictionary["imageURL"] as? String{
            imageURL = URL(string: validImageURL)
        }
        
        if let validParticipants = dictionary["participants"] as? [String: Any] {
            participants = validParticipants
        }
    }
    
    
    
}
