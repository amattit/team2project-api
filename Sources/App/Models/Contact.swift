//
//  File.swift
//  
//
//  Created by 16997598 on 21.07.2020.
//

import FluentMySQL
import Vapor

final class Contact: MySQLModel {
    var id: Int?
    var title: String
    var link: String
    var created: Date
    var updated: Date?
    var ownerId: User.ID
    
    init(id: Int? = nil, title: String, link: String, ownerId: Int) {
        self.id = id
        self.title = title
        self.link = link
        self.ownerId = ownerId
        self.created = Date()
    }
}

extension Contact {
    /// Fluent relation to user that owns this todo.
    var user: Parent<Contact, User> {
        return parent(\.ownerId)
    }
}

/// Allows `Todo` to be used as a Fluent migration.
extension Contact: MySQLMigration {
    static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return MySQLDatabase.create(Contact.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.title)
            builder.field(for: \.link)
            builder.field(for: \.ownerId)
            builder.field(for: \.created)
            builder.field(for: \.updated)
            builder.reference(from: \.ownerId, to: \User.id)
        }
    }
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Contact: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Contact: Parameter { }
