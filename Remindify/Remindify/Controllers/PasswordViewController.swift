import UIKit
import FirebaseAuth

class PasswordViewController: UIViewController {

    @IBOutlet weak var oldPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var saveChangesButton: UIButton!

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
                            self.warningLabel.textColor = UIColor.red
                        } else {
                            // Password successfully changed
                            print("Password changed successfully")
                            self.warningLabel.isHidden = false
                            self.warningLabel.text = "Password changed successfully"
                            self.warningLabel.textColor = UIColor.white
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
        warningLabel.text = ""
        saveChangesButton?.tintColor = .white
        navigationController?.navigationBar.tintColor = UIColor.white
        setUpConstraints()
    }

    func setUpConstraints() {
        oldPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        newPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        confirmPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        saveChangesButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // oldPasswordTextField
            oldPasswordTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            oldPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            oldPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // newPasswordTextField
            newPasswordTextField.topAnchor.constraint(equalTo: oldPasswordTextField.bottomAnchor, constant: 20),
            newPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            newPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // confirmPasswordTextField
            confirmPasswordTextField.topAnchor.constraint(equalTo: newPasswordTextField.bottomAnchor, constant: 20),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // warningLabel
            warningLabel.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 20),
            warningLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // saveChangesButton
            saveChangesButton.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 20),
            saveChangesButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveChangesButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveChangesButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}
