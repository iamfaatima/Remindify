//  ViewController.swift
//  Remindify
//
//  Created by Dev on 03/11/2023.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBAction func homeNavigation(_ sender: UIButton) {
        //navigate to home
        let homeViewController = self.storyboard?.instantiateViewController(withIdentifier: "HomeReminderTableViewController") as! HomeReminderTableViewController
        self.navigationController?.pushViewController(homeViewController, animated: true)
    }
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!

    @IBAction func loginButtonPressed(_ sender: UIButton) {
        
        let userEmail = emailTextField.text
        let userPassword = passwordTextField.text
        //create user
        if let email = userEmail, let password = userPassword{
        Auth.auth().signIn(withEmail: email, password: password) {authResult, error in
            if let error = error {
                print(error.localizedDescription)
                if error.localizedDescription == "An internal error has occurred, print and inspect the error details for more information."{
                    DispatchQueue.main.async {
                        self.warningLabel.isHidden = false
                        self.warningLabel.text = "Wrong username or password. Try again. "
                    }
                }else{
                    DispatchQueue.main.async {
                        self.warningLabel.isHidden = false
                        self.warningLabel.text = "\(error.localizedDescription)"
                    }
                }
                
            } else {
                //navigate to profile
                let profileViewController = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                self.navigationController?.pushViewController(profileViewController, animated: true)
            }
        }
        }else{
            DispatchQueue.main.async {
                self.warningLabel.isHidden = false
                self.warningLabel.text = "An error occured. Try again."
            }
        }
        
        
    }
    
    @IBAction func signupButtonPressed(_ sender: UIButton) {
        //navigate to signup
        let signupViewController = self.storyboard?.instantiateViewController(withIdentifier: "SignupViewController") as! SignupViewController
        self.navigationController?.pushViewController(signupViewController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.warningLabel.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        self.warningLabel.isHidden = true
    }
}
