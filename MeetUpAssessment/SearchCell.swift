//
//  SearchCell.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 17/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import UIKit

class SearchCell: UITableViewCell {
    
    
    @IBOutlet weak var searchCellImageView: UIImageView!

    @IBOutlet weak var searchCellTitleLabel: UILabel!
    
    @IBOutlet weak var searchCellDescriptionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
