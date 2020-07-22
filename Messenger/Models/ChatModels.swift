//
//  ChatModels.swift
//  Messenger
//
//  Created by Peter Bassem on 7/22/20.
//  Copyright © 2020 Peter Bassem. All rights reserved.
//

import Foundation
import MessageKit
import CoreLocation

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

extension MessageKind {
    
    var messageKindString: String {
        switch self {
        case .text:
            return "text"
        case .attributedText:
            return "attributed_text"
        case .photo:
            return "photo"
        case .video:
            return "video"
        case .location:
            return "location"
        case .emoji:
            return "emoji"
        case .audio:
            return "audio"
        case .contact:
            return "contact"
        case .custom:
            return "custom"
        }
    }
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}
