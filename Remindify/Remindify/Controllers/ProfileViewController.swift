import UIKit
import SDWebImage
import MBProgressHUD

class ProfileViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var changeImageButton: UIButton!
    @IBOutlet weak var changePassword: UIButton!
    
    let saveButton = UIButton(type: .custom)
    
    override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()

            FirebaseService.shared.checkUserAuthentication { [weak self] isLoggedIn in
                guard let self = self else { return }

                if isLoggedIn {
                    // User is logged in, load profile information
                    self.loadProfileInformation()
                } else {
                    // User is not logged in, show session expired popup and navigate to login view controller
                    self.showSessionExpiredPopup()
                    let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                    self.navigationController?.pushViewController(loginViewController, animated: true)
                }
            }
        }

    func loadProfileInformation() {
            FirebaseService.shared.getCurrentUser { [weak self] user in
                guard let self = self else { return }

                if let user = user {
                    let userName = user.displayName
                    let userEmail = user.email
                    self.emailTextField.text = userEmail
                    self.nameTextField.text = userName
                    self.loadProfileImage()
                } else {
                    self.warningLabel.isHidden = false
                    self.warningLabel.text = "Error loading"
                }
            }
        }
    
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
    
    @IBAction func changePasswordButtonPressed(_ sender: UIButton) {
        // Navigate to home/profile
        let passwordViewController = self.storyboard?.instantiateViewController(withIdentifier: "PasswordViewController") as! PasswordViewController
        self.navigationController?.pushViewController(passwordViewController, animated: true)
    }
    
    @objc func saveNameButtonPressed() {
           guard let updatedName = nameTextField.text, !updatedName.isEmpty else {
               DispatchQueue.main.async {
                   self.warningLabel.isHidden = false
                   self.warningLabel.text = "Name Field can't be empty"
               }
               print("Name Field can't be empty")
               return
           }

           // Use FirebaseService to update the user's display name
           FirebaseService.shared.updateDisplayName(updatedName) { [weak self] error in
               if let error = error {
                   DispatchQueue.main.async {
                       self?.warningLabel.isHidden = false
                       self?.warningLabel.text = "Error updating user profile: \(error.localizedDescription)"
                   }
               } else {
                   DispatchQueue.main.async {
                       self?.warningLabel.isHidden = false
                       self?.warningLabel.text = "User profile updated successfully"
                       self?.warningLabel.textColor = UIColor.white
                   }
               }
           }

           // Disable the save button after saving
           saveButton.isEnabled = false
       }

    @objc func textFieldDidChange(_ textField: UITextField) {
        // Enable the save button when the name text field is edited
        saveButton.isEnabled = true
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
    
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
           if let pickedImage = info[.editedImage] as? UIImage {
               // Show a loading indicator using MBProgressHUD
               let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
               self.navigationController?.navigationBar.isUserInteractionEnabled = false
               hud.mode = .indeterminate
               hud.label.text = "Uploading Image..."

               FirebaseService.shared.uploadProfileImage(image: pickedImage) { [weak self] result in
                   guard let self = self else { return }

                   // Hide the loading indicator
                   MBProgressHUD.hide(for: self.view, animated: true)
                   self.navigationController?.navigationBar.isUserInteractionEnabled = true

                   switch result {
                   case .success(let downloadURL):
                       // Image uploaded successfully
                       print("Image uploaded to Firebase Storage")

                       // Set the user's photoURL
                       FirebaseService.shared.updateUserProfilePhotoURL(downloadURL) { error in
                           if let error = error {
                               print("Error setting photoURL: \(error.localizedDescription)")
                           } else {
                               print("photoURL set in Firebase Authentication profile")

                               // Use SDWebImage to display the image
                               self.profileImageView.sd_setImage(with: downloadURL, placeholderImage: pickedImage)
                           }
                       }

                   case .failure(let error):
                       // Handle the error
                       print("Error uploading image: \(error.localizedDescription)")
                   }
               }
           }

           dismiss(animated: true, completion: nil)
       }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss(animated: true, completion: nil)
        }
}

extension ProfileViewController{
    
