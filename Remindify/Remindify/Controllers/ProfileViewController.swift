import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import Firebase
import FirebaseStorage
import SDWebImage

class ProfileViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var changeImageButton: UIButton!
    @IBOutlet weak var changePassword: UIButton!
    
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
        view.backgroundColor = .white
        
        activityIndicator.isHidden = true
        warningLabel.isHidden = true
        nameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
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

            loadProfileImage()

            // Make the profileImageView rounded
            profileImageView.frame = CGRect(x: 140, y: 140, width: 120, height: 120)
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
            profileImageView.clipsToBounds = true
            // Ensure that the aspect ratio of the image is maintained
            profileImageView.contentMode = .scaleAspectFill
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupUI()
        loadProfileImage()
    }

    func loadProfileImage() {
        if let user = Auth.auth().currentUser, let photoURL = user.photoURL {
            profileImageView.sd_setImage(with: photoURL, placeholderImage: UIImage(named: "person.circle.fill"))
        }
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
    
    func setupUI() {
        // Customize the appearance of the activityIndicator
        activityIndicator.style = .whiteLarge
            activityIndicator.color = UIColor.systemBlue // Adjust the color as needed
            activityIndicator.center = view.center
            activityIndicator.hidesWhenStopped = true // Hide when not animating

            // Constraints for the activityIndicator
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        // Apply styling and constraints for the profileImageView
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.layer.shadowColor = UIColor.white.cgColor
        profileImageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        profileImageView.layer.shadowRadius = 4
        profileImageView.layer.shadowOpacity = 0.5
        profileImageView.alpha = 0.8

        // Customize the appearance of the changeImageButton
        changeImageButton.backgroundColor = .clear
        changeImageButton.setTitleColor(UIColor(red: 46/255, green: 139/255, blue: 87/255, alpha: 1.0), for: .normal) // Sea green text color
        changeImageButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16) // Bold font
        changeImageButton.layer.cornerRadius = 8
        changeImageButton.layer.borderWidth = 1
        changeImageButton.layer.borderColor = UIColor(red: 46/255, green: 139/255, blue: 87/255, alpha: 1.0).cgColor // Sea green border color
        changeImageButton.clipsToBounds = true
        changeImageButton.alpha = 0.8

        // Customize the appearance of the changePassword button
        changePassword.backgroundColor = .clear
        changePassword.setTitleColor(UIColor(red: 46/255, green: 139/255, blue: 87/255, alpha: 1.0), for: .normal) // Sea green text color
        changePassword.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16) // Bold font
        changePassword.layer.cornerRadius = 8
        changePassword.layer.borderWidth = 1
        changePassword.layer.borderColor = UIColor(red: 46/255, green: 139/255, blue: 87/255, alpha: 1.0).cgColor // Sea green border color
        changePassword.clipsToBounds = true
        changePassword.alpha = 0.8

        // Constraints for profileImageView
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true

        // Constraints for changeImageButton (customized above)
        changeImageButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 20).isActive = true
        changeImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        // Constraints for nameTextField (customize as needed)
        nameTextField.topAnchor.constraint(equalTo: changeImageButton.bottomAnchor, constant: 20).isActive = true
        nameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        // Constraints for warningLabel (customize as needed)
        warningLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20).isActive = true
        warningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        // Constraints for emailTextField (customize as needed)
        emailTextField.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 20).isActive = true
        emailTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        // Constraints for changePassword button (customized above)
        changePassword.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20).isActive = true
        changePassword.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        // Constraints for saveButton (customize as needed)
        saveButton.topAnchor.constraint(equalTo: changePassword.bottomAnchor, constant: 20).isActive = true
        saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let pickedImage = info[.editedImage] as? UIImage {
            // Show a loading indicator
            activityIndicator.color = UIColor.darkGray
            activityIndicator.isHidden = false
            activityIndicator.center = self.view.center
            activityIndicator.startAnimating()
            self.view.addSubview(activityIndicator)

            // Upload the image to Firebase Storage
            let storage = Storage.storage()
            let storageRef = storage.reference().child("images/\(UUID().uuidString).jpg")

            if let imageData = pickedImage.jpegData(compressionQuality: 0.8) {
                let uploadTask = storageRef.putData(imageData, metadata: nil) { (metadata, error) in
                    // Remove the loading indicator
                    self.activityIndicator.stopAnimating()
                    //self.activityIndicator.removeFromSuperview()

                    guard error == nil else {
                        // Handle the error
                        print("Error uploading image: \(error!.localizedDescription)")
                        return
                    }

                    // Image uploaded successfully
                    print("Image uploaded to Firebase Storage")

                    // Show a loading indicator while retrieving the download URL
                    let loadingLabel = UILabel()
                    loadingLabel.text = "Loading..."
                    loadingLabel.center = self.view.center
                    self.view.addSubview(loadingLabel)

                    // Get the download URL
                    storageRef.downloadURL { (url, error) in
                        // Remove the loading label
                        loadingLabel.removeFromSuperview()

                        if let downloadURL = url {
                            if let user = Auth.auth().currentUser {
                                // Set the user's photoURL
                                let changeRequest = user.createProfileChangeRequest()
                                changeRequest.photoURL = downloadURL
                                changeRequest.commitChanges { error in
                                    if let error = error {
                                        print("Error setting photoURL: \(error.localizedDescription)")
                                    } else {
                                        print("photoURL set in Firebase Authentication profile")

                                        // Use SDWebImage to display the image
                                        self.profileImageView.sd_setImage(with: downloadURL, placeholderImage: pickedImage)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }


    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

