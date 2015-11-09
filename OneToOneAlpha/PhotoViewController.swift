//
//  PhotoViewController.swift
//  OneToOneAlpha
//
//  Created by Sam Wander on 11/8/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit
import Photos
import Parse

class PhotoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var sentImage:UIImage!
    //var receivedImage:UIImage!
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var sentImageContainer: UIImageView!
    @IBOutlet weak var receivedImageContainer: UIImageView!
    
    var dismissReceivedPhotoGesture:UIGestureRecognizer = UITapGestureRecognizer()
    
    var currentUser = PFUser.currentUser()
    
    var receivedImageIDs = [Int:String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        
        sentImageContainer.contentMode = .ScaleAspectFill
        sentImageContainer.clipsToBounds = true
        
        receivedImageContainer.contentMode = .ScaleAspectFill
        receivedImageContainer.clipsToBounds = true
        
        getNewPhotos()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func didPressChooseImage(sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
//        imagePicker.sourceType = .Camera // can't do without physical device
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]) {
            
            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                sentImage = pickedImage
                sentImageContainer.image = sentImage
                
            }
                    
            dismissViewControllerAnimated(true) { () -> Void in
                
                let imageURL = info[UIImagePickerControllerReferenceURL] as? NSURL
                print(imageURL)
                
                let fetchAssets = PHAsset.fetchAssetsWithALAssetURLs([imageURL!], options: nil)
                let asset = fetchAssets.lastObject as! PHAsset
                let options = PHImageRequestOptions()
                options.synchronous = true
                print(asset)
                
                PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: CGSize(width: 240.0, height: 240.0), contentMode: .AspectFill, options: options, resultHandler: { (result, info) -> Void in
                    
                    if let compressedImage = result {
                        let imageData = UIImagePNGRepresentation(compressedImage)
                        let imageFile = PFFile(name:"image.png", data:imageData!)
                        
                        let userPhoto = PFObject(className:"SentPhoto")
                        userPhoto["recipient"] = self.currentUser!["recipient"]
                        userPhoto["viewed"] = false
                        userPhoto["imageFile"] = imageFile
                        
                        var recipient = PFUser()
                        let query = PFUser.query()
                        query!.whereKey("username", equalTo:(self.currentUser!["recipient"]))
                        
                        do {
                            recipient = try query!.getFirstObject() as! PFUser
                            print("Recipient \(recipient)")
                        } catch {
                            print(error)
                        }
                        
                        // permissions...
                        let acl = PFACL()
                        acl.setPublicReadAccess(true)
                        acl.setWriteAccess(true, forUser: recipient)
                        acl.setPublicWriteAccess(true)
                        userPhoto.ACL = acl
                        
                        userPhoto.saveInBackground()
                        print("saved")
                    }
                })
            
            }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func getNewPhotos() {
        let query = PFQuery(className:"SentPhoto")
        query.whereKey("recipient", equalTo:(self.currentUser?.username)!)
        //query.whereKey("viewed", equalTo:"false") // not viewed yet
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // The find succeeded.
                print("Successfully retrieved \(objects!.count) photos.")
                if let objects = objects! as? [PFObject] {
                    
                    for object in objects {
                        
                        let imageFile = object["imageFile"]
                        print("Viewed: \(object["viewed"])")
                        print(imageFile)
                        
                        if imageFile != nil {
//                          let data:NSData!
//                          let error:NSError!
                            
                            imageFile!.getDataInBackgroundWithBlock({ (data, error) -> Void in
                                
                                if error == nil {
                                    
                                    let receivedImage:UIImageView = UIImageView(frame: CGRect(x: 67, y: 364, width: 240, height: 240))
                                    self.dismissReceivedPhotoGesture = UITapGestureRecognizer(target: self, action: "didDismissReceivedPhoto:")
                                    receivedImage.addGestureRecognizer(self.dismissReceivedPhotoGesture)
                                    receivedImage.userInteractionEnabled = true
                                    self.view.addSubview(receivedImage)
                                    
                                    receivedImage.image = UIImage(data: data!)
                                    
                                    self.receivedImageIDs[receivedImage.hash] = object.objectId!
                                    print(self.receivedImageIDs)
                                }
                                
                                }, progressBlock: { (percentDone: Int32) -> Void in
                                    print("Progress: \(percentDone)")
                            })
                        }
                    }
                }
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.userInfo)")
            }
        }
    }
    
    func didDismissReceivedPhoto(sender:UITapGestureRecognizer) {
        
        print("tapped")
        let id = self.receivedImageIDs[sender.view!.hash]
        print(id)
        
        
        let query = PFQuery(className:"SentPhoto")
        query.getObjectInBackgroundWithId(id!) {
            (imageToUpdate: PFObject?, error: NSError?) -> Void in
            if error != nil {
                print(error)
            } else if let imageToUpdate = imageToUpdate {
                imageToUpdate["viewed"] = true
                print(imageToUpdate)
                imageToUpdate.saveInBackground()
            }
        }

//        do {
//            let imageToUpdate = try PFQuery.getObjectOfClass("SentPhoto", objectId: id!)
//            imageToUpdate["viewed"] = true
//            imageToUpdate.saveInBackground()
//            imageToUpdate.saveInBackgroundWithBlock({ (success, error) -> Void in
//                if (success) {
//                    print("saved")
//                    // The object has been saved.
//                } else {
//                    // There was a problem, check error.description
//                }
//            })
//            print(imageToUpdate)
//        } catch {
//            print(error)
//        }
        
        sender.view!.removeFromSuperview()
    }
    
    
    @IBAction func didPressLogout(sender: UIButton) {
        
        PFUser.logOut()
        currentUser = PFUser.currentUser() // this will now be nil
        self.navigationController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }

}
