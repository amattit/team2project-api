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
    
    func getUser(_ req: Request) throws -> Future<UserWithProjectsResponse> {
        return try req.parameters.next(User.self).flatMap { user in
            return try user.contacts.query(on: req).all().flatMap { contacts in
                return try user.projects.query(on: req)
                    .filter(\.isPublished, .equal, 1)
                    .all()
                    .map { projects in
                        return try UserWithProjectsResponse(user, contacts: contacts, projects: projects)
                }
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
            
            if let about = userData.about {
                user.about = about
            }
            
            if let location = userData.location {
                user.location = location
            }
            
            if let role = userData.role {
                user.role = role
            }
            
            try user.validate()
            return user.save(on: req).map {
                return try UserResponse(with: $0)
            }
        }
    }
    
    func getAllUsers(_ req: Request) throws -> Future<[UserResponse]> {
        return User.query(on: req).all().map { users in
            return try users.map { try UserResponse(with: $0) }
        }
    }
}

struct UserWithProjectsResponse: Content {
    var id: Int
    
    var email: String
    
    var name: String?
    
    var imagePath: String?
    
    var about: String?
    
    var contacts: [ContactResponse]?
    
    var location: String?
    
    var role: String?
    
    var isFavorite: Bool?
    
    let projects: [ProjectController.ProjectListResponse]?
    
    init(_ user: User, contacts: [Contact], projects: [Project]) throws {
        self.id = try user.requireID()
        self.email = user.email
        self.name = user.name
        self.imagePath = user.imagePath
        self.about = user.about
        self.location = user.location
        self.role = user.role
        self.isFavorite = nil
        self.contacts = try contacts.map { try ContactResponse(contact: $0)}
        self.projects = try projects.map { try ProjectController.ProjectListResponse(with: $0, and: user) }
    }
}
