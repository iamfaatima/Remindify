//
//  HomeReminderTableTableViewController.swift
//  Remindify
//
//  Created by Dev on 05/11/2023.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import SwipeCellKit

class HomeReminderTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    
    var reminderArray = [ReminderModel(opened: false, title: "a", description: "aa", date: "2/2/23",documentID: nil, ownerId: nil),
                             ReminderModel(opened: false, title: "b", description: "bb", date: "2/3/24", documentID: nil, ownerId: nil)]
    
    var displayArray = [ReminderModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addButton()
        loadReminders()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func loadReminders() {
        reminderArray = []
        
        if let user = Auth.auth().currentUser {
            let ownerId = user.uid  // Get the current user's UID
            
            db.collection("reminders")
                .whereField("ownerId", isEqualTo: ownerId)  // Filter reminders by owner ID
                .order(by: "Date")
                .addSnapshotListener { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        if let snapshotDocuments = querySnapshot?.documents {
                            for document in snapshotDocuments {
                                let data = document.data()
                                if let title = data["Title"] as? String {
                                    let documentID = document.documentID // Retrieve the Firestore document ID
                                    let newReminder = ReminderModel(
                                        title: title,
                                        description: data["Description"] as! String,
                                        date: data["Date"] as! String,
                                        documentID: documentID, ownerId: ownerId
                                    )
                                    self.reminderArray.append(newReminder)
                                    
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                    }
                                }
                            }
                        }
                    }
                }
        }
        self.tableView.reloadData()
    }
    
    func addButton(){
        // Create a UIButton with an "add" symbol
        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus"), for: .normal) // "plus" is the SF Symbol name for the "add" symbol
        
        // Set up the button's frame or constraints
        addButton.frame = CGRect(x: tableView.frame.width - 100, y: tableView.frame.height - 200, width: 80, height: 80)
        addButton.backgroundColor = .lightGray
        addButton.tintColor = .black
        // Make the button's corners round
        addButton.layer.cornerRadius = addButton.frame.height / 2
        addButton.layer.masksToBounds = true
        
        // Add a target action to the button
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        // Add the button to your view
        view.addSubview(addButton)
        
        // Make sure the button is added on top of the table view.
        view.bringSubviewToFront(addButton)
        
        
        
    }
    @objc func addButtonTapped() {
        //navigate to add reminders
        let addReminderViewController = self.storyboard?.instantiateViewController(withIdentifier: "AddReminderViewController") as! AddReminderViewController
        self.navigationController?.pushViewController(addReminderViewController, animated: true)
    }
    
    //MARK: - Profile Button
    
    func addProfileButton() {
        let button = UIButton(type: .custom)
        
        // Load the user's photoURL and set it as the button's background image
        if let user = Auth.auth().currentUser, let photoURL = user.photoURL {
            button.sd_setBackgroundImage(with: photoURL, for: .normal, placeholderImage: UIImage(named: "Profile"))
        } else {
            // Use a default image if the user doesn't have a photoURL
            button.setImage(UIImage(named: "Profile"), for: .normal)
        }
        
        // Set the button's frame to position it in the top-right corner
        button.frame = CGRect(x: tableView.frame.width - 100, y: 0, width: 80, height: 80)
        
        // Add a target for the button to handle the button tap action
        button.addTarget(self, action: #selector(profileButtonTapped), for: .touchUpInside)
        
        button.layer.cornerRadius = button.frame.height / 2
        button.layer.masksToBounds = true
        
        // Make sure the button is added on top of the table view.
        view.bringSubviewToFront(button)
        
        // Add the button as a subview to your view controller's view
        view.addSubview(button)
    }
    
    @objc func profileButtonTapped() {
        //navigate to profile
        let profileViewController = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        self.navigationController?.pushViewController(profileViewController, animated: true)
    }

    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminderArray.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Return the desired height for the cells
        return 65.0 // Adjust the value to the height you want
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SwipeTableViewCell
        
        cell.delegate = self
        cell.textLabel?.text = reminderArray[indexPath.row].title
        
        // Set the font for the title (left side) label
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        
        // Set the detail (right side) of the cell
        cell.detailTextLabel?.text = reminderArray[indexPath.row].date
        
        return cell
    }
}


// Modify the swipe actions to work with single-row cells
extension HomeReminderTableViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            let reminderToDelete = self.reminderArray[indexPath.row]
            
            if let ownerId = reminderToDelete.ownerId, let documentId = reminderToDelete.documentID {
                // Update the local array first
                if let indexToDelete = self.reminderArray.firstIndex(where: { $0.documentID == documentId }) {
                    self.reminderArray.remove(at: indexToDelete)
                    
                    // Update Firestore
                    self.db.collection("reminders").document(documentId).delete { error in
                        if let error = error {
                            print("Error deleting document: \(error)")
                        } else {
                            print("Document successfully deleted!")
                            // Firestore will trigger the snapshot listener, updating the table view
                        }
                    }
                }
            }
        }

        // Customize the action appearance
        deleteAction.image = UIImage(named: "Trash")

        return [deleteAction]
    }




    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .destructive
        return options
    }
    
  
}

