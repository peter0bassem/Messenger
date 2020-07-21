//
//  ConversationsViewController.swift
//  Messenger
//
//  Created by Peter Bassem on 7/20/20.
//  Copyright © 2020 Peter Bassem. All rights reserved.
//

import UIKit
import Firebase
import JGProgressHUD

struct Conversation {
    let id : String
    let name : String
    let otherUserEmail : String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date : String
    let text : String
    let isRead : Bool
}

class ConversationsViewController: UIViewController {
    
    private lazy var spinner: JGProgressHUD = {
        let spinner = JGProgressHUD(style: .dark)
        return spinner
    }()
    
    private lazy var conversationsTableView: UITableView = {
       let tableView = UITableView()
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isHidden = true
        return tableView
    }()
    
    private lazy var noConversationsLabel: UILabel = {
       let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()

    private var conversations = [Conversation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeBarButton(_:)))
        view.addSubview(conversationsTableView)
        view.addSubview(noConversationsLabel)
        fetchConversations()
        startListeningForConversations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        conversationsTableView.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    private func validateAuth() {
        if Auth.auth().currentUser == nil {
            let loginViewController = LoginViewController()
            let navigationController = UINavigationController(rootViewController: loginViewController)
            navigationController.modalPresentationStyle = .fullScreen
            present(navigationController, animated: false)
        }
    }
    
    private func fetchConversations() {
        conversationsTableView.isHidden = false
    }
    
    private func createNewConversation(result: [String:String]) {
        guard let name = result["name"], let email = result["email"] else { return }
        let chatViewController = ChatViewController(with: email, id: nil)
        chatViewController.title = name
        chatViewController.isNewConversation = true
        navigationController?.pushViewController(chatViewController, animated: true)
    }
    
    private func startListeningForConversations() {
        guard var email = UserDefaults.standard.string(forKey: "email") else { return }
        email = DatabaseManager.safeEmail(email: email)
        DatabaseManager.shared.getAllConversations(for: email) { [weak self] (result) in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else { return }
                self?.conversations = conversations
                DispatchQueue.main.async {
                    self?.conversationsTableView.reloadData()
                }
            case .failure(let error):
                print("Failed let get convo:", error)
            }
        }
    }
    
    @objc private func didTapComposeBarButton(_ sender: UIBarButtonItem) {
        let newConversationViewController = NewConversationViewController()
        let navigationController = UINavigationController(rootViewController: newConversationViewController)
        newConversationViewController.completion = { [weak self] result in
            self?.createNewConversation(result: result)
        }
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
}


extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = conversationsTableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        let model = conversations[indexPath.row]
        cell.configure(wit: model)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        conversationsTableView.deselectRow(at: indexPath, animated: true)
        
        let model = conversations[indexPath.row]
        let chatViewController = ChatViewController(with: model.otherUserEmail, id: model.id)
        chatViewController.title = model.name
        navigationController?.pushViewController(chatViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}
