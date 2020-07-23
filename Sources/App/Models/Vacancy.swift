//
//  File.swift
//  
//
//  Created by 16997598 on 23.07.2020.
//

import Vapor
import FluentMySQL

final class Vacancy: MySQLModel {
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

extension Vacancy: MySQLMigration {
    static func prepare(on connection: MySQLConnection) -> EventLoopFuture<Void> {
        return MySQLDatabase.create(Vacancy.self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.title)
            builder.field(for: \.shareType)
            builder.field(for: \.shareValue)
            builder.field(for: \.created)
            builder.field(for: \.updated)
            builder.field(for: \.projectId)
            builder.field(for: \.ownerId)
            builder.field(for: \.isVacant)
            builder.field(for: \.aboutVacancy, type: .varchar(3000, characterSet: nil, collate: nil))
            builder.field(for: \.aboutFeatures, type: .varchar(3000, characterSet: nil, collate: nil))
            builder.reference(from: \.projectId, to: \Project.id)
            builder.reference(from: \.ownerId, to: \User.id)
        }
    }
}

extension Vacancy {
    final class ShareType: MySQLModel {
        var id: Int?
        var title: String
        
        init(title: String) {
            self.title = title
        }
    }
}

extension Vacancy.ShareType: Content {}

extension Vacancy.ShareType: MySQLMigration {
    static func prepare(on connection: MySQLConnection) -> EventLoopFuture<Void> {
        return MySQLDatabase.create(Vacancy.ShareType.self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.title)
        }
    }
}

struct ShareTypeDefaultData: MySQLMigration {
    static func revert(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return conn.future(())
    }
    
    static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        let _ = Vacancy.ShareType(title: "Share").save(on: conn).transform(to: ())
        let _ = Vacancy.ShareType(title: "PartTime").save(on: conn).transform(to: ())
        return Vacancy.ShareType(title: "FullTime").save(on: conn).transform(to: ())
    }
}
