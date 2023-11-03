//
//  ViewController.swift
//  Remindify
//
//  Created by Dev on 03/11/2023.
//

import UIKit

class LoginViewController: UIViewController {

    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!

    @IBAction func loginButtonPressed(_ sender: UIButton) {
        //navigate to profile
        let profileViewController = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        self.navigationController?.pushViewController(profileViewController, animated: true)
    }
    
    @IBAction func signupButtonPressed(_ sender: UIButton) {
        //navigate to signup
        let signupViewController = self.storyboard?.instantiateViewController(withIdentifier: "SignupViewController") as! SignupViewController
        self.navigationController?.pushViewController(signupViewController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }


}

