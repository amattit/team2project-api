//
//  File.swift
//  
//
//  Created by 16997598 on 16.08.2020.
//

import Vapor
import FluentPostgreSQL

final class Like: PostgreSQLModel {
    var id: Int?
    let projectId: User.ID
    let ownerId: Project.ID
    
    init(id: Int? = nil, projectId: Int, ownerId: Int) {
        self.id = id
        self.projectId = projectId
        self.ownerId = ownerId
    }
}

extension Like: Parameter { }

extension Like {
    var user: Parent<Like, User> {
        return parent(\.ownerId)
    }
    
    var project: Parent<Like, Project> {
        return parent(\.projectId)
    }
}

extension Project {
    var likes: Children<Project, Like> {
        return children(\.projectId)
    }
}
extension Like: PostgreSQLMigration {
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.create(Like.self, on: connection) { (builder) in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.ownerId)
            builder.field(for: \.projectId)
            builder.reference(from: \.ownerId, to: \User.id, onDelete: .cascade)
            builder.reference(from: \.projectId, to: \Project.id, onDelete: .cascade)
        }
    }
}
