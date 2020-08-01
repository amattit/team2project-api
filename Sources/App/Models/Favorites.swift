//
//  File.swift
//  
//
//  Created by 16997598 on 28.07.2020.
//

import Foundation
import Vapor
import FluentPostgreSQL

struct UserProject: PostgreSQLPivot {
    typealias Left = User
    typealias Right = Project
    
    static var leftIDKey: LeftIDKey = \.userId
    static var rightIDKey: RightIDKey = \.projectId
    
    var id: Int?
    var userId: Int
    var projectId: Int
}

extension UserProject: ModifiablePivot {
    init(_ user: User, _ project: Project) throws {
        userId = try user.requireID()
        projectId = try project.requireID()
    }
}

extension UserProject: PostgreSQLMigration {
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.create(UserProject.self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.projectId)
            builder.field(for: \.userId)
            builder.reference(from: \.projectId, to: \Project.id, onDelete: .cascade)
            builder.reference(from: \.userId, to: \User.id, onDelete: .cascade)
        }
    }
}

final class FavoriteUser: PostgreSQLModel {
    var id: Int?
    var ownerId: Int
    var favoriteUserId: Int
    
    init(id: Int? = nil, ownerId: Int, favUserId: Int) {
        self.id = id
        self.ownerId = ownerId
        self.favoriteUserId = favUserId
    }
}

extension FavoriteUser: PostgreSQLMigration {
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.create(FavoriteUser.self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.ownerId)
            builder.field(for: \.favoriteUserId)
            builder.reference(from: \.ownerId, to: \User.id)
            builder.reference(from: \.favoriteUserId, to: \User.id)
        }
    }
}

extension FavoriteUser {
    var favorites: Children<FavoriteUser, User> {
        return children(\.id)
    }
    
    var user: Parent<FavoriteUser, User> {
        return parent(\.favoriteUserId)
    }
}
