//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Peter Bassem on 7/20/20.
//  Copyright © 2020 Peter Bassem. All rights reserved.
//

import UIKit
import JGProgressHUD

final class NewConversationViewController: UIViewController {
    
    private lazy var spinnder: JGProgressHUD = {
        let spinner = JGProgressHUD(style: .dark)
        return spinner
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for users"
        searchBar.delegate = self
        return searchBar
    }()
    
    private lazy var usersTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(NewConversationTableViewCell.self, forCellReuseIdentifier: NewConversationTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isHidden = true
        return tableView
    }()
    
    private lazy var noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private var users = [[String:String]]()
    private var results = [SearchResult]()
    private var hasFetched = false
    
    public var completion: ((SearchResult) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cacnel", style: .done, target: self, action: #selector(didTapCancelBarButton(_:)))
        view.backgroundColor = .systemBackground
        searchBar.becomeFirstResponder()
        
        view.addSubview(noResultsLabel)
        view.addSubview(usersTableView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        usersTableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: (view.width) / 4, y: (view.height - 200) / 2, width: (view.width) / 2, height: 200)
    }
    
    @objc private func didTapCancelBarButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
extension NewConversationViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = usersTableView.dequeueReusableCell(withIdentifier: NewConversationTableViewCell.identifier, for: indexPath) as! NewConversationTableViewCell
        let result = results[indexPath.row]
        cell.configure(wit: result)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        usersTableView.deselectRow(at: indexPath, animated: true)
        // start conversation
        let targetUserData = results[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.completion?(targetUserData)
        }
    }
}

extension NewConversationViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else { return }
        
        searchBar.resignFirstResponder()
        results.removeAll()
        spinnder.show(in: view)
        
        searchUsers(query: text)
    }
    
    func searchUsers(query: String) {
        // check if array has firebase results
        if hasFetched {
            // if it does: filter
            filterUsers(with: query)
        } else {
            // if not: fetch then filter
            DatabaseManager.shared.getAllUsers { [weak self] (result) in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("Failed to get users:", error)
                }
            }
        }
    }
    
    func filterUsers(with term: String) {
        // update the UI: either show result or show no results label
        guard var currentUserEmail = UserDefaults.standard.string(forKey: "email"), hasFetched else { return }
        currentUserEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        self.spinnder.dismiss()
        let results: [SearchResult] = users.filter {
            guard let email = $0["email"], email != currentUserEmail else { return false }
            guard let name = $0["name"]?.lowercased() else { return false }
            return name.hasPrefix(term.lowercased())
        }.compactMap {
            guard let email = $0["email"], let name = $0["name"] else { return nil }
            return SearchResult(name: name, email: email)
        }
        self.results = results
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            noResultsLabel.isHidden = false
            usersTableView.isHidden = true
        } else {
            noResultsLabel.isHidden = true
            usersTableView.isHidden = false
            usersTableView.reloadData()
        }
    }
}
