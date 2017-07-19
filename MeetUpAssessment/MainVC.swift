//
//  MainVC.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 17/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import SDWebImage

class MainVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    @IBOutlet weak var addButton: UIBarButtonItem!{
        didSet{
            addButton.target = self
            addButton.action = #selector(didTappedAddButton(_:))
        }
    }
    
    var EventDetails : [EventData] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchEvent()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
    }
    
    func didTappedAddButton(_ sender : Any){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let addVC = storyboard.instantiateViewController(withIdentifier: "AddVC") as? AddVC else { return }
        
        present(addVC, animated: true, completion: nil)
    }
    
    func fetchEvent(){
        let ref = Database.database().reference()
        
        ref.child("events").observe(.childAdded, with: { (snapshot) in
            
            if let data = EventData(snapshot: snapshot){
                
                self.EventDetails.append(data)
                self.EventDetails.sort(by: {$0.timestamp > $1.timestamp})
            }
            
            self.tableView.reloadData()
        })
    }

}

extension MainVC : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return EventDetails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ListCell
            else { return UITableViewCell() }
        
        let currentRow = EventDetails[indexPath.row]
        
        
        cell.listTitleLabel.text = currentRow.eventTitle
        cell.listDescriptionLabel.text = currentRow.eventDescription
        
        cell.listImageView.sd_setImage(with: currentRow.imageURL)
        
        
        return cell
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "SelectedEventVC") as? SelectedEventVC
        
        let currentRow = EventDetails[indexPath.row]
        
        nextVC?.getEventDetail = currentRow
        
        self.navigationController?.pushViewController(nextVC!, animated: true)
        
    }
    
    
}
