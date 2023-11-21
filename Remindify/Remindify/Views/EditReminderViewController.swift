//
//  EditReminderViewController.swift
//  Remindify
//
//  Created by Dev on 11/11/2023.
//

import UIKit
import DateTimePicker
import AVFoundation
import UserNotifications

class EditReminderViewController: UIViewController, UITextViewDelegate {
    
    //MARK: - Outlets
    var reminder: ReminderModel? // Declare reminder as an optional property
    var selectedDate: Date?
    var dateString: String?
    let dateFormatter = DateFormatter()
    var updateAlert: UIAlertController?
    
    let titleView = UITextView()
    let warningLabel = UITextField()
    let descriptionTextView = UITextView()
    let dateTimeLabel = UILabel()
    let dateLabel = UILabel()
    // Placeholder labels
    let titlePlaceholderLabel: UILabel = UILabel()
    let descriptionPlaceholderLabel: UILabel = UILabel()
    
    override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            loadReminder()
            titleView.delegate = self
            descriptionTextView.delegate = self
            checkUserAuthentication()
        }

        func loadReminder() {
            if let reminder = self.reminder {
                titleView.text = reminder.title
                descriptionTextView.text = reminder.description
                if let date = reminder.date {
                    DispatchQueue.main.async {
                        self.dateLabel.text = date
                    }
                    selectedDate = dateFormatter.date(from: date)
                }
            }
        }

        func checkUserAuthentication() {
            FirebaseService.shared.checkUserAuthentication { [weak self] isAuthenticated in
                guard let self = self else { return }
                if !isAuthenticated {
                    self.showSessionExpiredPopup()
                }
            }
        }

        func updateReminderInFirestore(reminder: ReminderModel) {
            FirebaseService.shared.updateReminder(reminder) { [weak self] error in
                guard let self = self else { return }

                if let error = error {
                    self.warningLabel.text = "Error updating document"
                    self.warningLabel.isHidden = false
                    print("Error updating document: \(error)")
                } else {
                    print("Document updated successfully!")

                    if let date = reminder.date {
                        self.scheduleAlarmNotification(at: date)
                    }

                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    
    // Function to show session expired pop-up
    func showSessionExpiredPopup() {
        let alertController = UIAlertController(title: "Session Expired", message: nil, preferredStyle: .alert)
        
        // Add any additional customization to the alert controller if needed
        
        
        present(alertController, animated: true, completion: nil)
        
        // Dismiss the alert controller after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alertController.dismiss(animated: true, completion: nil)
        }
        // User is not logged in, navigate to the login view controller
        let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        self.navigationController?.pushViewController(loginViewController, animated: true)
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
            
            var notificationIdentifier = "alarmNotification"
            if let documentID = reminder!.documentID{
                notificationIdentifier = "Reminder_\(documentID)"
            }else{
                warningLabel.text = "Error updating alarm"
                warningLabel.isHidden = false
            }
            let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
            
            let center = UNUserNotificationCenter.current()
            center.add(request) { (error) in
                if let error = error {
                    self.warningLabel.text = "Error scheduling notification"
                    self.warningLabel.isHidden = false
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("Alarm notification scheduled successfully")
                }
            }
        } else {
            warningLabel.text = "Failed"
            warningLabel.isHidden = false
            print("Date parsing failed.")
        }
    }
    
    @objc func dateButtonTapped() {
        let min = Date()
        let max = Calendar.current.date(byAdding: .year, value: 1, to: min)
        let picker = DateTimePicker.create(minimumDate: min, maximumDate: max)
        
        picker.frame = CGRect(x: 0, y: 100, width: picker.frame.size.width, height: picker.frame.size.height)
        
        picker.completionHandler = { date in
            self.selectedDate = date // Store the selected date
            self.dateFormatter.dateFormat = "HH:mm dd/MM/yyyy"
            self.dateString = self.dateFormatter.string(from: date)
            DispatchQueue.main.async {
                self.dateLabel.text = self.dateString
            }
        }
        
        picker.show()
    }
    
    @objc func saveButtonTapped() {
            if let myreminder = self.reminder {
                var reminder = myreminder
                reminder.title = titleView.text
                reminder.description = descriptionTextView.text
                reminder.date = dateString ?? reminder.date

                if reminder.title == "" {
                    self.warningLabel.text = "Title can't be empty"
                    self.warningLabel.isHidden = false
                    return
                }

                updateReminderInFirestore(reminder: reminder)

                updateAlert = UIAlertController(title: "Reminder Updated", message: nil, preferredStyle: .alert)
                present(updateAlert!, animated: true, completion: nil)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.updateAlert?.dismiss(animated: true, completion: nil)
                }
            }
        }
    
    func textViewDidChange(_ textView: UITextView) {
        // Check if the titleView is being edited
        if textView == titleView {
            titlePlaceholderLabel.isHidden = !textView.text.isEmpty
        }
        // Check if the descriptionTextView is being edited
        else if textView == descriptionTextView {
            descriptionPlaceholderLabel.isHidden = !textView.text.isEmpty
        }
    }
}

//MARK: - UI setup

extension EditReminderViewController{
    func setupUI(){
        view.backgroundColor = .white
        navigationController?.navigationBar.tintColor = UIColor.systemTeal
        
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
        titleView.textColor = UIColor.white
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
        descriptionTextView.textColor = UIColor.white
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
        
        // Placeholder labels for title and description
        titlePlaceholderLabel.text = "Title"
        titlePlaceholderLabel.font = UIFont.systemFont(ofSize: 34)
        titlePlaceholderLabel.textColor = .white
        
        descriptionPlaceholderLabel.text = "Description"
        descriptionPlaceholderLabel.font = UIFont.systemFont(ofSize: 28)
        descriptionPlaceholderLabel.textColor = .white
        
        // Check if titleView has pre-populated text
        titlePlaceholderLabel.isHidden = !titleView.text.isEmpty
        
        // Check if descriptionTextView has pre-populated text
        descriptionPlaceholderLabel.isHidden = !descriptionTextView.text.isEmpty
        
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
        
        // Add placeholders to the UI
        titleView.addSubview(titlePlaceholderLabel)
        titlePlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titlePlaceholderLabel.leadingAnchor.constraint(equalTo: titleView.leadingAnchor, constant: 8),
            titlePlaceholderLabel.topAnchor.constraint(equalTo: titleView.topAnchor, constant: 8),
        ])
        
        descriptionTextView.addSubview(descriptionPlaceholderLabel)
        descriptionPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            descriptionPlaceholderLabel.leadingAnchor.constraint(equalTo: descriptionTextView.leadingAnchor, constant: 8),
            descriptionPlaceholderLabel.topAnchor.constraint(equalTo: descriptionTextView.topAnchor, constant: 8),
        ])
    }
    
}
