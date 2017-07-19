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
    
    @IBOutlet weak var segmentControl: UISegmentedControl!{
        didSet{
            segmentControl.addTarget(self, action: #selector(didTappedSegmentControl(_:)), for: .valueChanged)
            segmentControl.selectedSegmentIndex = 0
        }
    }
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    var displayUserDetail : UserProfile?
    var displayUserEventCreated : [EventData] = []
    var displayUserRSVP : [EventData] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayUserEventCreated = []
        fetchEventsCreated()
        obeserveDelete()

    }
    
    func obeserveDelete() {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("users").child(uid).child("eventJoined").observe(.childRemoved, with: { (snapshot) in
                if let deletedIndex = self.displayUserRSVP.index(where: { (eventID) -> Bool in
                    eventID.eid == snapshot.key
                }) {
                    self.displayUserRSVP.remove(at: deletedIndex)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    
                } else {
                    return
                }
            })
        }
    }
    
    
    func didTappedSegmentControl(_ sender:Any){
        switch segmentControl.selectedSegmentIndex
        {
        case 0:
            displayUserEventCreated = []
            obeserveDelete()
            fetchEventsCreated()
            tableView.reloadData()
        case 1:
            displayUserRSVP = []
            obeserveDelete()
            fetchRSVP()
            tableView.reloadData()
        default:
            break;
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
    }
    
    func fetchRSVP(){
     
        if let currentUserID = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("users").child(currentUserID).observe(.value, with: { (snapshot) in
                if let userRSVP = UserProfile(snapshot: snapshot){
                    
                    guard let eventJoined = userRSVP.eventJoined else { return }
                    
                    self.displayUserRSVP = []
                    
                    for(key,_) in eventJoined {
                        
                        self.getRSVP(key)
                        
                    }
                }
            })
            
            
        }
        
    }
    
    func getRSVP(_ eventID: String) {
        let ref = Database.database().reference()
        ref.child("events").child(eventID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let rsvpDetail = EventData(snapshot: snapshot){
                self.displayUserRSVP.append(rsvpDetail)
                self.displayUserRSVP.sort(by: {$0.timestamp > $1.timestamp})
                self.tableView.reloadData()
            }
        })
    }
    
    func fetchEventsCreated(){
        
        if let currentUserID = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("users").child(currentUserID).observe(.value, with: { (snapshot) in

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
                    
                    guard let eventDictionary = userProfile.eventCreated else {return}
                    
                    self.displayUserEventCreated = []
                    
                    for (key,_) in eventDictionary {
                        self.getEvent(key)
                    }
                }
            }) { (error) in
                
                print(error.localizedDescription)
                
                return
            }
        }
    }
    
    func getEvent(_ eventID: String) {
        
        let ref = Database.database().reference()
        ref.child("events").child(eventID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let eventDetail = EventData(snapshot: snapshot){
                self.displayUserEventCreated.append(eventDetail)
                self.displayUserEventCreated.sort(by: {$0.timestamp > $1.timestamp})
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
        
        if segmentControl.selectedSegmentIndex == 0 {
            return displayUserEventCreated.count
        } else {
            return displayUserRSVP.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserCell
        
        if segmentControl.selectedSegmentIndex == 0 {
            let currentRow = displayUserEventCreated[indexPath.row]
            
            cell.cellTitleLabel.text = currentRow.eventTitle
            cell.cellDescriptionLabel.text = currentRow.eventDescription
            cell.cellImageView.sd_setImage(with: currentRow.imageURL)
            
            
            return cell
            
        } else {
            
            let currentRow = displayUserRSVP[indexPath.row]
            
            cell.cellTitleLabel.text = currentRow.eventTitle
            cell.cellDescriptionLabel.text = currentRow.eventDescription
            cell.cellImageView.sd_setImage(with: currentRow.imageURL)
            
            return cell
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "SelectedEventVC") as! SelectedEventVC
        
        if segmentControl.selectedSegmentIndex == 0 {
            let currentRow = displayUserEventCreated[indexPath.row]
            
            nextVC.getEventDetail = currentRow
            
            self.navigationController?.pushViewController(nextVC, animated: true)
            
        } else {
            
            let currentRow = displayUserRSVP[indexPath.row]
            
            nextVC.getEventDetail = currentRow
            
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
    }
}

