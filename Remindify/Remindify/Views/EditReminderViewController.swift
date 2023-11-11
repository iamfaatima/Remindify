//
//  EditReminderViewController.swift
//  Remindify
//
//  Created by Dev on 11/11/2023.
//

import UIKit
import FirebaseFirestore
import DateTimePicker
import FirebaseAuth
import AVFoundation
import UserNotifications

class EditReminderViewController: UIViewController {
    
    //MARK: - Outlets
    var reminder: ReminderModel? // Declare reminder as an optional property
    var selectedDate: Date?
    var dateString: String?
    let dateFormatter = DateFormatter()
    var updateAlert: UIAlertController?

    @IBOutlet weak var titleView: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func dateButton(_ sender: UIButton) {
        let min = Date()
            let max = Calendar.current.date(byAdding: .year, value: 1, to: min)
            let picker = DateTimePicker.create(minimumDate: min, maximumDate: max)
            
            picker.frame = CGRect(x: 0, y: 100, width: picker.frame.size.width, height: picker.frame.size.height)
            
            picker.completionHandler = { date in
                self.selectedDate = date // Store the selected date
                self.dateFormatter.dateFormat = "HH:mm dd/MM/yyyy"
                self.dateString = self.dateFormatter.string(from: date)
            }
            
            picker.show()
    }
    @IBAction func saveButtonPressed(_ sender: Any) {
        // Save the edited reminder data back to Firestore
        if let myreminder = self.reminder {
                var reminder = myreminder
                // Update the reminder properties with the edited data
                reminder.title = titleView.text
                reminder.description = descriptionField.text
                reminder.date = dateString
                
                // Call a function to update the reminder in Firestore
                updateReminderInFirestore(reminder: reminder)
            
                updateAlert = UIAlertController(title: "Reminder Updated", message: nil, preferredStyle: .alert)
                present(updateAlert!, animated: true, completion: nil)
                
                // Add a delay to dismiss the alert after a few seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.updateAlert?.dismiss(animated: true, completion: nil)
                }
            }
    }
    
    override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .dark
            
            // Pre-fill the text fields with reminder data
        if let reminder = self.reminder {
            titleView.text = reminder.title
            descriptionField.text = reminder.description
            if let date = reminder.date{
                selectedDate = dateFormatter.date(from: date)
            }
        }
        }
    
    // Function to update the reminder in Firestore
    func updateReminderInFirestore(reminder: ReminderModel) {
        if let documentID = reminder.documentID {
            let db = Firestore.firestore()
            db.collection("reminders").document(documentID).updateData([
                "Title": reminder.title,
                "Description": reminder.description,
                "Date": reminder.date // Update the date field
            ]) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else {
                    print("Document updated successfully!")

                    // Set up your local notification or schedule your alarm here
                    if let date = reminder.date {
                        self.scheduleAlarmNotification(at: date)
                    }

                    // Optionally, you can navigate back to the previous view controller
                    let homeViewController = self.storyboard?.instantiateViewController(withIdentifier: "HomeReminderTableViewController") as! HomeReminderTableViewController
                    self.navigationController?.pushViewController(homeViewController, animated: true)
                }
            }
        }
    }
    
    func scheduleAlarmNotification(at date: String) {
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = "Time to wake up!"
        content.sound = UNNotificationSound.default

        // Play the "A.wav" sound when the notification is scheduled
        if let soundURL = Bundle.main.url(forResource: "A", withExtension: "wav", subdirectory: "Sounds") {
            let alarmSound = UNNotificationSound(named: .init(rawValue: soundURL.relativeString))
            content.sound = alarmSound
        }

        let calendar = Calendar.current
        dateFormatter.dateFormat = "HH:mm dd/MM/yyyy" // Corrected date format

        if let sdate = dateFormatter.date(from: date) {
            print(sdate)
            let alarmDate = sdate

            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alarmDate)

            print(dateComponents)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            let identifier = "alarmNotification"

            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            let center = UNUserNotificationCenter.current()
            center.add(request) { (error) in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("Alarm notification scheduled successfully")
                }
            }
        } else {
            print("Date parsing failed.")
        }
    }



}
