//
//  ProfileVC.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 17/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FBSDKLoginKit

class ProfileVC: UIViewController {
    
    @IBOutlet weak var settingButton: UIButton!{
        didSet{
            settingButton.addTarget(self, action: #selector(didTappedSettingButton(_:)), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var editButton: UIButton!{
        didSet{
            editButton.addTarget(self, action: #selector(didTappedEditButton(_:)), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var providerLabel: UILabel!
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    var displayUserDetail : UserProfile?
    var displayUserEvent : [EventData] = []
//    var currentUserID = Auth.auth().currentUser?.uid

    override func viewDidLoad() {
        super.viewDidLoad()
        
//    var provider = Auth.auth().currentUser?.providerID
//        print(provider)
        fetchEvents()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchEvents(){
        
        if let currentUserID = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("users").child(currentUserID).observe(.value, with: { (snapshot) in
                
//                guard let dictionary = snapshot.value as? [String:Any] else {
//                    return
//                }
//                
//                let name = dictionary["name"] as? String
//                let email = dictionary["email"] as? String
//                let provider = dictionary["provider"] as? String
////                let profileImageURL = dictionary["profileImageURL"] as? String
//                
//                if let profileURL = dictionary["profileImageURL"] as? String {
//                    let displayUrl = NSURL(string : profileURL)
//                    
//                    self.imageView.sd_setImage(with: displayUrl! as URL)
//                }
//                
//                if let fbProfileID = dictionary["id"] as? String {
//                    
//                    let fbProfileURL = NSURL(string: "https://graph.facebook.com/\(fbProfileID)/picture?type=large&return_ssl_resources=1")
//                    
//                    self.imageView.sd_setImage(with: fbProfileURL! as URL)
//                }
//
//                self.nameLabel.text = name
//                self.emailLabel.text = email
//                self.providerLabel.text = provider
//
//                
//                //self.displayUserEvent = []
//                
//                guard let eventDictionary = dictionary["event"] as? [String : Any] else {return}
//
//                for (key,_) in eventDictionary {
//                    self.getEvent(key)
//                }
                
                
                if let userProfile = UserProfile(snapshot: snapshot){

                    self.nameLabel.text = userProfile.name
                    self.emailLabel.text = userProfile.email
                    self.providerLabel.text = userProfile.provider
                    
                    if let profileURL = userProfile.profileImageURL {
                        self.imageView.sd_setImage(with: profileURL as URL)
                    }
                    
                    if let fbProfileID = userProfile.facebookID {
                        
                        let fbProfileURL = NSURL(string: "https://graph.facebook.com/\(fbProfileID)/picture?type=large&return_ssl_resources=1")
                        
                        self.imageView.sd_setImage(with: fbProfileURL! as URL)
                    }
                    
                    guard let eventDictionary = userProfile.event else {return}
                    
                    self.displayUserEvent = []
                    
                    for (key,_) in eventDictionary {
                        self.getEvent(key)
                    }
                }
            })
            
        }
        
        
    }
    
    func getEvent(_ eventID: String) {
        
        let ref = Database.database().reference()
        ref.child("events").child(eventID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let eventDetail = EventData(snapshot: snapshot){
                self.displayUserEvent.append(eventDetail)
                self.displayUserEvent.sort(by: {$0.timestamp > $1.timestamp})
                self.tableView.reloadData()
            }
        })
        
        
    }
    
    func didTappedEditButton(_ sender : Any){
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let editProfileVC = storyboard.instantiateViewController(withIdentifier: "EditProfileVC") as? EditProfileVC else { return }
        
        present(editProfileVC, animated: true, completion: nil)
    }

    func didTappedSettingButton(_ sender : Any){
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let signOut = UIAlertAction(title: "Log Out", style: .destructive) { (action) in
            let firebaseAuth = Auth.auth()
            let loginManager = FBSDKLoginManager() //FB system logout
            
            do {
                try firebaseAuth.signOut()
                loginManager.logOut()
                
                print ("Logged out successfully!")
                
            } catch let signOutError as NSError {
                
                print ("Error signing out: %@", signOutError)
                return
            }
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(signOut)
        alertController.addAction(cancel)
        
        present(alertController, animated: true, completion: nil)
        
    }

}

extension ProfileVC : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayUserEvent.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentRow = displayUserEvent[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserCell
        
        
        cell.cellTitleLabel.text = currentRow.title
        cell.cellDescriptionLabel.text = currentRow.description
        cell.cellImageView.sd_setImage(with: currentRow.imageURL)
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

