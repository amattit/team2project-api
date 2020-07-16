//
//  File.swift
//  
//
//  Created by 16997598 on 16.07.2020.
//

import Vapor
import FluentMySQL

struct ProjectLabel: MySQLPivot {
    
    typealias Left = Project
    typealias Right = LabelEnum
    
    static var leftIDKey: LeftIDKey = \.projectId
    static var rightIDKey: RightIDKey = \.labelId
    
    var id: Int?
    var projectId: Int
    var labelId: Int
    
}

extension ProjectLabel: MySQLMigration {
    static func prepare(on connection: MySQLConnection) -> EventLoopFuture<Void> {
        return MySQLDatabase.create(ProjectLabel.self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.projectId)
            builder.field(for: \.labelId)
            builder.reference(from: \.projectId, to: \Project.id)
            builder.reference(from: \.labelId, to: \LabelEnum.id)
        }
    }
}

extension ProjectLabel: ModifiablePivot {
    init(_ project: Project, _ label: LabelEnum) throws {
        projectId = try project.requireID()
        labelId = try label.requireID()
    }
}
