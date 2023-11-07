//
//  HomeReminderTableTableViewController.swift
//  Remindify
//
//  Created by Dev on 05/11/2023.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class HomeReminderTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    
    var reminderArray = [ReminderModel(opened: false, title: "a", description: "aa", date: "2/2/23"),
                         ReminderModel(opened: false, title: "b", description: "bb", date: "2/3/24")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addButton()
        addProfileButton()
        loadReminders()
        tableView.dataSource = self
        tableView.delegate = self
        //tableView.separatorStyle = .singleLineEtched
        self.title = "Remindify"
        
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
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

    func loadReminders(){
        reminderArray = []
            
        db.collection("reminders").order(by: "Date").addSnapshotListener() { (querySnapshot, err) in
          if let err = err {
            print("Error getting documents: \(err)")
          } else {
              if let snapshotDocuments = querySnapshot?.documents{
                  for document in snapshotDocuments {
                   // print("\(document.documentID) => \(document.data())")
                      let data = document.data()
                      if let title = data["Title"] as? String{
                          let newReminder = ReminderModel(title: title, description: data["Description"] as! String, date: data["Date"] as! String)
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
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Return the desired height for the cells
        return 65.0 // Adjust the value to the height you want
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
            return reminderArray.count
        }
        
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if reminderArray[section].opened == true{
                return 2
            }else{
                return 1
            }
        }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            if indexPath.row == 0{
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                cell.textLabel?.text = reminderArray[indexPath.section].title
                // Set the font for the title (left side) label
                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 20)
                // Set the detail (right side) of the cell
                cell.detailTextLabel?.text = reminderArray[indexPath.section].date
                //cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                return cell
            }else{
                //use different cell identifier if needed
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                cell.textLabel?.text = reminderArray[indexPath.section].description
                cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
                cell.detailTextLabel?.text = ""
                //cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                return cell
            }
        }
        
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if indexPath.row == 0{
                if reminderArray[indexPath.section].opened == true{
                    reminderArray[indexPath.section].opened = false
                    let sections = IndexSet.init(integer: indexPath.section)
                    tableView.reloadSections(sections, with: .none) //change this .none
                }else{
                    reminderArray[indexPath.section].opened = true
                    let sections = IndexSet.init(integer: indexPath.section)
                    tableView.reloadSections(sections, with: .none) //change this .none
                }
            }
        }
        
//        override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//            return section == 0 ? .leastNonzeroMagnitude : 20 // Hide the header for the first section
//        }

//        override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//            if section == 0 {
//                return nil // Return nil for the first section to hide the header
//            } else {
//                let separatorView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 0))
//                separatorView.backgroundColor = .clear // Set the color of the separator line
//                return separatorView
//            }
//        }


    }
