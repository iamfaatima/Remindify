//
//  SignupViewController.swift
//  Remindify
//
//  Created by Dev on 03/11/2023.
//

import UIKit

class SignupViewController: UIViewController {

    
    @IBAction func signupButtonPressed(_ sender: UIButton) {
        //navigate to home/profile
        let profileViewController = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        self.navigationController?.pushViewController(profileViewController, animated: true)
    }
    
    @IBAction func accountExistsButtonPressed(_ sender: Any) {
        //navigate to login
        if let navigationController = self.navigationController {
            navigationController.popToRootViewController(animated: true)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

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
