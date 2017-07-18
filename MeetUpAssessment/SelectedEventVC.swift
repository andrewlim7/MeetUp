//
//  SelectedEventVC.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 18/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import UIKit

class SelectedEventVC: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var joinButton: UIButton!

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var startAtLabel: UILabel!

    @IBOutlet weak var endAtLabel: UILabel!
    @IBOutlet weak var HostedByLabel: UILabel!

    @IBOutlet weak var descriptionLabel: UILabel!
    
    var getEventDetail : EventData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        titleLabel.text = getEventDetail?.title
        descriptionLabel.text = getEventDetail?.description
        startAtLabel.text = getEventDetail?.startAt
        endAtLabel.text = getEventDetail?.endAt
        HostedByLabel.text = "Hosted by \(getEventDetail?.name ?? "")"
        imageView.sd_setImage(with: getEventDetail?.imageURL)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    
}
