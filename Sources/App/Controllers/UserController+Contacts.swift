//
//  ProjectController+Contacts.swift
//  
//
//  Created by 16997598 on 21.07.2020.
//
import Vapor
import FluentMySQL

extension UserController {
    func getContactsEnum(_ req: Request) throws -> Future<[ContactEnum]> {
        return ContactEnum.query(on: req).all()
    }
    
    func getUserContacts(_ req: Request) throws -> Future<[ContactResponse]> {
        let user = try req.requireAuthenticated(User.self)
        return try user.contacts.query(on: req).all().map { try $0.map { try ContactResponse(contact: $0)}}
    }
    
    func createContact(_ req: Request) throws -> Future<ContactResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(ContactCreateRequest.self).flatMap {
            return Contact(title: $0.title, link: $0.link, ownerId: try user.requireID()).save(on: req).map {
                return try ContactResponse(contact: $0)
            }
        }
    }
    
    func updateContact(_ req: Request) throws -> Future<ContactResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Contact.self).flatMap { contact in
            guard try user.requireID() == contact.ownerId else { throw Abort(.forbidden, reason: "Только владелец контакта может поменять контакт")}
            return try req.content.decode(ContactResponse.self).flatMap { requsetData in
                contact.title = requsetData.title
                contact.link = requsetData.link
                return contact.update(on: req).map { contact in
                    return try ContactResponse(contact: contact)
                }
            }
        }
    }
    
    func deleteContact(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Contact.self).flatMap { contact -> Future<Void> in
            guard try user.requireID() == contact.ownerId else {
                throw Abort(.forbidden, reason: "Только владелец контакта может удалить контакт")
            }
            return contact.delete(on: req)
        }.transform(to: .ok)
    }
}

struct ContactResponse: Content {
    let id: Int
    let title: String
    let link: String
    
    init(contact: Contact) throws {
        self.id = try contact.requireID()
        self.title = contact.title
        self.link = contact.link
    }
}

struct ContactCreateRequest: Content {
    let title: String
    let link: String
}
