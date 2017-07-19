//
//  EditProfileVC.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 17/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import UIKit

class EditProfileVC: UIViewController {

    @IBOutlet weak var cancelButton: UIBarButtonItem!{
        didSet{
            cancelButton.target = self
            cancelButton.action = #selector(didTappedCancelButton(_:))
        }
    }
    
    @IBOutlet weak var naviBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //naviBar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 64)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didTappedCancelButton(_ sender: Any){
        dismiss(animated: true, completion: nil)
    }
    
}
