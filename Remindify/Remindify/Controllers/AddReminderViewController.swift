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
    
    let titleView = UITextView()
    let warningLabel = UITextField()
    let descriptionTextView = UITextView()
    let dateTimeLabel = UILabel()
    let dateLabel = UILabel()
       
    let dateFormatter = DateFormatter()
//    @IBOutlet weak var warningLabel: UILabel!
//    @IBOutlet weak var titleView: UITextField!
//    @IBOutlet weak var descriptionTextView: UITextField!
//    @IBOutlet weak var dateButton: UIButton!
//    @IBOutlet weak var dateLabel: UILabel!
//    @IBOutlet weak var saveButton: UIButton!
    
    var selectedDate: String?
    
    var reminder = ReminderModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        UNUserNotificationCenter.current().delegate = self
        dateLabel.isHidden = true
    }

    @objc func saveButtonTapped() {
        if titleView.text!.isEmpty {
            warningLabel.isHidden = false
            warningLabel.text = "Title can't be empty"
            return
        }
        
        if let user = Auth.auth().currentUser {
            let ownerId = user.uid  // Get the current user's UID
            
            reminder.title = titleView.text!
            reminder.description = descriptionTextView.text ?? ""
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
    
    @objc func dateButtonTapped() {
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
    
    func setupUI(){
        // Create a scroll view
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Create a stack view to hold the content
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        // Add a spacing view above the title to push it down
        let spacingView = UIView()
        stackView.addArrangedSubview(spacingView)

        // Set the height of the spacing view to create the desired spacing
        let spacingHeight: CGFloat = 30 // Adjust the value as needed
        spacingView.heightAnchor.constraint(equalToConstant: spacingHeight).isActive = true

        // Title TextView
        
        titleView.font = UIFont.boldSystemFont(ofSize: 36) // Larger and bolder
        titleView.isScrollEnabled = false
        titleView.text = "Title"
        titleView.layer.shadowColor = UIColor.systemTeal.cgColor // Shadow color
        titleView.layer.shadowOpacity = 0.7 // Shadow opacity
        titleView.layer.shadowRadius = 8.0 // Shadow radius
        titleView.layer.shadowOffset = CGSize(width: 0, height: 6) // Shadow offset
        titleView.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.6) // Background glow effect in sea green
        titleView.layer.cornerRadius = 12.0 // Rounded corners
        stackView.addArrangedSubview(titleView)

        // Warning Label (Text Field)
        
        warningLabel.text = "Warning"
        warningLabel.font = UIFont.boldSystemFont(ofSize: 14) // Bolder font
        warningLabel.textColor = .systemRed
        warningLabel.isHidden = true
        stackView.addArrangedSubview(warningLabel)

        // Description TextView
        
        descriptionTextView.font = UIFont.boldSystemFont(ofSize: 24) // Bolder font
        descriptionTextView.isScrollEnabled = false
        descriptionTextView.text = "Description"
        descriptionTextView.layer.shadowColor = UIColor.systemTeal.cgColor // Shadow color
        descriptionTextView.layer.shadowOpacity = 0.7 // Shadow opacity
        descriptionTextView.layer.shadowRadius = 8.0 // Shadow radius
        descriptionTextView.layer.shadowOffset = CGSize(width: 0, height: 6) // Shadow offset
        descriptionTextView.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.6) // Background glow effect in sea green
        descriptionTextView.layer.cornerRadius = 12.0 // Rounded corners
        stackView.addArrangedSubview(descriptionTextView)

        // Date Label
        
        dateTimeLabel.text = "Date"
        dateTimeLabel.textAlignment = .left // Align to the left

        // Create a horizontal stack view for the Date Label and Add Button
        let dateStackView = UIStackView()
        dateStackView.axis = .horizontal
        dateStackView.spacing = 10
        dateStackView.addArrangedSubview(dateTimeLabel)

        // Add Button
        let dateButton = UIButton()
        dateButton.setImage(UIImage(systemName: "exclamationmark.circle.fill"), for: .normal)
        dateStackView.addArrangedSubview(dateButton)
        dateButton.addTarget(self, action: #selector(dateButtonTapped), for: .touchUpInside)
        
        stackView.addArrangedSubview(dateStackView)

        // Stored Date Label
        
        dateLabel.text = ""
        stackView.addArrangedSubview(dateLabel)

        // Save Button
        let saveButton = UIButton()
        saveButton.setTitle("Save", for: .normal)
        saveButton.backgroundColor = UIColor.systemTeal // Sea green background color
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20) // Bolder font
        saveButton.layer.shadowColor = UIColor.systemGreen.cgColor // Shadow color
        saveButton.layer.shadowOpacity = 0.7 // Shadow opacity
        saveButton.layer.shadowRadius = 8.0 // Shadow radius
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 6) // Shadow offset
        saveButton.layer.cornerRadius = 12.0 // Rounded corners
        stackView.addArrangedSubview(saveButton)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)

        // Set constraints for the scroll view
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16), // Left space
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16), // Right space
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        // Set constraints for the stack view
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }
    

}
