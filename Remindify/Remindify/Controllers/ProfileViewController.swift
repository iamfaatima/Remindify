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
            profileImageView.frame = CGRect(x: 140, y: 180, width: 120, height: 120)
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
            profileImageView.clipsToBounds = true
            // Ensure that the aspect ratio of the image is maintained
            profileImageView.contentMode = .scaleAspectFill
            profileImageView.image = UIImage(imageLiteralResourceName: "Profile")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadProfileImage()
    }

    func loadProfileImage() {
        if let user = Auth.auth().currentUser, let photoURL = user.photoURL {
            profileImageView.sd_setImage(with: photoURL, placeholderImage: UIImage(named: "Profile"))
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
    
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
//        if let pickedImage = info[.editedImage] as? UIImage {
//            profileImageView.image = pickedImage
//        }
//        dismiss(animated: true, completion: nil)
//    }

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
                    self.activityIndicator.removeFromSuperview()

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

