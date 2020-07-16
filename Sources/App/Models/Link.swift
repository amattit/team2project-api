//
//  File.swift
//  
//
//  Created by 16997598 on 14.07.2020.
//

import FluentMySQL
import Vapor

final class Link: MySQLModel {
    var id: Int?
    var title: String
    var link: String
    var created: Date
    var updated: Date?
    var ownerId: User.ID
    var projectId: Project.ID
    
    init(id: Int? = nil, title: String, link: String, ownerId: Int, projectId: Int) {
        self.id = id
        self.title = title
        self.link = link
        self.ownerId = ownerId
        self.projectId = projectId
        self.created = Date()
    }
}

extension Link {
    /// Fluent relation to user that owns this todo.
    var user: Parent<Link, User> {
        return parent(\.ownerId)
    }
}

extension Link {
    /// Fluent relation to user that owns this todo.
    var project: Parent<Link, Project> {
        return parent(\.projectId)
    }
}

/// Allows `Todo` to be used as a Fluent migration.
extension Link: MySQLMigration {
    static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return MySQLDatabase.create(Link.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.title)
            builder.field(for: \.link)
            builder.field(for: \.ownerId)
            builder.field(for: \.projectId)
            builder.field(for: \.created)
            builder.field(for: \.updated)
            builder.reference(from: \.ownerId, to: \User.id)
            builder.reference(from: \.projectId, to: \Project.id)
        }
    }
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Link: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Link: Parameter { }
