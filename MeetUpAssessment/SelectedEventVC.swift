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

    @IBOutlet weak var dateLabel: UILabel!
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
    
    var getEventDetail : EventData?
    var isJoined : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = getEventDetail?.title
        descriptionLabel.text = getEventDetail?.description
        startAtLabel.text = getEventDetail?.startAt
        endAtLabel.text = getEventDetail?.endAt
        HostedByLabel.text = "Hosted by \(getEventDetail?.name ?? "")"
        imageView.sd_setImage(with: getEventDetail?.imageURL)
        locationLabel.text = getEventDetail?.address
        
        
        let destination = MKPointAnnotation()
        destination.coordinate = CLLocationCoordinate2DMake((getEventDetail?.lat)!, (getEventDetail?.long)!)
        destination.title = getEventDetail?.address
        mapView.addAnnotation(destination)
        
        let span = MKCoordinateSpanMake(0.03, 0.03)
        let region = MKCoordinateRegionMake(destination.coordinate, span)
        mapView.setRegion(region, animated: true)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func didTappedJoinButton(_ sender: Any){
        if isJoined == false {
            
            
            let ref = Database.database().reference().child("events").child("")
            
            let joiningRef = Database.database().reference().child("users")
            
            isJoined = true
            
            
        } else {
            
            
            isJoined = false
        }
    }
    
    
}

extension SelectedEventVC : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let annotationView = MKPinAnnotationView()
        annotationView.canShowCallout = true
        
        return annotationView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let coordinate = view.annotation?.coordinate else { return }
        
        let span = MKCoordinateSpanMake(0.03, 0.03)
        let region = MKCoordinateRegionMake(coordinate, span)
        mapView.setRegion(region, animated: true)
    }
    
}
