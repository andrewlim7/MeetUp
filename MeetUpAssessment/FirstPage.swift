//
//  FirstPage.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 21/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import UIKit

class FirstPage: UIViewController {
    @IBOutlet weak var signUpButton: UIButton!{
        didSet{
            signUpButton.addTarget(self, action: #selector(didTappedSignUpButton(_:)), for: .touchUpInside)
            signUpButton.layer.cornerRadius = 20.0
        }
    }

    @IBOutlet weak var loginButton: UIButton!{
        didSet{
            loginButton.addTarget(self, action: #selector(didTappedLoginButton(_:)), for: .touchUpInside)
            loginButton.layer.cornerRadius = 20.0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    func didTappedSignUpButton(_ sender:Any){
        let storyboard = UIStoryboard(name: "Auth", bundle: Bundle.main)
        let registerVC = storyboard.instantiateViewController(withIdentifier: "RegisterVC")
        self.navigationController?.pushViewController(registerVC, animated: true)
    }
    
    func didTappedLoginButton(_ sender:Any){
        let storyboard = UIStoryboard(name: "Auth", bundle: Bundle.main)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC")
        self.navigationController?.pushViewController(loginVC, animated: true)
    }
    
    

}
