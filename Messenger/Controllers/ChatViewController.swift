//
//  ChatViewController.swift
//  Messenger
//
//  Created by Peter Bassem on 7/20/20.
//  Copyright © 2020 Peter Bassem. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation

final class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .long
        dateFormatter.timeZone = .current
        return dateFormatter
    }()
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard var email = UserDefaults.standard.string(forKey: "email") else { return nil }
        email = DatabaseManager.safeEmail(email: email)
        return Sender(photoURL: "", senderId: email, displayName: "Me")
    }
    
    public let otherUserEmail: String
    private var conversationId: String?
    public var isNewConversation = false
    
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    
    init(with email: String, id: String?) {
        conversationId = id
        otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] (result) in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else { return }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToBottom()
                    }
                }
            case .failure(let error):
                print("Failed to get messages:", error)
            }
        }
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] (_) in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] (_) in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] (_) in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { (_) in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] (_) in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach a photo from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] (_) in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] (_) in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where would you like to attach a video from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] (_) in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] (_) in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let locationPickerViewController = LocationPickerViewController(coordinates: nil)
        locationPickerViewController.completion = { [weak self] (selectedCoordinates) in
            
            guard let self = self, let messageId = self.createMessageId(), let conversationId = self.conversationId, let name = self.title, let selfSender = self.selfSender else { return }

            
            let longitude: Double = selectedCoordinates.longitude
            let latitude: Double = selectedCoordinates.latitude
            
            print("long=\(longitude), lat=\(latitude)")
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { (success) in
                if success {
                    print("sent photo sent.")
                } else {
                    print("failed to send photo message.")
                }
            }
        }
        navigationController?.pushViewController(locationPickerViewController, animated: true)
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = self.selfSender, let messageId = createMessageId() else { return }
        
        // send message
        
        print("Sending text:", text)
        
        let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
        
        if isNewConversation {
            // create convo in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message) { [weak self] (success) in
                if success {
                    print("Message sent")
                    self?.isNewConversation = false
                    let newConversationId = "conversation_\(message.messageId)"
                    self?.conversationId = newConversationId
                    self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                    self?.messageInputBar.inputTextView.text = nil
                } else {
                    print("Failed to send")
                }
            }
        } else {
            // append to existing conversation data
            guard let conversationId = conversationId, let name = self.title else { return }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message) { [weak self] (success) in
                if success {
                    print("message sent.")
                    self?.messageInputBar.inputTextView.text = nil
                } else {
                    print("failed to send.")
                }
            }
        }
    }
    
    private func createMessageId() -> String? {
        // date, otherUserEmail, senderEmail, randomInt
        guard var currentUserEmail = UserDefaults.standard.string(forKey: "email") else { return nil }
        currentUserEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(currentUserEmail)_\(dateString)"
        print("created messageId:", newIdentifier)
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil, email should be cached.")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else { return }
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId  == self.selfSender?.senderId {
            // our message that we've sent
            return .link
        } else {
            return .secondarySystemBackground
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if sender.senderId == self.selfSender?.senderId {
            // show our image
            if let currentUserImageURL = self.senderPhotoURL {
                avatarView.sd_setImage(with: currentUserImageURL, completed: nil)
            } else {
                guard var email = UserDefaults.standard.string(forKey: "email") else { return }
                email = DatabaseManager.safeEmail(email: email)
                let path = "images/\(email)_profile_picture.png"
                
                // fetch url
                StorageManager.shared.downloadUrl(for: path) { [weak self] (result) in
                    switch result {
                    case .success(let url):
                        self?.senderPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        } else {
            // show user image
            if let otherUserImageURL = self.senderPhotoURL {
                avatarView.sd_setImage(with: otherUserImageURL, completed: nil)
            } else {
                // fetch url
                var email = self.otherUserEmail
                email = DatabaseManager.safeEmail(email: email)
                let path = "images/\(email)_profile_picture.png"
                
                // fetch url
                StorageManager.shared.downloadUrl(for: path) { [weak self] (result) in
                    switch result {
                    case .success(let url):
                        self?.otherUserPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let locationPickerViewController = LocationPickerViewController(coordinates: coordinates)
            navigationController?.pushViewController(locationPickerViewController, animated: true)
        default:
            break
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return }
            let photoViewerImageView = PhotoViewerViewController(with: imageUrl)
            navigationController?.pushViewController(photoViewerImageView, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else { return }
            let avPlayerViewController = AVPlayerViewController()
            avPlayerViewController.player = AVPlayer(url: videoUrl)
            present(avPlayerViewController, animated: true) {
                avPlayerViewController.player?.play()
            }
        default:
            break
        }
    }
}

extension ChatViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageId(), let conversationId = conversationId, let name = self.title, let selfSender = self.selfSender else { return }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            // Upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success(let urlString):
                    // Ready to send message
                    print("Uploaded message photo:", urlString)
                    
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus") else { return }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { (success) in
                        if success {
                            print("sent photo sent.")
                        } else {
                            print("failed to send photo message.")
                        }
                    }
                case .failure(let error):
                    print("message photo upload error:", error)
                }
            }
        } else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "video_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            // Upload Video
            
            do {
                if #available(iOS 13.0, *) {
                    let urlString = videoUrl.relativeString
                    let urlSlices = urlString.split(separator: ".")
                    //Create a temp directory using the file name
                    let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                    let targetURL = tempDirectoryURL.appendingPathComponent(String(urlSlices[1])).appendingPathExtension(String(urlSlices[2]))
                    
                    //Copy the video over
                    try FileManager.default.copyItem(at: videoUrl, to: targetURL)
                    
                    StorageManager.shared.uploadMessageVideo(with: targetURL, fileName: fileName) { [weak self] (result) in
                        guard let self = self else { return }
                        switch result {
                        case .success(let urlString):
                            // Ready to send message
                            print("Uploaded message video:", urlString)
                            
                            guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus") else { return }
                            let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .video(media))
                            
                            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { (success) in
                                if success {
                                    print("sent photo sent.")
                                } else {
                                    print("failed to send photo message.")
                                }
                            }
                        case .failure(let error):
                            print("message photo upload error:", error)
                        }
                    }
                } else {
                    StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName) { [weak self] (result) in
                        guard let self = self else { return }
                        switch result {
                        case .success(let urlString):
                            // Ready to send message
                            print("Uploaded message video:", urlString)
                            
                            guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus") else { return }
                            let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .video(media))
                            
                            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { (success) in
                                if success {
                                    print("sent photo sent.")
                                } else {
                                    print("failed to send photo message.")
                                }
                            }
                        case .failure(let error):
                            print("message photo upload error:", error)
                        }
                    }
                }
            } catch let error {
                print("certain error:", error)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
