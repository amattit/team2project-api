//
//  File.swift
//  
//
//  Created by 16997598 on 21.07.2020.
//

import FluentMySQL
import Vapor

final class ContactEnum: MySQLModel {
    var id: Int?
    let title: String
    
    init(id: Int? = nil, title: String) {
        self.id = id
        self.title = title
    }
}

extension ContactEnum: Parameter {}

extension ContactEnum: MySQLMigration {
    static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return MySQLDatabase.create(ContactEnum.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.title)
        }
    }
}

extension ContactEnum: Content {}


struct ContactEnumDefaultData: MySQLMigration {
    static func revert(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return conn.future(())
    }
    
    static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        let _ = ContactEnum(title: "Instagram").save(on: conn).transform(to: ())
        let _ = ContactEnum(title: "Telegram").save(on: conn).transform(to: ())
        let _ = ContactEnum(title: "ВКонтакте").save(on: conn).transform(to: ())
        let _ = ContactEnum(title: "Twitter").save(on: conn).transform(to: ())
        let _ = ContactEnum(title: "Facebook").save(on: conn).transform(to: ())
        return ContactEnum(title: "Openland").save(on: conn).transform(to: ())
    }
}
