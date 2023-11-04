//
//  SignupViewController.swift
//  Remindify
//
//  Created by Dev on 03/11/2023.
//

import UIKit
import FirebaseCore
import FirebaseAuth

class SignupViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var warningTextField: UILabel!
    
    @IBAction func signupButtonPressed(_ sender: UIButton) {
        if let name = nameTextField.text, let email = emailTextField.text, let password = passwordTextField.text {
               if password == confirmPasswordTextField.text {
                   Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                       if let error = error {
                           print(error.localizedDescription)
                           DispatchQueue.main.async {
                               self.warningTextField.isHidden = false
                               self.warningTextField.text = "\(error.localizedDescription)"
                           }
                       } else {
                           // Successfully created the user, now save the user's name
                           if let user = Auth.auth().currentUser {
                               // Create a user profile change request
                               let changeRequest = user.createProfileChangeRequest()
                               changeRequest.displayName = name
                               
                               // Commit the changes to the user's profile
                               changeRequest.commitChanges { error in
                                   if let error = error {
                                       DispatchQueue.main.async {
                                           self.warningTextField.isHidden = false
                                           self.warningTextField.text = "\(error.localizedDescription)"
                                       }
                                   } else {
                                       DispatchQueue.main.async {
                                           self.warningTextField.isHidden = false
                                           self.warningTextField.text = "User profile updated successfully"
                                           self.warningTextField.textColor = UIColor.green
                                       }
                                   }
                               }
                               
                               // Navigate to home/profile
                               let profileViewController = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                               self.navigationController?.pushViewController(profileViewController, animated: true)
                           }
                       }
                   }
               } else {
                   self.warningTextField.isHidden = false
                   self.warningTextField.text = "Password and Confirm Password does not match"
               }
           }
    }
    
    @IBAction func accountExistsButtonPressed(_ sender: Any) {
        //navigate to login
        if let navigationController = self.navigationController {
            navigationController.popToRootViewController(animated: true)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        warningTextField.isHidden = true
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
