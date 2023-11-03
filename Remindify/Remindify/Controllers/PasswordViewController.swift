//
//  PasswordViewController.swift
//  Remindify
//
//  Created by Dev on 03/11/2023.
//

import UIKit

class PasswordViewController: UIViewController {

    
    @IBAction func saveChangesButtonPressed(_ sender: UIButton) {
        //pop back to profile 
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
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
