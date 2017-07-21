//
//  LoginVC.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 17/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FBSDKLoginKit

class LoginVC: UIViewController, UITextFieldDelegate, FBSDKLoginButtonDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!{
        didSet{
            emailTextField.delegate = self
        }
    }
    
    @IBOutlet weak var passwordTextField: UITextField!{
        didSet{
            passwordTextField.isSecureTextEntry = true
            passwordTextField.delegate = self
            passwordTextField.returnKeyType = .done
        }
    }
    
    @IBOutlet weak var loginButton: UIButton!{
        didSet{
            loginButton.addTarget(self, action: #selector(didTappedLoginButton(_:)), for: .touchUpInside)
            loginButton.layer.cornerRadius = 5.0
        }
    }
    
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!{
        didSet{
            fbLoginButton.delegate = self
        }
    }
    
    @IBOutlet weak var signUpButton: UIButton!{
        didSet{
            signUpButton.addTarget(self, action: #selector(didTappedRegisterButton(_:)), for: .touchUpInside)
        }
    }
    
    let myActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSpinner()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func didTappedLoginButton(_ sender : Any){
        myActivityIndicator.startAnimating()
        
        guard
            let email = emailTextField.text,
            let password = passwordTextField.text
            else {
                return
        }
        
        if emailTextField.text == ""{
            self.warningAlert(warningMessage: "Please enter your email")
            
        } else if password == "" || password.characters.count < 6 {
            self.warningAlert(warningMessage: "Please enter your password")
            
        } else {
            Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                if let validError = error {
                    print(validError.localizedDescription)
                    self.warningAlert(warningMessage: "Please enter your email or password correctly!")
                    return;
                }
                
                print("User exist \(user?.uid ?? "")")
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let mainVC = storyboard.instantiateViewController(withIdentifier: "MainVC")
                self.present(mainVC, animated: true, completion: nil)
                self.myActivityIndicator.stopAnimating()
                self.emailTextField.text = nil
                self.passwordTextField.text = nil
            })
        }
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            
            print(error.localizedDescription)
            warningAlert(warningMessage: "Please try again")
            return
            
        } else if (result.isCancelled == true){
            
            print("Cancelled")
            
        } else {
            
            let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            Auth.auth().signIn(with: credential, completion: { (user, error) in
                print("user logged in the firebase")
                
                let ref = Database.database().reference(fromURL: "https://meetupfinalassessment.firebaseio.com/")
                
                guard let uid = user?.uid else {
                    return
                }
                
                let userReference = ref.child("users").child(uid)
                
                let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id,name,email"])
                graphRequest.start(completionHandler: { (connection, result, error) in
                    if error != nil {
                        print("\(String(describing: error))")
                    } else {
                        let values : [String: Any] = result as! [String : Any]
                        
                        userReference.updateChildValues(values, withCompletionBlock: { (error, ref) in
                            if error != nil {
                                print("\(String(describing: error))")
                                return
                            }
                            
                            // no error, so it means we've saved the user into our firebase database successfully
                            print("Save the user successfully into Firebase database")
                        })
                    }
                })
                
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let mainVC = storyboard.instantiateViewController(withIdentifier: "TabBarNavi")
                self.present(mainVC, animated: true, completion: nil)
            })
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Facebook logout successfully!")
        warningAlert(warningMessage: "Facebook logout successfully!")
    }
    
    func didTappedRegisterButton(_ sender : Any){
        let storyboard = UIStoryboard(name: "Auth", bundle: Bundle.main)
        let registerVC = storyboard.instantiateViewController(withIdentifier: "RegisterVC")
        self.navigationController?.pushViewController(registerVC, animated: true)
    }
    
    func setupSpinner(){
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.color = UIColor(red:0.25, green:0.72, blue:0.85, alpha:1.0)
        view.addSubview(myActivityIndicator)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField{
            passwordTextField.resignFirstResponder()
        }
        return true
    }
    
    func warningAlert(warningMessage: String){
        let alertController = UIAlertController(title: "Error", message: warningMessage, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alertController.addAction(ok)
        
        present(alertController, animated: true, completion: nil)
        self.myActivityIndicator.stopAnimating()
    }
}
