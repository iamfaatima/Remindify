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
import UserNotifications
import AVFoundation

class AddReminderViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    var updateAlert: UIAlertController?
    var alarmDate: Date?
    var audioPlayer: AVAudioPlayer?
    var isAlarmRinging = false
       
    let dateFormatter = DateFormatter()
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var chooseDateTimeButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    
    var selectedDate: String?
    
    var reminder = ReminderModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .dark
        warningLabel.isHidden = true
        UNUserNotificationCenter.current().delegate = self
        dateLabel.isHidden = true
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
                        self.updateAlert = UIAlertController(title: "Reminder Added", message: nil, preferredStyle: .alert)
                        self.present(self.updateAlert!, animated: true, completion: nil)
                        
                        // Add a delay to dismiss the alert after a few seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.updateAlert?.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
            if let date = selectedDate{
                DispatchQueue.main.async {
                    self.dateLabel.text = date
                    self.dateLabel.isHidden = false
                }
                scheduleAlarmNotification(at: date)
            }
            
        }
        
        //navigate to home
        let homeViewController = self.storyboard?.instantiateViewController(withIdentifier: "HomeReminderTableViewController") as! HomeReminderTableViewController
        self.navigationController?.pushViewController(homeViewController, animated: true)
    }
}

//MARK: - DateTime Picker

extension AddReminderViewController: DateTimePickerDelegate{
    @IBAction func pickDateButtonPressed(_ sender: UIButton) {
        let min = Date().addingTimeInterval(-60 * 60 * 24 * 4)
        let max = Date().addingTimeInterval(60 * 60 * 24 * 4)
        let picker = DateTimePicker.create(minimumDate: min, maximumDate: max)
        picker.frame = CGRect(x: 0, y: 100, width: picker.frame.size.width, height: picker.frame.size.height)
        
        picker.completionHandler = { date in
            
            self.dateFormatter.dateFormat = "HH:mm dd/MM/yyyy"
            //self.title = formatter.string(from: date)
        }
        picker.delegate = self
        picker.show()
    }
    
    func dateTimePicker(_ picker: DateTimePicker, didSelectDate: Date) {
        DispatchQueue.main.async {
            self.dateLabel.isHidden = false
            self.dateLabel.text = self.selectedDate
        }
        selectedDate = picker.selectedDateString
    }
}


// MARK: - Notification Functions

extension AddReminderViewController: UNUserNotificationCenterDelegate{
    // Implement the notification delegate method to handle notifications when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle the notification presentation when the app is in the foreground (e.g., show an alert)
        if notification.request.identifier == "alarmNotification" {
            play()
            isAlarmRinging = true
        }
        completionHandler([.alert, .sound, .badge])
    }
    
    func play() {
        print("Playing alarm sound")
        if let soundURL = Bundle.main.url(forResource: "A", withExtension: "wav", subdirectory: "Sounds") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer!.play()
            } catch {
                print("Error playing alarm sound: \(error.localizedDescription)")
            }
        } else {
            print("Error: Sound file not found")
        }
    }
    
    func scheduleAlarmNotification(at date: String) {
        // Obtain the documentID of the reminder
        if let documentID = reminder.documentID {
            let notificationIdentifier = "Reminder_\(documentID)"
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
            alarmDate = sdate
            
            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alarmDate!)
            
            print(dateComponents)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
            
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

}
