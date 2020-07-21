//
//  File.swift
//  
//
//  Created by 16997598 on 22.07.2020.
//

import Vapor

extension UserController {
    func getSelf(_ req: Request) throws -> Future<UserResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try user.contacts.query(on: req).all().map { contacts in
            return try UserResponse(with: user, contacts: contacts)
        }
    }
    
    func getUser(_ req: Request) throws -> Future<UserResponse> {
        return try req.parameters.next(User.self).flatMap { user in
            return try user.contacts.query(on: req).all().map { contacts in
                return try UserResponse(with: user, contacts: contacts)
            }
        }
    }
    
    func updateUser(_ req: Request) throws -> Future<UserResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(UpdateUserRequest.self).flatMap { userData in
            if let email = userData.email {
                user.email = email
            }
            
            if let name = userData.name {
                user.name = name
            }
            
            if let imagePath = userData.imagePath {
                user.imagePath = imagePath
            }
            try user.validate()
            return user.save(on: req).map {
                return try UserResponse(with: $0)
            }
        }
    }
}
