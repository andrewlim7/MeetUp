//
//  SearchVC.swift
//  MeetUpAssessment
//
//  Created by Andrew Lim on 17/07/2017.
//  Copyright © 2017 Andrew Lim. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class SearchVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    @IBOutlet weak var searchBar: UISearchBar!{
        didSet{
            searchBar.delegate = self
        }
    }
    
    var storeEventData : [EventData] = []
    var filteredEventData : [EventData] = []
    
    @IBOutlet weak var segmentControl: UISegmentedControl!{
        didSet{
            segmentControl.addTarget(self, action: #selector(didTappedSegmentControl(_:)), for: .valueChanged)
            segmentControl.selectedSegmentIndex = 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchEvents()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didTappedSegmentControl(_ sender: Any){
        switch segmentControl.selectedSegmentIndex
        {
        case 0:
            tableView.reloadData()
        case 1:
            tableView.reloadData()
        case 2:
            tableView.reloadData()
        default:
            break;
        }
    }
    
    func fetchEvents() {
        let ref = Database.database().reference()
        ref.child("events").observe(.childAdded, with: { (snapshot) in
            if let eventDetail = EventData(snapshot: snapshot){
                self.storeEventData.append(eventDetail)
                self.filteredEventData = self.storeEventData
                self.tableView.reloadData()
            }
        })
    }
}

extension SearchVC : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if segmentControl.selectedSegmentIndex == 0 {
            filteredEventData = searchText.isEmpty ? storeEventData : storeEventData.filter{ (item: EventData) -> Bool in
                return item.eventTitle.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
            }
        } else if segmentControl.selectedSegmentIndex == 1 {
            filteredEventData = searchText.isEmpty ? storeEventData : storeEventData.filter{ (item: EventData) -> Bool in
                return item.eventStartAt.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
            }
        } else {
            filteredEventData = searchText.isEmpty ? storeEventData : storeEventData.filter{ (item: EventData) -> Bool in
                return item.eventCategory.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
            }
        }
        
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        searchBar.endEditing(true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
}

extension SearchVC : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredEventData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SearchCell
        
        let currentRow = filteredEventData[indexPath.row]
        
        cell.searchCellImageView.sd_setImage(with: currentRow.imageURL)
        cell.searchCellTitleLabel.text = currentRow.eventTitle
        cell.searchCellDescriptionLabel.text = currentRow.eventDescription
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let currentRow = filteredEventData[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "SelectedEventVC") as! SelectedEventVC
        
        nextVC.getEventDetail = currentRow
        
        navigationController?.pushViewController(nextVC, animated: true)
    }
    
}
