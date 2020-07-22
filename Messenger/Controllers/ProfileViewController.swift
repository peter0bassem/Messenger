//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Peter Bassem on 7/20/20.
//  Copyright © 2020 Peter Bassem. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage

final class ProfileViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var data = [ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        data.append(ProfileViewModel(viewModelType: .info, title: "Name: \(UserDefaults.standard.string(forKey: "name") ?? "No Name")", handler: nil))
        data.append(ProfileViewModel(viewModelType: .info, title: "Email: \(UserDefaults.standard.string(forKey: "email") ?? "No Email")", handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Logout", handler: { [weak self] in
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { [weak self] (_) in
                
                UserDefaults.standard.setValue(nil, forKey: "email")
                UserDefaults.standard.setValue(nil, forKey: "name")
                
                // Facebook Logout
                let loginManager = LoginManager()
                loginManager.logOut()
                
                // Google Logout
                GIDSignIn.sharedInstance()?.signOut()
                
                // Firebase Email/Passwrod Logout
                do {
                    try Auth.auth().signOut()
                    
                    let loginViewController = LoginViewController()
                    let navigationController = UINavigationController(rootViewController: loginViewController)
                    navigationController.modalPresentationStyle = .fullScreen
                    self?.present(navigationController, animated: true)
                } catch let error {
                    print("Failed to logout:", error)
                }
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self?.present(actionSheet, animated: true, completion: nil)
        }))
        
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifer)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = createTableViewHeader()
    }
    
    private func createTableViewHeader() -> UIView? {
        guard let email = UserDefaults.standard.string(forKey: "email") else { return nil }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/\(fileName)"
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        headerView.backgroundColor = .link
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2, y: 75, width: 150, height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width / 2
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadUrl(for: path) { (result) in
            switch result {
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("Failed to get download url:", error)
            }
        }
        
        return headerView
    }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifer, for: indexPath) as! ProfileTableViewCell
        let viewModel = data[indexPath.row]
        cell.setup(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }
}

class ProfileTableViewCell: UITableViewCell {
    
    static let identifer = "ProfileTableViewCell"
    
    public func setup(with viewModel: ProfileViewModel) {
        textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
}
