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
    @IBOutlet weak var providerImageView: UIImageView!
    
    
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
    
    var displayUserEventCreated : [EventData] = []
    var displayUserRSVP : [EventData] = []
    var providerStatus : String?
    var refresher = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkEditButtonStatus()
        
        refresher.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
        tableView.addSubview(refresher)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        
        if segmentControl.selectedSegmentIndex == 0 {
            displayUserEventCreated = []
            fetchEventsCreated()
            tableView.reloadData()
            
        } else {
            displayUserRSVP = []
            fetchRSVP()
            tableView.reloadData()
        }
    }
    
    func checkEditButtonStatus(){
        if let checkProvider = Auth.auth().currentUser?.providerData{
            for item in checkProvider{
                providerStatus = item.providerID
            }
        }
        
        if providerStatus == "facebook.com"{
            editButton.isHidden = true
            editButton.isEnabled = false
        }
    }
    
    func didTappedSegmentControl(_ sender:Any){
        switch segmentControl.selectedSegmentIndex
        {
        case 0:
            displayUserEventCreated = []
            fetchEventsCreated()
            tableView.reloadData()
        case 1:
            displayUserRSVP = []
            fetchRSVP()
            tableView.reloadData()
        default:
            break;
        }
    }
    
    func handleRefresh(){
        refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refresher.tintColor = UIColor(red:0.25, green:0.72, blue:0.85, alpha:1.0)
        let ref = Database.database().reference()
        ref.child("events").removeAllObservers()
        
        if segmentControl.selectedSegmentIndex == 0 {
            self.displayUserEventCreated = []
            fetchEventsCreated()
        } else {
            self.displayUserRSVP = []
            fetchRSVP()
        }
        refresher.endRefreshing()
        tableView.reloadData()
    }
    
    func fetchRSVP(){
        
        if let currentUserID = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("users").child(currentUserID).observeSingleEvent(of: .value, with: { (snapshot) in
                if let userRSVP = UserProfile(snapshot: snapshot){
                    
                    guard let eventJoined = userRSVP.eventJoined else { return }
                    
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
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    func fetchEventsCreated(){
        
        if let currentUserID = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("users").child(currentUserID).observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let userProfile = UserProfile(snapshot: snapshot){
                    
                    self.nameLabel.text = userProfile.name
                    self.emailLabel.text = userProfile.email
                    
                    if userProfile.provider == "facebook.com" {
                        self.providerImageView.image = UIImage(named: "facebook3")
                        
                    } else {
                        self.providerImageView.image = UIImage(named: "email")
                    }
                    
                    if let profileURL = userProfile.profileImageURL {
                        self.imageView.sd_setImage(with: profileURL as URL)
                    }
                    
                    if let fbProfileID = userProfile.facebookID {
                        
                        let fbProfileURL = NSURL(string: "https://graph.facebook.com/\(fbProfileID)/picture?type=large&return_ssl_resources=1")
                        
                        self.imageView.sd_setImage(with: fbProfileURL! as URL)
                    }
                    
                    guard let eventDictionary = userProfile.eventCreated else {return}
                    
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
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    func didTappedEditButton(_ sender : Any){
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let editProfileVC = storyboard.instantiateViewController(withIdentifier: "EditProfileVC") as! EditProfileVC
        
        editProfileVC.displayUserImage = imageView.image
        
        present(editProfileVC, animated: true, completion: nil)
    }
    
    func didTappedSettingButton(_ sender : Any){
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let signOut = UIAlertAction(title: "Log Out", style: .destructive) { (action) in
            let firebaseAuth = Auth.auth()
            let loginManager = FBSDKLoginManager()
            
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
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? UserCell else {
            return UITableViewCell()
        }
        
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

