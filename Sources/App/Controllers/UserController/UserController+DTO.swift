//
//  File.swift
//  
//
//  Created by 16997598 on 22.07.2020.
//

import Vapor
import Crypto
// MARK: Content

/// Data required to create a user.
struct CreateUserRequest: Content {
    /// User's full name.
    var name: String?
    
    /// User's email address.
    var email: String
    
    /// User's desired password.
    var password: String
    
    /// User's password repeated to ensure they typed it correctly.
    var verifyPassword: String
    
    /// Роль пользователя
    var userRole: String?
    
    var openLandProfileLink: String?
    
}

extension User {
    convenience init(with dto: CreateUserRequest) throws {
        let hash = try BCrypt.hash(dto.password)
        self.init(id: nil, email: dto.email, passwordHash: hash, name: dto.name, imagePath: nil)
        self.role = dto.userRole
    }
}

/// Public representation of user data.
struct UserResponse: Content {
    /// User's unique identifier.
    /// Not optional since we only return users that exist in the DB.
    var id: Int
    
    /// User's email address.
    var email: String
    
    var name: String?
    
    var imagePath: String?
    
    var contacts: [ContactResponse]?
    
    init(id: Int, email: String, name: String? = nil, imagePath: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.imagePath = imagePath
    }
    
    init(with user: User) throws {
        self.id = try user.requireID()
        self.email = user.email
        self.name = user.name
        self.imagePath = user.imagePath
    }
    
    init(with user: User, contacts: [Contact]) throws {
        try self.init(with: user)
        self.contacts = try contacts.map { try ContactResponse(contact: $0)}
    }
}

struct SetImageRequest: Content {
    let imagePath: String
}

struct UpdateUserRequest: Content {
    var email: String?
    
    var name: String?
    
    var imagePath: String?
}
