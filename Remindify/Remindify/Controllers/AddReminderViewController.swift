//
//  AddReminderViewController.swift
//  Remindify
//
//  Created by Dev on 06/11/2023.
//

import UIKit
import DateTimePicker

class AddReminderViewController: UIViewController, DateTimePickerDelegate {
    
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
                    self.title = formatter.string(from: date)
                }
        picker.delegate = self
        picker.show()
    }
    
    func dateTimePicker(_ picker: DateTimePicker, didSelectDate: Date) {
        selectedDate = picker.selectedDateString
        }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        
        if (titleTextField.text == "") {
            warningLabel.isHidden = false
            DispatchQueue.main.async {
                self.warningLabel.text = "Title can't be empty"
            }
            return
        }
        
        reminder.title = titleTextField.text!
        reminder.description = descriptionTextField.text ?? ""
        reminder.date = selectedDate ?? ""
        
        print(reminder.title)
        print(reminder.description)
        print(reminder.date)
        
    }
    
}
