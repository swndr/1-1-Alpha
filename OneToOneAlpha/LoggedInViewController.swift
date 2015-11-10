//
//  LoggedInViewController.swift
//  OneToOneAlpha
//
//  Created by Sam Wander on 11/10/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit
import Parse

class LoggedInViewController: UIViewController {

    var receivedMessage = "pending"
    @IBOutlet weak var confirmText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        confirmText.text = receivedMessage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didLogOut(sender: UIButton) {
        
        PFUser.logOut()
        //let currentUser = PFUser.currentUser() // this will now be nil
        self.navigationController?.popToRootViewControllerAnimated(true)
    }

}
