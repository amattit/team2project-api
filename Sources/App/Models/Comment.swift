//
//  File.swift
//  
//
//  Created by 16997598 on 16.08.2020.
//

import FluentPostgreSQL
import Vapor

final class Comment: PostgreSQLModel {
    var id: Int?
    var title: String
    var projectId: Project.ID
    var ownerId: User.ID
    var created: Date
    
    init(id: Int? = nil, title: String, ownerId: Int, projectId: Int) {
        self.id = id
        self.title = title
        self.ownerId = ownerId
        self.projectId = projectId
        self.created = Date()
    }
}

extension Comment {
    var owner: Parent<Comment, User> {
        return parent(\.ownerId)
    }
    
    var project: Parent<Comment, Project> {
        return parent(\.projectId)
    }
}

extension Project {
    var comments: Children<Project, Comment> {
        return children(\.projectId)
    }
}

extension Comment: Content { }

extension Comment: Parameter { }

extension Comment: PostgreSQLMigration {
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.create(Comment.self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.title)
            builder.field(for: \.created)
            builder.field(for: \.projectId)
            builder.field(for: \.ownerId)
            builder.reference(from: \.ownerId, to: \User.id, onDelete: .cascade)
            builder.reference(from: \.projectId, to: \Project.id, onDelete: .cascade)
        }
    }
}

struct CreateCommentRequest: Content {
    let title: String
}

struct CommentResponse: Content {
    let id: Int
    let title: String
    let user: UserResponse
    
    init(_ comment: Comment, user: User) throws {
        self.id = try comment.requireID()
        self.title = comment.title
        self.user = try UserResponse(with: user)
    }
}

struct CommentCount: Content {
    let count: Int
}
