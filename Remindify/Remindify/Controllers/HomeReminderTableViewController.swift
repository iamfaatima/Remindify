import UIKit
import FirebaseFirestore
import FirebaseAuth
import SwipeCellKit
import CoreMotion

class HomeReminderTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UNUserNotificationCenterDelegate, SwipeTableViewCellDelegate {
    
    let db = Firestore.firestore()
    var updateAlert: UIAlertController?
    var reminderArray = [ReminderModel(opened: false, title: "a", description: "aa", date: "2/2/23",documentID: nil, ownerId: nil),
                         ReminderModel(opened: false, title: "b", description: "bb", date: "2/3/24", documentID: nil, ownerId: nil)]
    
    var filteredReminders = [ReminderModel]()
    var originalReminders: [ReminderModel] = [] // Keep a reference to the original data
    
    
    let tableView = UITableView()
    let searchBar = UISearchBar()
    let footerView = UIView()
    var isCellExpanded: [Bool] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        
        // Left Bar Button (Logout)
        let leftBarButton = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutButtonTapped))
        self.navigationItem.leftBarButtonItem = leftBarButton

        // Increase the size of the navigation bar
        if let navigationBarFrame = navigationController?.navigationBar.frame {
            navigationController?.navigationBar.frame = CGRect(x: navigationBarFrame.origin.x, y: navigationBarFrame.origin.y, width: navigationBarFrame.size.width, height: 200)
        }
        filteredReminders = reminderArray
        navigationItem.hidesBackButton = true
        requestNotificationAuthorization()
        addProfileButton()
        loadReminders()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @objc func addReminderButtonTapped() {
        //navigate to add reminders
        let addReminderViewController = self.storyboard?.instantiateViewController(withIdentifier: "AddReminderViewController") as! AddReminderViewController
        self.navigationController?.pushViewController(addReminderViewController, animated: true)
    }
    
    
    
    func loadReminders() {
        filteredReminders = []
        
        if let user = Auth.auth().currentUser {
            let ownerId = user.uid  // Get the current user's UID
            
            db.collection("reminders")
                .whereField("ownerId", isEqualTo: ownerId)  // Filter reminders by owner ID
                .order(by: "Date", descending: true) // Make sure "Date" is spelled correctly (use uppercase "D") if that's your field name
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
                                        date: data["Date"] as? String,
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
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in your table
        return filteredReminders.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell
        let reminder = filteredReminders[indexPath.row]
        
        cell.titleLabel.text = reminder.title
        cell.detailLabel.text = "\(reminder.date ?? "")"
        cell.descriptionLabel.text = "Description: \(reminder.description ?? "")"
        cell.isExpanded = isCellExpanded[indexPath.row]
        cell.doubleTapAction = { [weak self] in
            self?.isCellExpanded[indexPath.row].toggle()
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < filteredReminders.count else {
            return
        }

        let selectedReminder = filteredReminders[indexPath.row]

        let editViewController = self.storyboard?.instantiateViewController(withIdentifier: "EditReminderViewController") as! EditReminderViewController
        editViewController.reminder = selectedReminder
        self.navigationController?.pushViewController(editViewController, animated: true)
    }
    
    func setupUI() {
        // Set up the search bar
        searchBar.delegate = self
        searchBar.placeholder = "Search Reminders"
        searchBar.searchBarStyle = .minimal
        searchBar.barTintColor = UIColor(red: 46/255, green: 139/255, blue: 87/255, alpha: 1.0) // Sea-green shade
        searchBar.backgroundImage = UIImage()
        searchBar.tintColor = .white
        searchBar.isTranslucent = true
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        // Set up the table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CustomTableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = .clear // No background color
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Set up the footer view with sea-green background color
        footerView.backgroundColor = UIColor(red: 46/255, green: 139/255, blue: 87/255, alpha: 1.0) // Sea-green shade
        footerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(footerView)
        
        // Add the "Add Reminder" button with a three-dot SF symbol
        let addButton = UIButton()
        addButton.setTitle("Add Reminder", for: .normal)
        addButton.tintColor = .white
        addButton.backgroundColor = UIColor(red: 46/255, green: 139/255, blue: 87/255, alpha: 1.0) // Sea-green shade
        addButton.layer.cornerRadius = 8
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addReminderButtonTapped), for: .touchUpInside)
        footerView.addSubview(addButton)
        
        // Initialize the cell expansion states
        isCellExpanded = Array(repeating: false, count: 10)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: footerView.topAnchor),
            
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 60),
            
            addButton.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            addButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }
    
    class CustomTableViewCell: SwipeTableViewCell {
        let titleLabel = UILabel()
        let detailLabel = UILabel()
        let descriptionLabel = UILabel()
        var descriptionLabelHeightConstraint: NSLayoutConstraint!
        
        var isExpanded: Bool = false {
            didSet {
                descriptionLabelHeightConstraint.constant = isExpanded ? 44 : 0
                descriptionLabel.isHidden = !isExpanded
            }
        }
        var doubleTapAction: (() -> Void)?
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setUI()
            
            // Add a double-tap gesture recognizer
            let doubleTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleDoubleTap))
            doubleTapGesture.minimumPressDuration = 0.5 // Set the required duration for a long press
            doubleTapGesture.allowableMovement = 10.0 // Set the maximum movement allowed for a long press

            contentView.addGestureRecognizer(doubleTapGesture)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setUI() {
            contentView.backgroundColor = .clear // No background color
            contentView.layer.cornerRadius = 10
            contentView.layer.shadowColor = UIColor(red: 46/255, green: 139/255, blue: 87/255, alpha: 0.4).cgColor // Sea-green shadow
            contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
            contentView.layer.shadowRadius = 4
            contentView.layer.shadowOpacity = 1.0
            
            titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            titleLabel.textColor = UIColor(red: 46/255, green: 139/255, blue: 87/255, alpha: 1.0) // Sea-green color
            titleLabel.numberOfLines = 0
            
            detailLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            detailLabel.textColor = .darkGray
            detailLabel.numberOfLines = 0
            
            descriptionLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
            descriptionLabel.textColor = .darkGray
            descriptionLabel.numberOfLines = 0
            
            addSubview(titleLabel)
            addSubview(detailLabel)
            addSubview(descriptionLabel)
            
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            detailLabel.translatesAutoresizingMaskIntoConstraints = false
            descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
                
                detailLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                
                descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                descriptionLabel.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 4),
                descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12),
            ])
            
            descriptionLabelHeightConstraint = descriptionLabel.heightAnchor.constraint(equalTo: descriptionLabel.heightAnchor, multiplier: isExpanded ? 1.0 : 0.0)
            descriptionLabelHeightConstraint.isActive = true
        }
        
        @objc func handleDoubleTap() {
            doubleTapAction?()
        }
    }
    
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
                            DispatchQueue.main.async {
                                self.loadReminders()
                            }
                            // Obtain the notification identifier
                            let notificationIdentifier = "Reminder_\(documentId)"
                            // Remove the local notification with the obtained identifier
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
                            // Firestore will trigger the snapshot listener, updating the table view
                        }
                    }
                    
                    
                }
            }
        }
        
        // Customize the action appearance
        deleteAction.image = UIImage(systemName: "trash")
        
        return [deleteAction]
    }

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .destructive
        options.transitionStyle = .border

        return options
    }
        
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
