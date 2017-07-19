//
//  AddVC.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 17/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class AddVC: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var cancelButton: UIBarButtonItem!{
        didSet{
            cancelButton.target = self
            cancelButton.action = #selector(didTappedCancelButton(_:))
        }
    }
    
    @IBOutlet weak var mapView: MKMapView!{
        didSet{
            mapView.delegate = self
        }
    }
    
    @IBOutlet weak var titleTextField: UITextField!{
        didSet{
            titleTextField.delegate = self
        }
    }
    @IBOutlet weak var descriptionTextField: UITextField!{
        didSet{
            descriptionTextField.delegate = self
        }
    }
    
    @IBOutlet weak var startAtTextField: UITextField!{
        didSet{
            startAtTextField.delegate = self
        }
    }
    @IBOutlet weak var endAtTextField: UITextField!{
        didSet{
            endAtTextField.delegate = self
        }
    }
    @IBOutlet weak var dateTextField: UITextField!{
        didSet{
            dateTextField.delegate = self
        }
    }
    @IBOutlet weak var categoryTextField: UITextField!{
        didSet{
            categoryTextField.delegate = self
        }
    }
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var uploadImageButton: UIButton!{
        didSet{
            uploadImageButton.addTarget(self, action: #selector(didTappedUploadImageButton(_:)), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var doneButton: UIButton!{
        didSet{
            doneButton.addTarget(self, action: #selector(didTappedDoneButton(_:)), for: .touchUpInside)
        }
    }
    
    let myActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    let currentUserID = Auth.auth().currentUser?.uid
    var getName : String = ""
    var isImageSelected : Bool = false
    let ref = Database.database().reference()
    let locationManager = CLLocationManager()
    let selfAnnotation = MKPointAnnotation()
    var selectedAnnotation = MKPointAnnotation()
    var locationAddress : String?
    var getLocationLat : Double?
    var getLocationLong : Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSpinner()
        getNameFromDB()
        
        determineCurrentLocation()
        
        imageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AddVC.imagedTapped(sender:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tapGestureRecognizer)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        titleTextField.resignFirstResponder()
        descriptionTextField.resignFirstResponder()
        startAtTextField.resignFirstResponder()
        endAtTextField.resignFirstResponder()
        dateTextField.resignFirstResponder()
        categoryTextField.resignFirstResponder()
        return true
    }
    
    func imagedTapped(sender: UIGestureRecognizer){
        openImagePicker()
    }
    
    func getNameFromDB(){
        if let uid = currentUserID {
            ref.child("users").child(uid).observe(.value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String:Any],
                    let name = dictionary["name"] as? String {
                    self.getName = name
                }
            })
        }
    }
    
    func determineCurrentLocation(){
        
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled(){
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
    }
    
    func didTappedCancelButton(_ sender: Any){
        dismiss(animated: true, completion: nil)
        
        titleTextField.text = nil
        descriptionTextField.text = nil
        startAtTextField.text = nil
        endAtTextField.text = nil
        dateTextField.text = nil
        imageView.image = nil
        categoryTextField.text = nil
    }
    
    func didTappedUploadImageButton(_ sender: Any){
        openImagePicker()
    }
    
    func didTappedDoneButton(_ sender: Any){
        myActivityIndicator.startAnimating()
        
        let storageRef = Storage.storage().reference()
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        
        guard let data = UIImageJPEGRepresentation(imageView.image!, 0.8) else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        let uuid = UUID().uuidString
        print(uuid)
        
        storageRef.child("\(uuid).jpg").putData(data, metadata: metadata) { (newMeta, error) in
            if error != nil {
                print(error!)
            } else {
                defer{
                    self.dismiss(animated: true, completion: nil) //dismiss the view when done.
                }
                
                if let foundError = error {
                    print(foundError.localizedDescription)
                    return
                }
                
                guard let imageURL = newMeta?.downloadURLs?.first?.absoluteString else {
                    return
                }
                
                self.storePictureAndDetails(imageURL) //pass in the imageURL in the function
            }
            self.myActivityIndicator.stopAnimating()
        }
    }
    
    func storePictureAndDetails(_ imageURL: String!){
        
        guard
            let uid = currentUserID,
            let validTitle = titleTextField.text,
            let validDescription = descriptionTextField.text,
            let validStartAt = startAtTextField.text,
            let validEndAt = endAtTextField.text,
            let validDate = dateTextField.text,
            let validImageURL = imageURL,
            let validCategory = categoryTextField.text
            else { return }
        
        let now = Date()
        let param : [String:Any] = ["userID" : uid,
                                    "name" : self.getName,
                                    "eventTitle" : validTitle,
                                    "eventDescription" : validDescription,
                                    "eventStartAt" : validStartAt,
                                    "eventEndAt" : validEndAt,
                                    "eventDate" : validDate,
                                    "eventCategory" : validCategory,
                                    "imageURL": validImageURL,
                                    "timestamp": now.timeIntervalSince1970,
                                    "locationAddress": self.locationAddress ?? "",
                                    "lat": self.getLocationLat ?? "",
                                    "long": self.getLocationLong ?? ""]
        
        let ref = Database.database().reference().child("events").childByAutoId()
        ref.setValue(param)
        
        let currentEID = ref.key
        print(currentEID)
        
        let updateUserPID = Database.database().reference().child("users").child(uid).child("event")
        updateUserPID.updateChildValues([currentEID: true])
        
    }
    
    func setupSpinner(){
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.color = UIColor(red:0.25, green:0.72, blue:0.85, alpha:1.0)
        myActivityIndicator.backgroundColor = UIColor.gray
        
        view.addSubview(myActivityIndicator)
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
    
    func loadPlaceMark(location : CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let validError = error{
                print("Geocode Error: \(validError.localizedDescription)")
            }
            
            
            if let placemark = placemarks?.first{
                var textArray : [String] = []
                for item in [placemark.name, placemark.thoroughfare, placemark.locality] {
                    if let name = item { textArray.append(name) }
                }
                
                let finalString = textArray.joined(separator: ", ")
                
                self.locationAddress = finalString
                print(finalString)
                
//                print(placemark.name ?? "")
//                print(placemark.thoroughfare ?? "")
//                print(placemark.locality ?? "")
            }
        }
    }

    
}

