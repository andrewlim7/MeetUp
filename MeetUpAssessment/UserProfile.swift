//
//  UserProfile.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 17/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import Foundation
import FirebaseDatabase

class UserProfile{
    
    var userID : String?
    var name: String?
    var email: String?
    var profileImageURL : URL?
    var provider : String?
    var facebookID : String?
    var event : [String:Any]?
    
    init?(snapshot: DataSnapshot){
        
        self.userID = snapshot.key
        
        guard
            let dictionary = snapshot.value as? [String:Any],
            let validName = dictionary["name"] as? String,
            let validUserID = dictionary["userID"] as? String,
            let validEmail = dictionary["email"] as? String,
            let validProvider = dictionary["provider"] as? String,
            let validFID = dictionary["id"] as? String,
            let validEvent = dictionary["event"] as? [String:Any]
            else { return nil }
        
        name = validName
        userID = validUserID
        email = validEmail
        provider = validProvider
        facebookID = validFID
        event = validEvent
    
        if let validImageURL = dictionary["profileImageURL"] as? String{
            profileImageURL = URL(string: validImageURL)
        }
        
    }
    
    
    
    
}
