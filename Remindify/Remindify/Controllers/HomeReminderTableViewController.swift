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
import CoreMotion

class HomeReminderTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    var updateAlert: UIAlertController?
    var reminderArray = [ReminderModel(opened: false, title: "a", description: "aa", date: "2/2/23",documentID: nil, ownerId: nil),
                         ReminderModel(opened: false, title: "b", description: "bb", date: "2/3/24", documentID: nil, ownerId: nil)]
    
    var filteredReminders = [ReminderModel]()
    var originalReminders: [ReminderModel] = [] // Keep a reference to the original data
    let addButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add an observer for orientation change
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        // Left Bar Button (Logout)
        let leftBarButton = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutButtonTapped))
        self.navigationItem.leftBarButtonItem = leftBarButton
        
        // Increase the size of the navigation bar
        if let navigationBarFrame = navigationController?.navigationBar.frame {
            navigationController?.navigationBar.frame = CGRect(x: navigationBarFrame.origin.x, y: navigationBarFrame.origin.y, width: navigationBarFrame.size.width, height: 200)
        }

        
        tableView.dataSource = self
        tableView.delegate = self
        filteredReminders = reminderArray
        navigationItem.hidesBackButton = true
        requestNotificationAuthorization()
        addButtonToScreen()
        addProfileButton()
        loadReminders()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @objc func orientationDidChange() {
            if UIDevice.current.orientation.isLandscape {
                // Device is in landscape mode
                addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: view.frame.height - 150).isActive = true
                addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: view.frame.width - 100 ).isActive = true
            }
        }
    
    
    func loadReminders() {
        filteredReminders = []
        
        if let user = Auth.auth().currentUser {
            let ownerId = user.uid  // Get the current user's UID
            
            db.collection("reminders")
                .whereField("ownerId", isEqualTo: ownerId)  // Filter reminders by owner ID
                .order(by: "Date") // Make sure "Date" is spelled correctly (use uppercase "D") if that's your field name
                .addSnapshotListener() { (querySnapshot, err) in
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
                                        documentID: documentID, ownerId: ownerId)
                                    self.filteredReminders.append(newReminder)
                                    
                                    
                                }
                                else{
                                    print("error")
                                }
                            }
                            // Set the originalReminders to the filteredReminders
                            self.originalReminders = self.filteredReminders
                        }else{print("errorr")}
                        // Reload the table view after updating the data
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
        }
    }
    
    func addButtonToScreen() {
        // Create a UIButton with an "add" symbol
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)

        addButton.backgroundColor = .lightGray
        addButton.tintColor = .black
        // Make the button's corners round
        addButton.layer.cornerRadius = 40
        addButton.layer.masksToBounds = true
        addButton.translatesAutoresizingMaskIntoConstraints = false

        // Add a target action to the button
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)

        // Add the button to your view controller's view
        view.addSubview(addButton)

        addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: view.frame.width - 100).isActive = true
        addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: view.frame.height - 150 ).isActive = true
        addButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 80).isActive = true
    }

    @objc func addButtonTapped() {
        //navigate to add reminders
        let addReminderViewController = self.storyboard?.instantiateViewController(withIdentifier: "AddReminderViewController") as! AddReminderViewController
        self.navigationController?.pushViewController(addReminderViewController, animated: true)
    }
    
    //MARK: - Profile Button
    
    func addProfileButton() {
        let buttonSize: CGFloat = 40  // Adjust the size as needed
        let buttonFrame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)

        let customButton = UIButton(frame: buttonFrame)
        customButton.layer.cornerRadius = buttonSize / 2  // Make it rounded
        customButton.clipsToBounds = true

        if let user = Auth.auth().currentUser, let photoURL = user.photoURL {
            customButton.sd_setBackgroundImage(with: photoURL, for: .normal, placeholderImage: UIImage(named: "Profile"))
        } else {
            customButton.setImage(UIImage(systemName: "person.circle.fill") , for: .normal)
        }

        customButton.addTarget(self, action: #selector(profileButtonTapped), for: .touchUpInside)

        let customView = UIView(frame: buttonFrame)
        customView.addSubview(customButton)

        let profileBarButton = UIBarButtonItem(customView: customView)
        self.navigationItem.rightBarButtonItem = profileBarButton
    }

    
    @objc func profileButtonTapped() {
        //navigate to profile
        let profileViewController = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        self.navigationController?.pushViewController(profileViewController, animated: true)
    }
    
    //MARK: - bar buttons

    @objc func logoutButtonTapped() {
        // Handle the action for the left bar button (Logout)
        do {
            try Auth.auth().signOut()
            updateAlert = UIAlertController(title: "Logging Out", message: nil, preferredStyle: .alert)
            present(updateAlert!, animated: true, completion: nil)
            
            // Add a delay to dismiss the alert after a few seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.updateAlert?.dismiss(animated: true, completion: nil)
                        
                        // Navigate to the login view controller on the main thread
                        DispatchQueue.main.async {
                            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                            self.navigationController?.pushViewController(loginViewController, animated: true)
                        }
                    }
            
        } catch {
            print("Error while signing out: \(error)")
        }
    }


    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredReminders.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Return the desired height for the cells
        return 65.0 // Adjust the value to the height you want
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SwipeTableViewCell
        
        cell.delegate = self
        cell.textLabel?.text = filteredReminders[indexPath.row].title
        
        // Set the font for the title (left side) label
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        
        // Set the detail (right side) of the cell
        cell.detailTextLabel?.text = filteredReminders[indexPath.row].date
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < filteredReminders.count else {
            return
        }
        
        let selectedReminder = filteredReminders[indexPath.row]
        
        let editViewController = self.storyboard?.instantiateViewController(withIdentifier: "EditReminderViewController") as! EditReminderViewController
        editViewController.reminder = selectedReminder
        self.navigationController?.pushViewController(editViewController, animated: true)
    }
    
    
    
}

//MARK: - SwipeCells


// Modify the swipe actions to work with single-row cells
extension HomeReminderTableViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            let reminderToDelete = self.filteredReminders[indexPath.row]
            
            if let ownerId = reminderToDelete.ownerId, let documentId = reminderToDelete.documentID {
                // Update the local array first
                if let indexToDelete = self.filteredReminders.firstIndex(where: { $0.documentID == documentId }) {
                    self.filteredReminders.remove(at: indexToDelete)
                    
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

extension HomeReminderTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            // If the search bar is empty, show the original table view
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
            // Reload the original data
            filteredReminders = originalReminders
            self.tableView.reloadData()
        } else {
            // If there's text in the search bar, filter the reminders based on the search text
            let searchTextLowercased = searchText.lowercased()
            filteredReminders = originalReminders.filter { reminder in
                // Case-insensitive search for reminders containing the search text
                return reminder.title?.lowercased().contains(searchTextLowercased) ?? false
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        // Allow editing and return true
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Handle actions when the search button is clicked (optional)
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Handle actions when the cancel button is clicked
        searchBar.text = ""
        searchBar.resignFirstResponder()
        //        displayArray = reminderArray
        //        tableView.reloadData()
        loadReminders()
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        // Allow ending editing and return true
        return true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // Handle actions when the search bar ends editing (optional)
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Handle text changes in the search bar (optional)
        return true
    }
    
    // Handle tap gesture to resign search bar when the user clicks anywhere else on the screen
    //        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //            searchBar.resignFirstResponder()
    //        }
    
}

//MARK: - notifications

extension HomeReminderTableViewController: UNUserNotificationCenterDelegate{
    
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                print("Notification authorization granted")
            } else {
                print("Notification authorization denied or error")
            }
        }
    }
}