    func setUpImageViewConstraints() {
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.heightAnchor.constraint(equalToConstant: 160).isActive = true
        profileImageView.widthAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70).isActive = true
    }
    
    func setUpChangeImageConstraints() {
        changeImageButton.translatesAutoresizingMaskIntoConstraints = false
        //changeImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 60).isActive = true
        changeImageButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16).isActive = true
    }
    
    func setUpNameTextFieldConstraints() {
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.heightAnchor.constraint(equalToConstant: 37).isActive = true
        nameTextField.widthAnchor.constraint(equalToConstant: 207).isActive = true
        nameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        nameTextField.topAnchor.constraint(equalTo: changeImageButton.bottomAnchor, constant: 38.8).isActive = true
    }
    
    func setUpWarningLabelConstraints() {
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        warningLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 8).isActive = true
        warningLabel.adjustsFontSizeToFitWidth = true
    }
    
    func setUpEmailTextFieldConstraints() {
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.heightAnchor.constraint(equalToConstant: 37).isActive = true
        emailTextField.widthAnchor.constraint(equalToConstant: 206).isActive = true
        emailTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emailTextField.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 38.8).isActive = true
    }
    
    func setUpPasswordButtonConstraints() {
        changePassword.translatesAutoresizingMaskIntoConstraints = false
        //changePassword.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 60).isActive = true
        changePassword.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16).isActive = true
    }
    
    
    
    func setupUI(){
        setUpImageViewConstraints()
        setUpChangeImageConstraints()
        setUpNameTextFieldConstraints()
        setUpWarningLabelConstraints()
        setUpEmailTextFieldConstraints()
        setUpPasswordButtonConstraints()
        
        navigationController?.navigationBar.tintColor = UIColor.white
        view.backgroundColor = .dark
        
        loadProfileImage()
        
        profileImageView.frame = CGRect(x: 140, y: 140, width: 120, height: 120)
        // Make the profile image view round
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        // Center the buttons
        changeImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        changePassword.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        changePassword.tintColor = .white
        changeImageButton.tintColor = .white
        warningLabel.textColor = UIColor.red
        
        activityIndicator.isHidden = true
        warningLabel.isHidden = true
        nameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        saveButton.isEnabled = false
        emailTextField.isUserInteractionEnabled = false
        emailTextField.isEnabled = false
        emailTextField.textColor = .gray
        emailTextField.backgroundColor = .lightGray
        
        // Save button
        let saveImageSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular, scale: .small)
        let saveImage = UIImage(systemName: "checkmark.circle.fill", withConfiguration: saveImageSymbolConfiguration)?.withTintColor(.dark, renderingMode: .alwaysOriginal)
        
        // Create a UIButton and set the image as its background
        
        saveButton.setImage(saveImage, for: .normal)
        saveButton.tintColor = .white
        saveButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30) // Adjust the size as needed
        
        saveButton.addTarget(self, action: #selector(saveNameButtonPressed), for: .touchUpInside)
        
        // Set the UIButton as the right view of the name text field
        nameTextField.rightView = saveButton
        nameTextField.rightViewMode = .whileEditing // Show the right view always
        
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 100, weight: .regular, scale: .large)
        
        // Create a white symbol image
        let symbolImage = UIImage(systemName: "person.circle.fill", withConfiguration: symbolConfiguration)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        
        // Set the profileImageView's image to the white symbol image
        profileImageView.image = symbolImage
    }
    
    func loadProfileImage() {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 100, weight: .regular, scale: .large)
        // Create a white symbol image
        let symbolImage = UIImage(systemName: "person.circle.fill", withConfiguration: symbolConfiguration)?.withTintColor(.white, renderingMode: .alwaysOriginal)

        FirebaseService.shared.getCurrentUserPhotoURL { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let photoURL):
                // Use SDWebImage to display the image
                self.profileImageView.sd_setImage(with: photoURL, placeholderImage: symbolImage)

            case .failure(let error):
                print("Error loading profile image: \(error.localizedDescription)")
                // Use the symbol image as a placeholder
                self.profileImageView.image = symbolImage
            }
        }
    }

    
}
