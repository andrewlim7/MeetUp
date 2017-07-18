//
//  ProfileVC.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 17/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import UIKit
import FirebaseAuth
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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
