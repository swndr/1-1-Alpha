/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse

class OnboardViewController: UIViewController {

    @IBOutlet weak var accountSegmentedControl: UISegmentedControl!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var recipientTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var currentUser = PFUser.currentUser()
        if currentUser != nil {
            print("found one")
            print(currentUser?.username)
            // Do stuff with the user
            self.performSegueWithIdentifier("openPhotoView", sender: nil)
        } else {
            print("didn't find one")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func didChangeSignInType(sender: UISegmentedControl) {
        
        if accountSegmentedControl.selectedSegmentIndex == 0 {
            
            recipientLabel.hidden = false
            recipientTextField.hidden = false
            
        } else {
            
            recipientLabel.hidden = true
            recipientTextField.hidden = true
            recipientTextField.text?.removeAll()
            
        }
        
    }
    
    @IBAction func didPressGo(sender: UIButton) {
        
        if accountSegmentedControl.selectedSegmentIndex == 0 {
            print("sign up")
            
            var user = PFUser()
            user.username = usernameTextField.text
            user.password = passwordTextField.text
            user["recipient"] = recipientTextField.text
            
            user.signUpInBackgroundWithBlock {
                (succeeded: Bool, error: NSError?) -> Void in
                if let error = error {
                    let errorString = error.userInfo["error"] as? NSString
                    // Show the errorString somewhere and let the user try again.
                    print(errorString)
                } else {
                    // Hooray! Let them use the app now.
                    self.performSegueWithIdentifier("openPhotoView", sender: nil)
                }
            }
            
        } else {
            print("log in")
            
            PFUser.logInWithUsernameInBackground(usernameTextField.text!, password: passwordTextField.text!) {
                (user: PFUser?, error: NSError?) -> Void in
                if user != nil {
                    // Do stuff after successful login.
                    self.performSegueWithIdentifier("openPhotoView", sender: nil)
                } else {
                    // The login failed. Check error to see why.
                }
            }
            
            
            
            
        }
        
    }
    
    
    
}
