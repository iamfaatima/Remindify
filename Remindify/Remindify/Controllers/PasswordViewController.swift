import UIKit
import FirebaseAuth

class PasswordViewController: UIViewController {

    @IBOutlet weak var oldPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    
    @IBAction func saveChangesButtonPressed(_ sender: UIButton) {
        // Check if the new password and confirm password match
        guard let newPassword = newPasswordTextField.text, let confirmPassword = confirmPasswordTextField.text, newPassword == confirmPassword else {
            warningLabel.isHidden = false
            warningLabel.text = "Password and confirm password do not match"
            return
        }
        
        // Authenticate the user with their current password to update the password
        if let user = Auth.auth().currentUser, let oldPassword = oldPasswordTextField.text {
            let credential = EmailAuthProvider.credential(withEmail: user.email!, password: oldPassword)
            user.reauthenticate(with: credential) { _, error in
                if let error = error {
                    // The old password is incorrect
                    self.warningLabel.isHidden = false
                    self.warningLabel.text = "Old password is incorrect"
                } else {
                    // Change the password
                    user.updatePassword(to: newPassword) { error in
                        if let error = error {
                            // Handle password change error
                            print("Error changing password: \(error.localizedDescription)")
                            self.warningLabel.isHidden = false
                            self.warningLabel.text = "Error changing password"
                        } else {
                            // Password successfully changed
                            print("Password changed successfully")
                            self.warningLabel.isHidden = false
                            self.warningLabel.text = "Password changed successfully"
                            self.warningLabel.textColor = UIColor.green
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .dark
        warningLabel.isHidden = true
    }
}
