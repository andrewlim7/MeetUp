//
//  RegisterVC.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 17/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class RegisterVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var uploadImageButton: UIButton!{
        didSet{
            uploadImageButton.addTarget(self, action: #selector(didTappedUploadButton(_:)), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var nameTextField: UITextField!{
        didSet{
            nameTextField.delegate = self
        }
    }
    
    @IBOutlet weak var emailTextField: UITextField!{
        didSet{
            emailTextField.delegate = self
        }
    }
    
    @IBOutlet weak var passwordTextField: UITextField!{
        didSet{
            passwordTextField.isSecureTextEntry = true
            passwordTextField.delegate = self
        }
    }
    
    @IBOutlet weak var confirmPasswordTextField: UITextField!{
        didSet{
            confirmPasswordTextField.isSecureTextEntry = true
            confirmPasswordTextField.delegate = self
        }
    }
    
    @IBOutlet weak var signUpButton: UIButton!{
        didSet{
            signUpButton.addTarget(self, action: #selector(didTappedSignUpButton(_:)), for: .touchUpInside)
            signUpButton.layer.cornerRadius = 5
        }
    }

    let myActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    var isImageSelected : Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSpinner()
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        imageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(RegisterVC.imagedTapped(sender:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tapGestureRecognizer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y += keyboardSize.height
            }
        }
        
    }
    
    func imagedTapped(sender: UITapGestureRecognizer){
        openImagePicker()
    }
    
    func didTappedUploadButton(_ sender : Any){
        openImagePicker()
    }

    func didTappedSignUpButton(_ sender: Any){
        myActivityIndicator.startAnimating()
        
        guard
            let name = nameTextField.text,
            let email = emailTextField.text,
            let password = passwordTextField.text,
            let confirmPassword = confirmPasswordTextField.text
            else { return }
        
        if name == "" {
            warningAlert(warningMessage: "Please enter your username")
            
        } else if password == "" {
            warningAlert(warningMessage: "Please enter your password")
            
        } else if password.characters.count < 6  {
            warningAlert(warningMessage: "Please enter minimum of 6 characters for password")
            
        } else if email == "" {
            warningAlert(warningMessage: "Please enter your email")
            
        } else if password != confirmPassword {
            warningAlert(warningMessage: "Please enter your password and confirm password correctly!")
            
        } else if isImageSelected == false {
            warningAlert(warningMessage: "Please select profile picture!")
            
        } else {
            
            Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                if let validError = error {
                    print(validError.localizedDescription)
                    self.warningAlert(warningMessage: "Please enter another email address!")
                    return;
                }
                
                guard let uid = Auth.auth().currentUser?.uid else {return}
                
                let storageRef = Storage.storage().reference()
                
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpg"
                
                let data = UIImageJPEGRepresentation(self.imageView.image!, 0.8)
                
                storageRef.child("\(uid).jpg").putData(data!, metadata: metadata) { (newMeta, error) in
                    if (error != nil) {
                        // Uh-oh, an error occurred!
                        print(error!)
                    } else {
                        
                        defer{
                            self.dismiss(animated: true, completion: nil) //so the return function will return this
                        }
                        
                        if let foundError = error {
                            print(foundError.localizedDescription)
                            return
                        }
                        
                        guard let imageURL = newMeta?.downloadURLs?.first?.absoluteString else {
                            return
                        }
                        
                        let param : [String : Any] = ["name": name,
                                                      "email": email,
                                                      "profileImageURL": imageURL,
                                                      "provider": "email"]
                        
                        let ref = Database.database().reference().child("users")
                        ref.child(uid).setValue(param)
                    }
                }
                
                self.myActivityIndicator.stopAnimating()
                
                print("User sign-up successfully! \(user?.uid ?? "")")
                print("User email address! \(user?.email ?? "")")
                print("Username is \(name)")
            })
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            emailTextField.becomeFirstResponder()
        } else if textField == emailTextField{
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField{
            confirmPasswordTextField.becomeFirstResponder()
        } else if textField == confirmPasswordTextField{
            confirmPasswordTextField.resignFirstResponder()
            confirmPasswordTextField.returnKeyType = .done
        }
        return true
    }
    
    func setupSpinner(){
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.color = UIColor(red:0.25, green:0.72, blue:0.85, alpha:1.0)
        
        
        view.addSubview(myActivityIndicator)
    }
    
    func warningAlert(warningMessage: String){
        let alertController = UIAlertController(title: "Error", message: warningMessage, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alertController.addAction(ok)
        
        present(alertController, animated: true, completion: nil)
        self.myActivityIndicator.stopAnimating()
    }
    
    func openImagePicker(){
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        
        let alertController = UIAlertController(title: "Photo Source", message: "Choose a source", preferredStyle: .actionSheet)
        
        let camera = UIAlertAction(title: "Camera", style: .default) { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                pickerController.sourceType = .camera
                self.present(pickerController, animated: true, completion: nil)
            } else {
                let alertVC = UIAlertController(title: "No Camera",message: "Sorry, this device has no camera",preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok",style:.default,handler: nil)
                alertVC.addAction(okAction)
                self.present(alertVC, animated: true,completion: nil)
                return
            }
        }
        
        let photoLibrary = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            pickerController.sourceType = .photoLibrary
            self.present(pickerController, animated: true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(camera)
        alertController.addAction(photoLibrary)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

}

extension RegisterVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { //cancel button in photo
        self.isImageSelected = false
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        self.imageView.image = selectedImage
        
        self.isImageSelected = true
        
        dismiss(animated: true, completion: nil)
        
    }
}
