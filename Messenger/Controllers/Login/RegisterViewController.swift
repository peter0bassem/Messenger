//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Peter Bassem on 7/20/20.
//  Copyright © 2020 Peter Bassem. All rights reserved.
//

import UIKit
import Firebase
import JGProgressHUD

final class RegisterViewController: UIViewController {
    
    private lazy var spinner: JGProgressHUD = {
        let spinner = JGProgressHUD(style: .dark)
        return spinner
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        scrollView.isUserInteractionEnabled = true
        return scrollView
    }()
    
    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePicture(_:)))
        //        gesture.numberOfTouchesRequired = 1
        //        gesture.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(gesture)
        
        return imageView
    }()
    
    private lazy var firstNameTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "First Name"
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .secondarySystemBackground
        textField.keyboardType = .emailAddress
        textField.delegate = self
        return textField
    }()
    
    private lazy var lastNameTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Last Name"
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .secondarySystemBackground
        textField.keyboardType = .emailAddress
        textField.delegate = self
        return textField
    }()
    
    private lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Email"
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .secondarySystemBackground
        textField.keyboardType = .emailAddress
        textField.delegate = self
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Password"
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .secondarySystemBackground
        textField.isSecureTextEntry = true
        textField.delegate = self
        return textField
    }()
    
    private lazy var registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.addTarget(self, action: #selector(didTapLogginButton(_:)), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        title = "Register"
        view.backgroundColor = .systemBackground
        
        //        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegisterButton(_:)))
        
        view.addSubview(scrollView)
        scrollView.addSubview(logoImageView)
        scrollView.addSubview(firstNameTextField)
        scrollView.addSubview(lastNameTextField)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(registerButton)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        logoImageView.frame = CGRect(x: (scrollView.width - size) / 2, y: 20, width: size, height: size)
        logoImageView.layer.cornerRadius = logoImageView.width / 2
        firstNameTextField.frame = CGRect(x: 30, y: (logoImageView.bottom + 10), width: (scrollView.width - 60), height: 52)
        lastNameTextField.frame = CGRect(x: 30, y: (firstNameTextField.bottom + 10), width: (scrollView.width - 60), height: 52)
        emailTextField.frame = CGRect(x: 30, y: (lastNameTextField.bottom + 10), width: (scrollView.width - 60), height: 52)
        passwordTextField.frame = CGRect(x: 30, y: (emailTextField.bottom + 10), width: (scrollView.width - 60), height: 52)
        registerButton.frame = CGRect(x: 30, y: (passwordTextField.bottom + 10), width: (scrollView.width - 60), height: 52)
    }
    
    func alertUserLoginError(message: String = "Please enter all information to create a new account.") {
        let alert = UIAlertController(title: "Woops", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegisterButton(_ sender: UIBarButtonItem) {
        let registerViewController = RegisterViewController()
        registerViewController.title = "Create Account"
        navigationController?.pushViewController(registerViewController, animated: true)
    }
    
    @objc private func didTapChangeProfilePicture(_ sender: UITapGestureRecognizer) {
        presentPhotoActionSheet()
    }
    
    @objc private func didTapLogginButton(_ sender: UIButton) {
        firstNameTextField.resignFirstResponder()
        lastNameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        guard let firstName = firstNameTextField.text, let lastName = lastNameTextField.text, let email = emailTextField.text, let password = passwordTextField.text, !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        let cachedImage = logoImageView.image
        // Firebase Login
        DatabaseManager.shared.userExists(with: email) { [weak self] (exists) in
            DispatchQueue.main.async {
                self?.spinner.dismiss()
            }
            guard !exists else {
                self?.alertUserLoginError(message: "Looks like a user account for that email address already exists.")
                return
            }
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
                guard authResult != nil, error == nil else {
                    print("Error creating user:", error!)
                    return
                }
                
                UserDefaults.standard.setValue(email, forKey: "email")
                UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                DatabaseManager.shared.insertUser(with: chatUser) { (success) in
                    if success {
                        // upload image
                        guard let image = cachedImage, let data = image.pngData() else { return }
                        let fileName = chatUser.profiePictureFileName
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { (result) in
                            switch result {
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                print(downloadUrl)
                            case .failure(let error):
                                print("Storage manager error:", error)
                            }
                        }
                    }
                }
                self?.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameTextField {
            lastNameTextField.becomeFirstResponder()
        } else if textField == lastNameTextField {
            emailTextField.becomeFirstResponder()
        } else if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            didTapLogginButton(registerButton)
        }
        return true
    }
}

extension RegisterViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] (_) in
            self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { [weak self] (_) in
            self?.presentPhotoPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    func presentPhotoPicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.logoImageView.image = selectedImage
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
