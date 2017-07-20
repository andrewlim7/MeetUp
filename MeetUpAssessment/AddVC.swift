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
    
    @IBOutlet weak var naviBar: UINavigationBar!
    
    let myActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    let currentUserID = Auth.auth().currentUser?.uid
    var getName : String = ""
    var isImageSelected : Bool = false
    var isImageUpdated : Bool = false
    let ref = Database.database().reference()
    let locationManager = CLLocationManager()
    let selfAnnotation = MKPointAnnotation()
    var selectedAnnotation = MKPointAnnotation()
    let destination = MKPointAnnotation() 
    var locationAddress : String?
    var getLocationLat : Double?
    var getLocationLong : Double?
    var getEditEventDetail : EventData?
    let datePicker = UIDatePicker()
    var selectedRow = 0 //for pickerview row
    let picker = UIPickerView() //programmatically program pickerview
    let pickerArray = ["Outdoors & Adventure","Tech","Family","Health & Wellness","Sport & Fitness","Learning",
                       "Photography","Food & Drink","Writing","Language & Culture","Music","Movements","Film",
                       "Games","Beliefs", "Arts","Normal Gathering","Book Clubs","Pets","Dance","Career & Business","Social","Fashion & Beauty","Hobbies"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSpinner()
        showStartDatePicker()
        showEndDatePicker()
        getNameFromDB()
        displayPickerView()
        
        picker.delegate = self
        picker.dataSource = self
        
        
        imageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AddVC.imagedTapped(sender:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tapGestureRecognizer)
        
        if getEditEventDetail == nil {
            determineCurrentLocation()
            
        } else {
            naviBar.items?.first?.title = "Edit event detail"
            
            naviBar?.items?.first?.rightBarButtonItem = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(AddVC.deleteEvent))
            
            titleTextField.text = getEditEventDetail?.eventTitle
            descriptionTextField.text = getEditEventDetail?.eventDescription
            startAtTextField.text = getEditEventDetail?.eventStartAt
            endAtTextField.text = getEditEventDetail?.eventEndAt
            categoryTextField.text = getEditEventDetail?.eventCategory
            imageView.sd_setImage(with: getEditEventDetail?.imageURL)
            
            if let coorLat = getEditEventDetail?.lat, let coorLong = getEditEventDetail?.long {
                destination.coordinate = CLLocationCoordinate2DMake(coorLat, coorLong)
                destination.title = getEditEventDetail?.address
                mapView.addAnnotation(destination)
            }
        
            
            let span = MKCoordinateSpanMake(0.03, 0.03)
            let region = MKCoordinateRegionMake(destination.coordinate, span)
            mapView.setRegion(region, animated: true)
            
            doneButton.setTitle("Update", for: .normal)
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func showStartDatePicker(){
        //Formate Date
        datePicker.datePickerMode = .dateAndTime
        datePicker.backgroundColor = .white
        
        //ToolBar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneStartDatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(cancelDatePicker))
        
        toolbar.setItems([doneButton,spaceButton,cancelButton], animated: false)
        
        startAtTextField.inputAccessoryView = toolbar //input the white background accessory
        startAtTextField.inputView = datePicker
    }
    
    func showEndDatePicker(){
        
        //ToolBar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneEndDatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(cancelDatePicker))
        toolbar.setItems([doneButton,spaceButton,cancelButton], animated: false)
        
        endAtTextField.inputAccessoryView = toolbar
        endAtTextField.inputView = datePicker
    }
    
    func doneStartDatePicker(){
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE dd MMMM yyyy, h:mm a"
        startAtTextField.text = formatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
    
    func doneEndDatePicker(){
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE dd MMMM yyyy, h:mm a"
        endAtTextField.text = formatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
    
    func cancelDatePicker(){
        self.view.endEditing(true)
    }
    
    func deleteEvent(_ sender: Any){
        let alertController = UIAlertController(title: "Are you sure?", message: "You cannot retrieve this post after being deleted", preferredStyle: .alert)
        
        let delete = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            if let eventID = self.getEditEventDetail?.eid {
                let eventRef = Database.database().reference().child("events").child(eventID)
                eventRef.removeValue()
                
                if let currentUserID = self.getEditEventDetail?.userID {
                    let userRef = Database.database().reference().child("users").child(currentUserID).child("eventCreated")
                    userRef.removeValue()
                    
                    let userEventJoined = Database.database().reference().child("users").child(currentUserID).child("eventJoined")
                    userEventJoined.child(eventID).removeValue()
                }
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let mainVC = storyboard.instantiateViewController(withIdentifier: "MainVC") as! MainVC
            
            self.present(mainVC, animated: true, completion: nil)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(delete)
        alertController.addAction(cancel)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        titleTextField.resignFirstResponder()
        descriptionTextField.resignFirstResponder()
        startAtTextField.resignFirstResponder()
        endAtTextField.resignFirstResponder()
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
        imageView.image = nil
        categoryTextField.text = nil
    }
    
    func didTappedUploadImageButton(_ sender: Any){
        openImagePicker()
    }
    
    func didTappedDoneButton(_ sender: Any){
        myActivityIndicator.startAnimating()
        
        if doneButton.titleLabel?.text == "Done" {
            saveDetails()
        } else {
            // do updateDetails()
            
        }
        
    }
    
    func updateDetails(){
        
        if isImageSelected == false{
            
            warningAlert(warningMessage: "Please upload an event's image!")
            
        } else {
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
    }
    
    func updatePictureAndDetails(_ imageURL: String? = nil){
        guard
            let uid = currentUserID,
            let validTitle = titleTextField.text,
            let validDescription = descriptionTextField.text,
            let validStartAt = startAtTextField.text,
            let validEndAt = endAtTextField.text,
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
                                    "eventCategory" : validCategory,
                                    "imageURL": validImageURL,
                                    "timestamp": now.timeIntervalSince1970,
                                    "locationAddress": self.locationAddress ?? "",
                                    "lat": self.getLocationLat ?? "",
                                    "long": self.getLocationLong ?? ""]
        
        let ref = Database.database().reference().child("events")
        ref.child(uid).updateChildValues(param)
    }
    
    func saveDetails(){
        if titleTextField.text == "" {
            
            warningAlert(warningMessage: "Please insert the title!")
            
        } else if descriptionTextField.text == ""{
            
            warningAlert(warningMessage: "Please insert description!")
            
        } else if startAtTextField.text == ""{
            
            warningAlert(warningMessage: "Please insert event start date!")
            
        } else if endAtTextField.text == ""{
            
            warningAlert(warningMessage: "Please insert event end date!")
            
        } else if categoryTextField.text == ""{
            
            warningAlert(warningMessage: "Please insert category!")
            
        } else if isImageSelected == false{
            
            warningAlert(warningMessage: "Please upload an event's image!")
            
        } else {
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
    }
    
    func storePictureAndDetails(_ imageURL: String!){
        
        guard
            let uid = currentUserID,
            let validTitle = titleTextField.text,
            let validDescription = descriptionTextField.text,
            let validStartAt = startAtTextField.text,
            let validEndAt = endAtTextField.text,
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
        
        let updateEventCreated = Database.database().reference().child("users").child(uid).child("eventCreated")
        updateEventCreated.updateChildValues([currentEID:true])
        
        let updateEventJoined = Database.database().reference().child("users").child(uid).child("eventJoined").child(currentEID)
        updateEventJoined.updateChildValues([uid:true])
        
        let updateEventParticipants = Database.database().reference().child("events").child(currentEID).child("participants")
        updateEventParticipants.updateChildValues([uid:true])
        
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
    
    func warningAlert(warningMessage: String){
        let alertController = UIAlertController(title: "Error", message: warningMessage, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alertController.addAction(ok)
        
        present(alertController, animated: true, completion: nil)
        self.myActivityIndicator.stopAnimating()
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
                
                //to update selectedAnnotation address on pin
                if let displayAddressOnPin = self.locationAddress {
                    self.selectedAnnotation.title = "\(displayAddressOnPin)"
                }
            }
        }
    }
    
    func displayPickerView(){
        let pickerView = picker
        pickerView.backgroundColor = .white
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(donePickerView))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(cancelPickerView))
        
        toolBar.setItems([doneButton, spaceButton, cancelButton], animated: false)
        
        categoryTextField.inputView = pickerView
        categoryTextField.inputAccessoryView = toolBar
    }

    func donePickerView(){
        categoryTextField.text = pickerArray[selectedRow]
        categoryTextField.resignFirstResponder()
    }
    
    func cancelPickerView(){
        categoryTextField.resignFirstResponder()
    }
    
}

extension AddVC : UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRow = row //for done button to get current row
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
        
        //get current location's coordinate
        guard let coor = locations.first?.coordinate
            else { return }
        
        selfAnnotation.coordinate = coor
        selfAnnotation.title = "Current Location"
        mapView.addAnnotation(selfAnnotation)
        
        //to store current location in database
        getLocationLat = selfAnnotation.coordinate.latitude
        getLocationLong = selfAnnotation.coordinate.longitude
        
        if let lat = getLocationLat, let long = getLocationLong {
            //loadPlaceMark will update the EventData's locationAddress
            let currentLocation = CLLocation(latitude: lat, longitude: long)
            self.loadPlaceMark(location: currentLocation)
        }

        let locValue : CLLocationCoordinate2D = coor
        let span = MKCoordinateSpanMake(0.03, 0.03)
        let region = MKCoordinateRegion(center: locValue, span: span)
        mapView.setRegion(region, animated: true)
        
    }
    
}

extension AddVC : MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        let pinIdentifier = "pin"
        
        let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: pinIdentifier)
        if pinView == nil {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: pinIdentifier)
            pinView.canShowCallout = true
            pinView.isDraggable = true
            
            return pinView
            
        } else {
            pinView?.annotation = annotation
        }
        
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
            
            let coordinates = CLLocation(latitude: lat, longitude: long)
            
            getLocationLat = lat
            getLocationLong = long

            self.loadPlaceMark(location: coordinates)
            
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

