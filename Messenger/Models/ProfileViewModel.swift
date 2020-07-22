//
//  ProfileViewModel.swift
//  Messenger
//
//  Created by Peter Bassem on 7/22/20.
//  Copyright © 2020 Peter Bassem. All rights reserved.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType : ProfileViewModelType
    let title : String
    let handler : (() -> Void)?
}
