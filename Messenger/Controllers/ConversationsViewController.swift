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

/// Controller that shows list of conversations
final class ConversationsViewController: UIViewController {
    
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
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeBarButton(_:)))
        view.addSubview(conversationsTableView)
        view.addSubview(noConversationsLabel)
        startListeningForConversations()
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification, object: nil, queue: .main) { [weak self] (_) in
            self?.startListeningForConversations()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        conversationsTableView.frame = view.bounds
        noConversationsLabel.frame = CGRect(x: 10, y: (view.height - 100) / 2, width: (view.width - 20), height: 100)
        
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
    
    private func createNewConversation(result: SearchResult) {
        let name = result.name
        let email = DatabaseManager.safeEmail(email: result.email)
        
        // check in database if conversation with two users exists
        // if it does: reuse conversation id
        // otherwise: use existing code
        
        
        DatabaseManager.shared.conversationExists(with: email) { [weak self] (result) in
            switch result {
            case .success(let conversationId):
                let chatViewController = ChatViewController(with: email, id: conversationId)
                chatViewController.title = name
                chatViewController.isNewConversation = false
                self?.navigationController?.pushViewController(chatViewController, animated: true)
            case .failure(_):
                let chatViewController = ChatViewController(with: email, id: nil)
                chatViewController.title = name
                chatViewController.isNewConversation = true
                self?.navigationController?.pushViewController(chatViewController, animated: true)
            }
        }
    }
    
    private func startListeningForConversations() {
        guard var email = UserDefaults.standard.string(forKey: "email") else { return }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        email = DatabaseManager.safeEmail(email: email)
        DatabaseManager.shared.getAllConversations(for: email) { [weak self] (result) in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    self?.conversationsTableView.isHidden = true
                    self?.noConversationsLabel.isHidden = false
                    return
                }
                self?.noConversationsLabel.isHidden = true
                self?.conversationsTableView.isHidden = false
                self?.conversations = conversations
                DispatchQueue.main.async {
                    self?.conversationsTableView.reloadData()
                }
            case .failure(let error):
                print("Failed let get convo:", error)
                self?.conversationsTableView.isHidden = true
                self?.noConversationsLabel.isHidden = false
            }
        }
    }
    
    func openConversation(_ model: Conversation) {
        let chatViewController = ChatViewController(with: model.otherUserEmail, id: model.id)
        chatViewController.title = model.name
        navigationController?.pushViewController(chatViewController, animated: true)
    }
    
    @objc private func didTapComposeBarButton(_ sender: UIBarButtonItem) {
        let newConversationViewController = NewConversationViewController()
        let navigationController = UINavigationController(rootViewController: newConversationViewController)
        newConversationViewController.completion = { [weak self] result in
            
            guard let currentConversations = self?.conversations else { return }
            if let targetConversation = currentConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(email: result.email)
            }) {
                let chatViewController = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                chatViewController.title = targetConversation.name
                chatViewController.isNewConversation = false
                self?.navigationController?.pushViewController(chatViewController, animated: true)
            } else {
                self?.createNewConversation(result: result)
            }
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
        openConversation(model)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // begin delete
            let conversationId = conversations[indexPath.row].id
            conversationsTableView.beginUpdates()
            self.conversations.remove(at: indexPath.row)
            conversationsTableView.deleteRows(at: [indexPath], with: .left)
            DatabaseManager.shared.deleteConversation(conversationId: conversationId) { (success) in
                if !success {
                    // add model and row back and show alert error
                    
                }
            }
            conversationsTableView.endUpdates()
        }
    }
}