extension AddVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
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

extension AddVC : CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
        return
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        locationManager.stopUpdatingLocation()
        
        guard let coor = locations.first?.coordinate
            else { return }
        
        selfAnnotation.coordinate = coor
        selfAnnotation.title = "Current Location"
        mapView.addAnnotation(selfAnnotation)
        
        let locValue : CLLocationCoordinate2D = coor
        let span = MKCoordinateSpanMake(0.03, 0.03)
        let region = MKCoordinateRegion(center: locValue, span: span)
        mapView.setRegion(region, animated: true)
        
    }
    
}

extension AddVC : MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let pinView = MKPinAnnotationView()
        pinView.canShowCallout = true
        pinView.isDraggable = true
        
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        switch newState {
            
        case .starting:
            print("dragging")
        
        case .ending, .canceling:
            guard
                let lat = view.annotation?.coordinate.latitude,
                let long = view.annotation?.coordinate.longitude
            
            else { return }
            
            if let displayAddressOnPin = locationAddress {
                self.selectedAnnotation.title = "\(displayAddressOnPin)"
            } else {
                self.selectedAnnotation.title = "Selected Location"
            }
            
            let coordinates = CLLocation(latitude: lat, longitude: long)
            self.loadPlaceMark(location: coordinates)
            
            getLocationLat = lat
            getLocationLong = long
            
        default:
            break
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("Did Select")
        
        guard let centerCoor = view.annotation?.coordinate else { return }
        
        let span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        
        let region = MKCoordinateRegionMake(centerCoor, span)
        mapView.setRegion(region, animated: true)
        
        selectedAnnotation = view.annotation as! MKPointAnnotation
        
    }
}

