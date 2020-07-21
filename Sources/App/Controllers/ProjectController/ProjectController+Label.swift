//
//  File.swift
//  
//
//  Created by 16997598 on 22.07.2020.
//

import Vapor

extension ProjectController {
    func getLabels(_ req: Request) throws -> Future<[LabelEnum]> {
        return LabelEnum.query(on: req).all()
    }
    
    func addLabelToProject(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            guard try user.requireID() == project.ownerId else {
                throw Abort(.forbidden, reason: "Только пользователь создавший проект может внести изменения в лэйблы")
            }
            return try req.content.decode(AddLabelToProject.self).map { labelDto in
                return try self.getLabelById(labelDto.labelId, on: req).map { label in
                    return project.labels.attach(label, on: req)
                }
            }.transform(to: HTTPStatus.ok)
        }
    }
    
    func removeLabelFromProject(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            guard try user.requireID() == project.ownerId else {
                throw Abort(.forbidden, reason: "Только пользователь создавший проект может внести изменения в лэйблы")
            }
            return try req.content.decode(AddLabelToProject.self).map { labelDto in
                return try self.getLabelById(labelDto.labelId, on: req).map { label in
                    return project.labels.detach(label, on: req)
                }
            }.transform(to: HTTPStatus.ok)
        }
    }
    
    /// don use
    internal func getLabelById(_ id: Int, on req: Request) throws -> Future<LabelEnum> {
        return LabelEnum.query(on: req).filter(\.id, .equal, id).first().unwrap(or: Abort(.notFound, reason: "Label not found"))
    }
    
    /// don use
    internal func getLabels(for project: Project, on req: Request) throws -> Future<[LabelEnum]> {
        return try project.labels.query(on: req).all()
    }
}
