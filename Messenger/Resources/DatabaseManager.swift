//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Peter Bassem on 7/20/20.
//  Copyright © 2020 Peter Bassem. All rights reserved.
//

import Foundation
import Firebase
import MessageKit
import CoreLocation

/// Manager object to read and write data ro real time Firebase database
final class DatabaseManager {
    /// Shared instance of class
    static let shared = DatabaseManager()
    
    private init() { }
    
    private let database = Database.database().reference()
    
    static func safeEmail(email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

//MARK: -
extension DatabaseManager {
    
    /// Returns dictionary node at child path.
    func getDataFor(path: String, completion: @escaping ((Result<Any, Error>) -> Void)) {
        database.child("\(path)").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

//MARK: - Account Management
extension DatabaseManager {
    
    /// Checks if user exists for given email
    /// Parameters
    /// - `email`:    Target email to be checekd
    /// - `completion`:   Async closure to return with result
    public func userExists(with email: String, completion: @escaping ((Bool)->Void)) {
        let safeEmail = DatabaseManager.safeEmail(email: email)
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            guard let _ = snapshot.value as? [String:Any] else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Insert a user to database.
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue(["fisrtName": user.firstName, "lastName": user.lastName]) { [weak self] (error, _) in
            guard error == nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            
            self?.database.child("users").observeSingleEvent(of: .value) { (snapshot) in
                if var usersCollection = snapshot.value as? [[String:String]] {
                    // append to user dictionary
                    let newElement = ["name": user.firstName + " " + user.lastName, "email": user.safeEmail]
                    usersCollection.append(newElement)
                    self?.database.child("users").setValue(usersCollection) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                } else {
                    // create that array
                    let newCollection: [[String:String]] = [
                        ["name": user.firstName + " " + user.lastName, "email": user.safeEmail]
                    ]
                    self?.database.child("users").setValue(newCollection) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
        }
    }
    
    /// Gets all users from database
    public func getAllUsers(completion: @escaping (Result<[[String:String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseErrors: Error {
        case failedToFetch
        
        var localizedDescription: String {
            switch self {
            case .failedToFetch:
                return "This means blah failed"
            }
        }
    }
}

//MARK: - Sending Messages / conversations
extension DatabaseManager {
    
    /// Creates a new conversation with target user email and first message sent,
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping ((Bool) -> Void)) {
        guard let currentEmail = UserDefaults.standard.string(forKey: "email"), let currentName = UserDefaults.standard.string(forKey: "name") else { return }
        let safeEmail = DatabaseManager.safeEmail(email: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(false)
                print("User not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message: String = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String:Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message
                ]
            ]
            
            let recipient_newConversationData: [String:Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message
                ]
            ]
            
            // Update recipeint conversation entry.
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] (snapshot) in
                if var conversations = snapshot.value as? [[String:Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            }
            
            // Update current user conversation entry.
            if var conversations = userNode["conversations"] as? [[String:Any]] {
                // conversation array exists for current user
                // you should append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { [weak self] (error, _) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                }
            } else {
                // conversation array does not exists
                // create it
                userNode["conversations"] = [newConversationData]
                ref.setValue(userNode) { [weak self] (error, _) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                }
            }
        }
    }
    
    private func finishCreatingConversation(name: String, conversationId: String, firstMessage: Message, completion: @escaping ((Bool) -> Void)) {
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message: String = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }
        
        guard var currentUserEmail = UserDefaults.standard.string(forKey: "email") else {
            completion(false)
            return
        }
        currentUserEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        
        let collectionMessage: [String:Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]
        let value: [String:Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        database.child("\(conversationId)").setValue(value) { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Fetches and returns all conversations for the user with passed in emal.
    public func getAllConversations(for email: String, completion: @escaping ((Result<[Conversation], Error>) -> Void)) {
        database.child("\(email)/conversations").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap { (dictionary) in
                guard let conversationId = dictionary["id"] as? String, let name = dictionary["name"] as? String, let otherUserEmail = dictionary["other_user_email"] as? String, let latestMessage = dictionary["latest_message"] as? [String:Any], let date = latestMessage["date"] as? String, let message = latestMessage["message"] as? String, let isRead = latestMessage["is_read"] as? Bool else { return nil }
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            }
            completion(.success(conversations))
        }
    }
    
    /// Gets all messages for given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping ((Result<[Message], Error>) -> Void)) {
        database.child("\(id)/messages").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap { (dictionary) in
                guard let name = dictionary["name"] as? String, let isRead = dictionary["is_read"] as? Bool, let messageId = dictionary["id"] as? String, let content = dictionary["content"] as? String, let senderEmail = dictionary["sender_email"] as? String, let type = dictionary["type"] as? String, let dateString = dictionary["date"] as? String, let date = ChatViewController.dateFormatter.date(from: dateString) else { return nil }
                
                var kind: MessageKind?
                if type == "photo" {
                    // photo
                    guard let imageUrl = URL(string: content), let placeholder = UIImage(systemName: "plus") else { return nil}
                    let media = Media(url: imageUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else if type == "video" {
                    // video
                    guard let videoUrl = URL(string: content), let placeholder = UIImage(named: "video_placeholder") else { return nil}
                    let media = Media(url: videoUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                } else if type == "location" {
                    let locationComponents = content.components(separatedBy: ",")
                    guard let longitude = Double(locationComponents[0]),
                        let latitude = Double(locationComponents[1]) else { return nil }
                    
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                } else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else { return nil }
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: finalKind)
            }
            completion(.success(messages))
        }
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping ((Bool) -> Void)) {
        // add new message to messages
        // update sender latest message
        // update recipient latest message
        
        guard var currentEmail = UserDefaults.standard.string(forKey: "email") else {
            completion(false)
            return
        }
        currentEmail = DatabaseManager.safeEmail(email: currentEmail)
        
        database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard var currentMessages = snapshot.value as? [[String:Any]] else {
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message: String = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
                break
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                message = "\(locationData.location.coordinate.longitude),\(locationData.location.coordinate.latitude)"
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            guard var currentUserEmail = UserDefaults.standard.string(forKey: "email") else {
                completion(false)
                return
            }
            currentUserEmail = DatabaseManager.safeEmail(email: currentUserEmail)
            
            let newMessageEntry: [String:Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            currentMessages.append(newMessageEntry)
            self?.database.child("\(conversation)/messages").setValue(currentMessages, withCompletionBlock: { (error, _) in
                guard error == nil else {
                    completion(false)
                    return
                }
                self?.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { (snapshot) in
                    var databaseEntryConversations = [[String:Any]]()
                    let updatedValue: [String:Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    if var currentUserConversations = snapshot.value as? [[String:Any]] {
                        var targetConversation: [String:Any]?
                        var position = 0

                        for conversationDictionary in currentUserConversations {
                            if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                targetConversation = conversationDictionary
                                break
                            }
                            position += 1
                        }
                        
                        if var targetConversation = targetConversation {
                            targetConversation["latest_message"] = updatedValue
                            currentUserConversations[position] = targetConversation
                            databaseEntryConversations = currentUserConversations
                        } else {
                            let newConversationData: [String:Any] = [
                                "id": conversation,
                                "other_user_email": DatabaseManager.safeEmail(email: otherUserEmail),
                                "name": name,
                                "latest_message": updatedValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversations = currentUserConversations
                        }
                    } else {
                        let newConversationData: [String:Any] = [
                            "id": conversation,
                            "other_user_email": DatabaseManager.safeEmail(email: otherUserEmail),
                            "name": name,
                            "latest_message": updatedValue
                        ]
                        databaseEntryConversations = [
                            newConversationData
                        ]
                    }
                    
                    
                    
                    self?.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        //Update latest message for recipient user
                        self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { (snapshot) in
                            let updatedValue: [String:Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            var databaseEntryConversations = [[String:Any]]()
                            
                            guard let currentName = UserDefaults.standard.string(forKey: "name") else { return }
                            
                            if var otherUserConversations = snapshot.value as? [[String:Any]] {
                                var targetConversation: [String:Any]?
                                
                                var position = 0
                                
                                for conversationDictionary in otherUserConversations {
                                    if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                        targetConversation = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }
                                
                                if var targetConversation = targetConversation {
                                    targetConversation["latest_message"] = updatedValue
                                    otherUserConversations[position] = targetConversation
                                    databaseEntryConversations = otherUserConversations
                                } else {
                                    // failed to find in current collection
                                    let newConversationData: [String:Any] = [
                                        "id": conversation,
                                        "other_user_email": DatabaseManager.safeEmail(email: currentEmail),
                                        "name": currentName,
                                        "latest_message": updatedValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversations = otherUserConversations
                                }
                            } else {
                                // current collection does not exist
                                let newConversationData: [String:Any] = [
                                    "id": conversation,
                                    "other_user_email": DatabaseManager.safeEmail(email: currentEmail),
                                    "name": currentName,
                                    "latest_message": updatedValue
                                ]
                                databaseEntryConversations = [
                                    newConversationData
                                ]
                            }
                           
                            self?.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { (error, _) in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        })
                    })
                })
            })
        }
    }
    
    public func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void) {
        guard var email = UserDefaults.standard.string(forKey: "email") else {
            completion(false)
            return
        }
        email = DatabaseManager.safeEmail(email: email)
        
        print("Deleteing conversation with id:", conversationId)
        
        // Get all conversations for current user
        // Delete conversation in target with traget id
        // reset those conversations for the user in database
        let ref = database.child("\(email)/conversations")
        ref.observeSingleEvent(of: .value) { (snapshot) in
            if var conversations = snapshot.value as? [[String:Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String, id == conversationId {
                        print("found conversation to delete")
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations) { (error, _) in
                    guard error == nil else {
                        print("failed to write new conversation array")
                        completion(false)
                        return
                    }
                    print("deleted conversation ")
                    completion(true)
                }
            }
        }
    }
    
    public func conversationExists(with targetOtherRecipientEmail: String, completion: @escaping ((Result<String, Error>) -> Void)) {
        let safeRecipientEmail = DatabaseManager.safeEmail(email: targetOtherRecipientEmail)
        guard var senderEmail = UserDefaults.standard.string(forKey: "email") else { return }
        senderEmail = DatabaseManager.safeEmail(email: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
            guard let collection = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            
            // iterate and find conversation with target sender
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else { return false }
                return senderEmail == targetSenderEmail
            }) {
                // get id
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseErrors.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            } else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
        }
    }
}

struct ChatAppUser {
    let firstName : String
    let lastName : String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profiePictureFileName : String {
        return "\(safeEmail)_profile_picture.png"
    }
    
}
