//
//  File.swift
//  
//
//  Created by 16997598 on 22.07.2020.
//

import Vapor

extension ProjectController {
    func addLinkToProject(_ req: Request) throws -> Future<LinkResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            guard try user.requireID() == project.ownerId else {
                throw Abort(.forbidden, reason: "Только автор проекта может добавлять ссылки")
            }
            return try req.content.decode(AddLinkRequest.self).flatMap { link in
                let link = Link(title: link.title, link: link.link, ownerId: try user.requireID(), projectId: try project.requireID())
                try link.validate()
                return link.save(on: req).map { link in
                    return LinkResponse(id: try link.requireID(), title: link.title, link: link.link)
                }
            }
        }
    }
    
    func deleteLink(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        let _ = try req.parameters.next(Project.self)
        return try req.parameters.next(Link.self).flatMap { link -> Future<Void> in
            guard try user.requireID() == link.ownerId else {
                throw Abort(.forbidden)
            }
            return link.delete(on: req)
        }.transform(to: .ok)
    }
    
    func updateLink(_ req: Request) throws -> Future<LinkResponse> {
        let user = try req.requireAuthenticated(User.self)
        let _ = try req.parameters.next(Project.self)
        return try req.parameters.next(Link.self).flatMap { link in
            guard try user.requireID() == link.ownerId else {
                throw Abort(.forbidden)
            }
        
            return try req.content.decode(UpdateLinkRequest.self).flatMap { t in
                link.title = t.title
                link.link = t.link
                try link.validate()
                return link.update(on: req).map { link in
                    return LinkResponse(id: try link.requireID(), title: link.title, link: link.link)
                }
            }
        }
    }
    
    func getLinksForProject(_ req: Request) throws -> Future<[LinkResponse]> {
        let _ = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self)
            .flatMap { try $0.links.query(on: req).all() }
            .map {
                try $0.map { lnk in
                    return LinkResponse(id: try lnk.requireID(), title: lnk.title, link: lnk.link)
                }
        }
    }
    /// don use
    internal func getLinksRs(project: Project, on req: Request) throws -> Future<[LinkResponse]> {
        return try project.links.query(on: req).all().map {
            return try $0.map {
                LinkResponse(id: try $0.requireID(), title: $0.title, link: $0.link)
            }
        }
    }
}
