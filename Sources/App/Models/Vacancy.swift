//
//  File.swift
//  
//
//  Created by 16997598 on 23.07.2020.
//

import Vapor
import FluentPostgreSQL

final class Vacancy: PostgreSQLModel {
    var id: Int?
    
    /// Название вакансии
    var title: String
    
    /// Доля в процентах
    var shareType: String
    
    /// возвращается в случае если ShareType == share
    var shareValue: Int?
    
    var created: Date
    
    var updated: Date?
    
    var projectId: Project.ID
    
    var ownerId: User.ID
    
    var isVacant: Bool
    
    var aboutVacancy: String?
    
    var aboutFeatures: String?
    
    init(id: Int? = nil, title: String, shareType: String, shareValue: Int?, projectId: Int, ownerId: Int, isVacant: Bool = true ,aboutVacancy: String?, aboutFeatures: String?) {
        self.id = id
        self.title = title
        self.shareType = shareType
        self.shareValue = shareValue
        self.created = Date()
        self.projectId = projectId
        self.ownerId = ownerId
        self.isVacant = isVacant
        self.aboutVacancy = aboutVacancy
        self.aboutFeatures = aboutFeatures
    }
}

extension Vacancy: Parameter {}

extension Vacancy {
    var owner: Parent<Vacancy, User> {
        return parent(\.ownerId)
    }
    
    var project: Parent<Vacancy, Project> {
        return parent(\.projectId)
    }
}

extension Vacancy: PostgreSQLMigration {
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.create(Vacancy.self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.title)
            builder.field(for: \.shareType)
            builder.field(for: \.shareValue)
            builder.field(for: \.created)
            builder.field(for: \.updated)
            builder.field(for: \.projectId)
            builder.field(for: \.ownerId)
            builder.field(for: \.isVacant)
            builder.field(for: \.aboutVacancy, type: .varchar(3000))
            builder.field(for: \.aboutFeatures, type: .varchar(3000))
            builder.reference(from: \.projectId, to: \Project.id, onDelete: .cascade)
            builder.reference(from: \.ownerId, to: \User.id, onDelete: .cascade)
        }
    }
}

extension Vacancy {
    final class ShareType: PostgreSQLModel {
        var id: Int?
        var title: String
        
        init(title: String) {
            self.title = title
        }
    }
}

extension Vacancy.ShareType: Content {}

extension Vacancy.ShareType: PostgreSQLMigration {
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.create(Vacancy.ShareType.self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.title)
        }
    }
}

struct ShareTypeDefaultData: PostgreSQLMigration {
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return conn.future(())
    }
    
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        let _ = Vacancy.ShareType(title: "Share").save(on: conn).transform(to: ())
        let _ = Vacancy.ShareType(title: "PartTime").save(on: conn).transform(to: ())
        return Vacancy.ShareType(title: "FullTime").save(on: conn).transform(to: ())
    }
}

extension Vacancy: Validatable {
    static func validations() throws -> Validations<Vacancy> {
        var validations = Validations(Vacancy.self)
        try validations.add(\.title, .count(3...255))
        return validations
    }
}
