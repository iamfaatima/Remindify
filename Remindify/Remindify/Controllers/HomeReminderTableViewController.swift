//
//  HomeReminderTableTableViewController.swift
//  Remindify
//
//  Created by Dev on 05/11/2023.
//

import UIKit

class HomeReminderTableViewController: UITableViewController {
    
    let reminderArray = ["a", "b"]
    override func viewDidLoad() {
        super.viewDidLoad()
        addButton()
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminderArray.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Return the desired height for the cells
        return 65.0 // Adjust the value to the height you want
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        
        cell.textLabel?.text = reminderArray[indexPath.row]
        
        // Set the font for the title (left side) label
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        
        // Set the detail (right side) of the cell
        cell.detailTextLabel?.text = "Reminders - 03/11/2023, 5:00 PM"
        
        return cell
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    
    
}
