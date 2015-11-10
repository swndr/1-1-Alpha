//
//  CreateAccountViewController.swift
//  OneToOneAlpha
//
//  Created by Sam Wander on 11/9/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit
import Parse

class CreateAccountViewController: UIViewController {
    
    @IBOutlet weak var codeTextField: UITextField!
    
    var confirmMessage:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var currentUser = PFUser.currentUser()
        print(currentUser)
        if currentUser != nil && currentUser?.username != nil {
            print("found one")
            print(currentUser?.username)
            
            // Do stuff with the user
            confirmMessage = "Logged in user: \(currentUser?.username!)"
            self.performSegueWithIdentifier("loginSegue", sender: nil)
            
        } else {
            print("didn't find one")
            PFAnonymousUtils.logInWithBlock {
                (user: PFUser?, error: NSError?) -> Void in
                if error != nil || user == nil {
                    print("Anonymous login failed.")
                } else {
                    print("Anonymous user logged in: \(user)")
                }
            }
            
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func editingDidChangeOnCode(sender: UITextField) {
        
        
    }
    
    @IBAction func didPressGo(sender: UIButton) {
        
        
            let query = PFQuery(className:"AccountCode")
            query.whereKey("code", equalTo:(self.codeTextField.text!))
            query.findObjectsInBackgroundWithBlock {
                (objects: [PFObject]?, error: NSError?) -> Void in
                
                if error == nil {
                    // The find succeeded.
                    if let objects = objects! as? [PFObject] {
                        print(objects.count)
                        if objects.count == 1 {
                            // Existing code entry
                            let codeObject = objects.first
                            
                            let interval = NSDate().timeIntervalSinceDate((codeObject?.createdAt)!)
                            print(interval)
                            if interval < 3600 {
                                // Less than an hour, can auth this user
                                
                                var user = PFUser.currentUser()
                                //user!.username = self.randomStringWithLength(8) as String
                                user!.username = "testUser4"
                                user!.password = "password"
                                user!["recipient"] = codeObject!["creator"]
                                
                                user!.signUpInBackgroundWithBlock {
                                    (succeeded: Bool, error: NSError?) -> Void in
                                    if let error = error {
                                        let errorString = error.userInfo["error"] as? NSString
                                        // Show the errorString somewhere and let the user try again.
                                        print(errorString)
                                    } else {
                                        print("success: \(succeeded)")
                                        codeObject!["used"] = true
                                        codeObject!.saveInBackground()
                                        
                                        // How to set the recipient for user1?
                                        
                                        // Hooray! Let them use the app now.
                                        self.confirmMessage = "Logged in user: \(user!.username!)"
                                        self.performSegueWithIdentifier("loginSegue", sender: nil)
                                    }
                                }
                                
                                
                                
                            } else {
                                // Expired code
                                print("code expired try again")
                            }

                            
                        
                        } else if objects.count > 1 {
                            print("duplicate")
                        } else {
                            print("does not exist")
                            
                            let randomUsername = self.randomStringWithLength(8) as String
                            
                            var user = PFUser.currentUser()
                            //user!.username = self.randomStringWithLength(8) as String
                            user!.username = "testUser3"
                            user!.password = "password"
                            user!["recipient"] = "pending"
                            
                            user!.signUpInBackgroundWithBlock {
                                (succeeded: Bool, error: NSError?) -> Void in
                                if let error = error {
                                    let errorString = error.userInfo["error"] as? NSString
                                    // Show the errorString somewhere and let the user try again.
                                    print(errorString)
                                } else {
                                    print("success: \(succeeded)")
                                    let accountCode = PFObject(className:"AccountCode")
                                    accountCode["code"] = self.codeTextField.text!
                                    accountCode["used"] = false
                                    accountCode["creator"] = "testUser3"
                                    //accountCode["creator"] = randomUsername
                                    
                                    // permissions...
                                    let acl = PFACL()
                                    acl.setPublicReadAccess(true)
                                    acl.setPublicWriteAccess(true)
                                    accountCode.ACL = acl
                                    
                                    accountCode.saveInBackground()
                                    // Hooray! Let them use the app now.
                                    self.confirmMessage = "Logged in user: \(user!.username!)"
                                    self.performSegueWithIdentifier("loginSegue", sender: nil)
                                }
                            }
                            
                        }
        
                } else {
                    // Log details of the failure
                    print("Error: \(error!) \(error!.userInfo)")
                }
            }
        }
    }
    
    

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "loginSegue"
        {
            if let destinationVC = segue.destinationViewController as? LoggedInViewController {
                destinationVC.receivedMessage = confirmMessage
            }
        }
    }
    
    
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        var randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            var length = UInt32 (letters.length)
            var rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
    
    
    
    
}