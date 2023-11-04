import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBAction func changeImageButtonPressed(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true

            let alert = UIAlertController(title: "Change Profile Picture", message: "Select the source for your profile picture.", preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                imagePicker.sourceType = .camera
                self?.present(imagePicker, animated: true, completion: nil)
            })

            alert.addAction(UIAlertAction(title: "Gallery", style: .default) { [weak self] _ in
                imagePicker.sourceType = .photoLibrary
                self?.present(imagePicker, animated: true, completion: nil)
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(alert, animated: true, completion: nil)
    }
    
    @IBAction func saveNameButton(_ sender: UIButton) {
        // Validate the name before saving
        guard let updatedName = nameTextField.text, !updatedName.isEmpty else {
            DispatchQueue.main.async {
                self.warningLabel.isHidden = false
                self.warningLabel.text = "Name Field can't be empty"
            }
            print("Name Field can't be empty")
            return
        }

        
        // Update the user's display name in Firebase
        if let user = Auth.auth().currentUser {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = updatedName
            changeRequest.commitChanges { error in
                if let _ = error {
                    DispatchQueue.main.async {
                        self.warningLabel.isHidden = false
                        self.warningLabel.text = "Error updating user profile"
                    }
                } else {
                    DispatchQueue.main.async {
                        self.warningLabel.isHidden = false
                        self.warningLabel.text = "User profile updated successfully"
                        self.warningLabel.textColor = UIColor.green
                    }
                }
            }
        }else{
            DispatchQueue.main.async {
                self.warningLabel.isHidden = false
                self.warningLabel.text = "Error. Try Again."
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        warningLabel.isHidden = true
        
        nameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Disable the save button initially
        saveButton.isEnabled = false

        emailTextField.isUserInteractionEnabled = false
        emailTextField.isEnabled = false
        emailTextField.textColor = .gray
        emailTextField.backgroundColor = .lightGray

        if let user = Auth.auth().currentUser {
            let userName = user.displayName
            let userEmail = user.email
            emailTextField.text = userEmail
            nameTextField.text = userName
        }
        
        // Make the profileImageView rounded
           profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
           profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(imageLiteralResourceName: "Profile")
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        // Enable the save button when the name text field is edited
        saveButton.isEnabled = true
    }
    
    @IBAction func changePasswordButtonPressed(_ sender: UIButton) {
        // Navigate to home/profile
        let passwordViewController = self.storyboard?.instantiateViewController(withIdentifier: "PasswordViewController") as! PasswordViewController
        self.navigationController?.pushViewController(passwordViewController, animated: true)
    }
    
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let pickedImage = info[.editedImage] as? UIImage {
            profileImageView.image = pickedImage
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
