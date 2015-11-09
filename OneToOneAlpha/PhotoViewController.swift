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
    var receivedImage:UIImage!
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var sentImageContainer: UIImageView!
    @IBOutlet weak var receivedImageContainer: UIImageView!
    
    var currentUser = PFUser.currentUser()
    
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
                        
                        // permissions...
//                        let acl = PFACL()
//                        acl.setPublicReadAccess(true)
//                        acl.setPublicWriteAccess(true)
//                        userPhoto.ACL = acl
                        
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
        var query = PFQuery(className:"SentPhoto")
        query.whereKey("recipient", equalTo:(self.currentUser?.username)!)
        query.whereKey("viewed", equalTo:(0))
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // The find succeeded.
                print("Successfully retrieved \(objects!.count) photos.")
                // Do something with the found objects
                if let objects = objects! as? [PFObject] {
                    
                    for object in objects {
                        
                        let imageFile = object["imageFile"]
                        print(object["viewed"])
                        print(imageFile)
                        
                        if imageFile != nil {
                            let data:NSData!
                            let error:NSError!
                            imageFile!.getDataInBackgroundWithBlock({ (data, error) -> Void in
                                if error == nil {
                                    self.receivedImageContainer.image = UIImage(data: data!)
                                    object["viewed"] = true
                                    print(object)
                                }
                                //print(data)
                                
                            })
                        }
                        //print(object.objectId)
                    }
                }
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.userInfo)")
            }
        }
    }
    
    
    @IBAction func didPressLogout(sender: UIButton) {
        
        PFUser.logOut()
        currentUser = PFUser.currentUser() // this will now be nil
        self.navigationController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }

}
