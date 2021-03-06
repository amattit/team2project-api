//
//  File.swift
//  
//
//  Created by 16997598 on 16.07.2020.
//

import FluentPostgreSQL
import Vapor

final class LabelEnum: PostgreSQLModel {
    var id: Int?
    let title: String
    
    init(id: Int? = nil, title: String) {
        self.id = id
        self.title = title
    }
}

extension LabelEnum: Parameter {}

extension LabelEnum: PostgreSQLMigration {
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.create(LabelEnum.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.title)
        }
    }
}

extension LabelEnum: Content {}

extension LabelEnum {
    var projects: Siblings<LabelEnum, Project, ProjectLabel> {
        return siblings()
    }
}

struct LabelEnumDefaultData: PostgreSQLMigration {
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return conn.future(())
    }
    
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        let _ = LabelEnum(title: "делаем mvp").save(on: conn).transform(to: ())
        let _ = LabelEnum(title: "mvp готов").save(on: conn).transform(to: ())
        let _ = LabelEnum(title: "есть идея").save(on: conn).transform(to: ())
        let _ = LabelEnum(title: "есть ТЗ").save(on: conn).transform(to: ())
        let _ = LabelEnum(title: "работает").save(on: conn).transform(to: ())
        let _ = LabelEnum(title: "делаем анализ").save(on: conn).transform(to: ())
        let _ = LabelEnum(title: "ищем деньги").save(on: conn).transform(to: ())
        return LabelEnum(title: "масштабируем").save(on: conn).transform(to: ())
        
    }
}
