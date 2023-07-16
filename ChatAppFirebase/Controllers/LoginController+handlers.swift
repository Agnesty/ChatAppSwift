//
//  LoginController+handlers.swift
//  ChatAppFirebase
//
//  Created by Agnes Triselia Yudia on 15/07/23.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @objc func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[.originalImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        print("Canceled picker")
    }
    
    private func registerUserIntoDatabaseWithUID(uid: String, values: [String: AnyObject]) {
        let ref = Database.database().reference(fromURL: "https://authentication-project-267a4-default-rtdb.asia-southeast1.firebasedatabase.app")
        let userReference = ref.child("users").child(uid)
        
        userReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print("Ini error karena: \(String(describing:err))")
                return
            }
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    func handleRegister() {
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            print("Form is not valid")
            return
        }
        
        // Create User or Register
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            
            if error != nil {
                print("Register error: \(String(describing: error?.localizedDescription))")
                return
            }
            
            guard let uid = authResult?.user.uid else {
                print("Failed retrieving user uid")
                return
            }
            
            //successfully authenticated user saved to realtime database (image, email, and name)
            let imageName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).png")
            
            if let uploadData = self.profileImageView.image?.pngData() {
                storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                    if let error = error {
                        print(error)
                        return
                    }

                    storageRef.downloadURL { (url, error) in
                        if let error = error {
                            print(error)
                            return
                        }

                        if let profileImageUrl = url?.absoluteString {
                            let values: [String: AnyObject] = ["name": name as AnyObject, "email": email as AnyObject, "profileImageURL": profileImageUrl as AnyObject]
                            self.registerUserIntoDatabaseWithUID(uid: uid, values: values)
                            if let navigationController = self.presentingViewController as? UINavigationController,
                               let messageController = navigationController.viewControllers.first as? MessagesController {
                                messageController.navigationItem.title = name
                            }
                        }
                    }
                }
            )}
        }
    }
}


