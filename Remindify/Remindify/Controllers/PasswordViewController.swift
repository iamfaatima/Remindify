import UIKit
import FirebaseAuth


class PasswordViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var oldPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var saveChangesButton: UIButton!
    
    var updateAlert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
        
        // Check if the user is logged in using FirebaseService
        FirebaseService.shared.checkUserAuthentication { [weak self] isAuthenticated in
            guard let self = self else { return }

            if !isAuthenticated {
                self.showSessionExpiredPopup()
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
    }
    // MARK: - Actions

    @IBAction func saveChangesButtonPressed(_ sender: UIButton) {
        guard let newPassword = newPasswordTextField.text, let confirmPassword = confirmPasswordTextField.text, newPassword == confirmPassword else {
            showPasswordMismatchWarning()
            return
        }
        
        // Check if the user is logged in
        guard let user = FirebaseService.shared.currentUser else {
            // User is not logged in, handle the error or show a relevant message
            return
        }

        reauthenticateUser(user: user, oldPassword: oldPasswordTextField.text, newPassword: newPassword)
    }

    // MARK: - Private Methods

    private func reauthenticateUser(user: User, oldPassword: String?, newPassword: String) {
        guard let email = user.email, let oldPassword = oldPassword else {
            // Handle the missing information
            showNilFieldWarning()
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        FirebaseService.shared.reauthenticateUser(with: credential) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.showIncorrectPasswordWarning()
            } else {
                self.changeUserPassword(user: user, newPassword: newPassword)
            }
        }
    }

    private func changeUserPassword(user: User, newPassword: String) {
        FirebaseService.shared.changeUserPassword(user: user, newPassword: newPassword) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.handlePasswordChangeError(error: error)
            } else {
                self.showPasswordChangeSuccess()
            }
        }
    }

    private func expireSessionAndNavigateToLogin() {
        FirebaseService.shared.signOut { [weak self] success, error in
            guard let self = self else { return }

            if let error = error {
                print("Error while signing out: \(error)")
                // Handle the error, show an alert, or take appropriate action
            } else if success {
                // Show an alert or loading indicator if needed
                self.updateAlert = UIAlertController(title: "Logging Out", message: nil, preferredStyle: .alert)
                self.present(self.updateAlert!, animated: true, completion: nil)
                
                // Add a delay to dismiss the alert after a few seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.updateAlert?.dismiss(animated: true) {
                        // Navigate back to the previous view controller
                        let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                        self.navigationController?.pushViewController(loginViewController, animated: true)
                    }
                }
            }
        }
    }



    private func showNilFieldWarning() {
        warningLabel.isHidden = false
        warningLabel.text = "Field can't be empty"
    }

    private func showIncorrectPasswordWarning() {
        warningLabel.isHidden = false
        warningLabel.text = "Old password is incorrect"
    }
    
    private func showPasswordMismatchWarning() {
        warningLabel.isHidden = false
        warningLabel.text = "Password and confirm password do not match"
    }
    
    private func handlePasswordChangeError(error: Error) {
        print("Error changing password: \(error.localizedDescription)")
        warningLabel.isHidden = false
        warningLabel.text = "Error changing password"
        warningLabel.textColor = .red
    }
    
    private func showPasswordChangeSuccess() {
        print("Password changed successfully")
        warningLabel.isHidden = false
        warningLabel.text = "Password changed successfully"
        warningLabel.textColor = .white
        // Expire the session and navigate to LoginViewController
        expireSessionAndNavigateToLogin()
    }
    
    // MARK: - Private UI Setup Methods
    
    private func setupView() {
        view.backgroundColor = .dark
        warningLabel.isHidden = true
        warningLabel.text = ""
        saveChangesButton?.tintColor = .white
        navigationController?.navigationBar.tintColor = .white
    }
    
    private func setupConstraints() {
        let textFields = [oldPasswordTextField, newPasswordTextField, confirmPasswordTextField, warningLabel, saveChangesButton]
        
        textFields.forEach { textField in
            textField?.translatesAutoresizingMaskIntoConstraints = false
        }
        
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
