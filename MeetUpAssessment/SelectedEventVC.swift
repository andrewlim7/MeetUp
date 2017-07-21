//
//  SelectedEventVC.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 18/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseDatabase

class SelectedEventVC: UIViewController, EventDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var joinButton: UIButton!{
        didSet{
            joinButton.addTarget(self, action: #selector(didTappedJoinButton(_:)), for: .touchUpInside)
        }
    }

    @IBOutlet weak var startAtLabel: UILabel!

    @IBOutlet weak var endAtLabel: UILabel!
    @IBOutlet weak var HostedByLabel: UILabel!

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!{
        didSet{
            mapView.delegate = self
        }
    }
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var totalParticipantLabel: UILabel!
    
    var getEventDetail : EventData?
    var storeTempEventID : String?
    var isJoined : Bool = false
    var currentUserID = Auth.auth().currentUser?.uid
    let destination = MKPointAnnotation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if getEventDetail?.userID == currentUserID {
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(SelectedEventVC.editEvent))
        }
        
        joinButtonStatus()
        participantsCount()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
        
        if storeTempEventID == getEventDetail?.eid {
            
            let alertController = UIAlertController(title: "Error", message: "This event has removed", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default, handler: { (UIAlertAction) in
                self.navigationController?.popViewController(animated: true)
            })
            alertController.addAction(ok)
            
            present(alertController, animated: true, completion: nil)
            
        } else {
            mapView.removeAnnotation(destination)
            
            //to observe user's detail by providing the eventID
            let ref = Database.database().reference().child("events")
            ref.child((getEventDetail?.eid)!).observeSingleEvent(of: .value, with: { (snapshot) in
                if let data = EventData(snapshot: snapshot){
                    self.titleLabel.text = "Title: \(data.eventTitle )"
                    self.descriptionLabel.text = data.eventDescription
                    self.startAtLabel.text = "Event start at: \(data.eventStartAt )"
                    self.endAtLabel.text = "Event start at: \(data.eventEndAt )"
                    self.categoryLabel.text = "Category: \(data.eventCategory )"
                    self.HostedByLabel.text = "Hosted by \(data.name )"
                    self.imageView.sd_setImage(with: data.imageURL)
                    self.locationLabel.text = data.address
                    
                    if let coorLat = data.lat, let coorLong = data.long {
                        self.destination.coordinate = CLLocationCoordinate2DMake(coorLat, coorLong)
                        self.destination.title = data.address
                        self.mapView.addAnnotation(self.destination)
                    }
                    
                    let span = MKCoordinateSpanMake(0.03, 0.03)
                    let region = MKCoordinateRegionMake(self.destination.coordinate, span)
                    self.mapView.setRegion(region, animated: true)
                }
            })
       }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func participantsCount(){
        
        let ref = Database.database().reference()
        if let eventID = getEventDetail?.eid{
            ref.child("events").child(eventID).child("participants").observe(.value, with: { (snapshot) in
                
                var count = 0
                count += Int(snapshot.childrenCount)
                self.totalParticipantLabel.text = "\(count) participant(s) are going"
                
            })
        }
    }

    
    func editEvent(){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "AddVC") as! AddVC
        nextVC.delegate = self
        
        nextVC.getEditEventDetail = getEventDetail
        
        present(nextVC, animated: true, completion: nil)
    }
    
    func joinButtonStatus(){
        let ref = Database.database().reference()
        
        if let eventID = getEventDetail?.eid {
            ref.child("events").child(eventID).child("participants").observe(.value, with: { (snapshot) in
                if let uid = self.currentUserID {
                    if snapshot.hasChild(uid){
                        self.joinButton.setTitle("Joined", for: .normal)
                        self.joinButton.backgroundColor = UIColor.red
                        self.isJoined = true
                    } else {
                        self.joinButton.setTitle("Join", for: .normal)
                        self.joinButton.backgroundColor = UIColor.green
                    }
                }
            })
        }
    }

    func didTappedJoinButton(_ sender: Any){
        if isJoined == false {
            
            if let eventID = getEventDetail?.eid {
                let ref = Database.database().reference().child("events").child(eventID).child("participants")
                ref.updateChildValues([currentUserID!: true])
        
                let userRef = Database.database().reference().child("users").child(currentUserID!).child("eventJoined")
                userRef.updateChildValues([eventID: true])
                
                isJoined = true
            }
            
        } else {
            
            if let eventID = getEventDetail?.eid {
                
                if let uid = self.currentUserID {
                    let ref = Database.database().reference().child("events").child(eventID).child("participants")
                    ref.child(uid).removeValue()
                    
                    let userRef = Database.database().reference().child("users").child(uid).child("eventJoined")
                    userRef.child(eventID).removeValue()
                    
                    isJoined = false
                }
            }
        }
    }
    
    func refreshDeletedEvent(eventID: String) {
        storeTempEventID = eventID
        dismiss(animated: true, completion: nil)
    }
    
}

extension SelectedEventVC : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let pinIdentifier = "pin"
        
        let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: pinIdentifier)
        if pinView == nil {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: pinIdentifier)
            pinView.canShowCallout = true
            
            return pinView
            
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let coordinate = view.annotation?.coordinate else { return }
        
        let span = MKCoordinateSpanMake(0.03, 0.03)
        let region = MKCoordinateRegionMake(coordinate, span)
        mapView.setRegion(region, animated: true)
    }
    
}
