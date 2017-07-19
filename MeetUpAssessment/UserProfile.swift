//
//  UserProfile.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 17/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class UserProfile{
    
    var userID : String
    var name: String?
    var email: String?
    var profileImageURL : URL?
    var provider : String?
    var facebookID : String?
    var eventCreated : [String:Any]?
    var eventJoined : [String:Any]?
    
    init?(snapshot: DataSnapshot){
        
        self.userID = snapshot.key
        
        guard
            let dictionary = snapshot.value as? [String:Any],
            let validName = dictionary["name"] as? String
            else { return nil }
        
        name = validName
        
        if let validEmail = dictionary["email"] as? String {
            email = validEmail
        }
        
        if let validFID = dictionary["id"] as? String {
            facebookID = validFID
        }
        
        if let validImageURL = dictionary["profileImageURL"] as? String{ 
            profileImageURL = URL(string: validImageURL)
        }
        
        if let validEventCreated = dictionary["eventCreated"] as? [String:Any] {
            eventCreated = validEventCreated
        }
        
        if let validEventJoined = dictionary["eventJoined"] as? [String:Any]{
            eventJoined = validEventJoined
        }
        
        if let validProvider = Auth.auth().currentUser?.providerData{
            for item in validProvider{
                provider = item.providerID
            }
        }
        

        
    }
}
