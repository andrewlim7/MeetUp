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

class SelectedEventVC: UIViewController {
    
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
    
    var getEventDetail : EventData?
    var isJoined : Bool = false
    var currentUserID = Auth.auth().currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if getEventDetail?.userID == currentUserID {
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(SelectedEventVC.editEvent))
            
        }

        titleLabel.text = "Title: \(getEventDetail?.eventTitle ?? "")"
        descriptionLabel.text = getEventDetail?.eventDescription
        startAtLabel.text = "Event start at: \(getEventDetail?.eventStartAt ?? "")"
        endAtLabel.text = "Event start at: \(getEventDetail?.eventEndAt ?? "")"
        categoryLabel.text = "Category: \(getEventDetail?.eventCategory ?? "")"
        HostedByLabel.text = "Hosted by \(getEventDetail?.name ?? "")"
        imageView.sd_setImage(with: getEventDetail?.imageURL)
        locationLabel.text = getEventDetail?.address
        
        let destination = MKPointAnnotation()
        if let coorLat = getEventDetail?.lat, let coorLong = getEventDetail?.long {
            destination.coordinate = CLLocationCoordinate2DMake(coorLat, coorLong)
            destination.title = getEventDetail?.address
            mapView.addAnnotation(destination)
        }
        
        let span = MKCoordinateSpanMake(0.03, 0.03)
        let region = MKCoordinateRegionMake(destination.coordinate, span)
        mapView.setRegion(region, animated: true)
        
        joinButtonStatus()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func editEvent(){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "AddVC") as! AddVC
        
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
                //rmb to do uid = currentUserID
                let ref = Database.database().reference().child("events").child(eventID).child("participants")
                ref.updateChildValues([currentUserID!: true])
                
                let userRef = Database.database().reference().child("users").child(currentUserID!).child("eventJoined").child(eventID)
                userRef.updateChildValues([currentUserID!: true])
                
                isJoined = true
            }
        } else {
            
            if let eventID = getEventDetail?.eid {
                
                if let uid = self.currentUserID {
                    let ref = Database.database().reference().child("events").child(eventID).child("participants")
                    ref.child(uid).removeValue()
                    
                    let userRef = Database.database().reference().child("users").child(uid).child("eventJoined").child(eventID)
                    userRef.child(uid).removeValue()
                    
                    isJoined = false
                }
            }
        }
    }
    
}

extension SelectedEventVC : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let pinView = MKPinAnnotationView()
        pinView.annotation = annotation
        
        pinView.canShowCallout = true
        pinView.isDraggable = true
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let coordinate = view.annotation?.coordinate else { return }
        
        let span = MKCoordinateSpanMake(0.03, 0.03)
        let region = MKCoordinateRegionMake(coordinate, span)
        mapView.setRegion(region, animated: true)
    }
    
}
