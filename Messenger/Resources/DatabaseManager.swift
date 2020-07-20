//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Peter Bassem on 7/20/20.
//  Copyright © 2020 Peter Bassem. All rights reserved.
//

import Foundation
import Firebase

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
}

//MARK: - Account Management
extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool)->Void)) {
        database.child(email).observeSingleEvent(of: .value) { (snapshot) in
            guard let _ = snapshot.value as? String else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Insert a user to database.
    public func insertUser(with user: ChatAppUser) {
        database.child(user.emailAddress).setValue(["fisrtName": user.firstName, "lastName": user.lastName])
    }
}

struct ChatAppUser {
    let firstName : String
    let lastName : String
    let emailAddress: String
//    let profilePictureUrl : URL
}
