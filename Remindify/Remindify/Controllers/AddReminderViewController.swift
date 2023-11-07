//
//  AddReminderViewController.swift
//  Remindify
//
//  Created by Dev on 06/11/2023.
//

import UIKit
import FirebaseFirestore
import DateTimePicker
import FirebaseAuth

class AddReminderViewController: UIViewController, DateTimePickerDelegate {
    
    let db = Firestore.firestore()
    
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    
    var selectedDate: String?
    
    var reminder = ReminderModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        warningLabel.isHidden = true
        
    }
    
    @IBAction func pickDateButtonPressed(_ sender: UIButton) {
        let min = Date().addingTimeInterval(-60 * 60 * 24 * 4)
        let max = Date().addingTimeInterval(60 * 60 * 24 * 4)
        let picker = DateTimePicker.create(minimumDate: min, maximumDate: max)
        picker.frame = CGRect(x: 0, y: 100, width: picker.frame.size.width, height: picker.frame.size.height)
        
        picker.completionHandler = { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm:ss aa dd/MM/YYYY"
            //self.title = formatter.string(from: date)
        }
        picker.delegate = self
        picker.show()
    }
    
    func dateTimePicker(_ picker: DateTimePicker, didSelectDate: Date) {
        selectedDate = picker.selectedDateString
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        if titleTextField.text!.isEmpty {
            warningLabel.isHidden = false
            warningLabel.text = "Title can't be empty"
            return
        }
        
        if let user = Auth.auth().currentUser {
            let ownerId = user.uid  // Get the current user's UID
            
            reminder.title = titleTextField.text!
            reminder.description = descriptionTextField.text ?? ""
            reminder.date = selectedDate ?? ""
            
            if let title = reminder.title {
                let reminderData: [String: Any] = [
                    "Title": title,
                    "Description": reminder.description,
                    "Date": reminder.date,
                    "ownerId": ownerId  // Set the owner's UID
                ]
                
                db.collection("reminders").addDocument(data: reminderData) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        print("Document added with ID")
                    }
                }
            }
        }
        
        //navigate to home
        let homeViewController = self.storyboard?.instantiateViewController(withIdentifier: "HomeReminderTableViewController") as! HomeReminderTableViewController
        self.navigationController?.pushViewController(homeViewController, animated: true)
    }
}
