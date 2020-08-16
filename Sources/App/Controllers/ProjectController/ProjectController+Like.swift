//
//  File.swift
//  
//
//  Created by 16997598 on 16.08.2020.
//

import Vapor

extension ProjectController {
    
    /// Добавить Лайк api/v1/project/123/like
    func addLike(_ req: Request) throws -> Future<LikeResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            return try project.likes.query(on: req).all().flatMap { likes in
                if try !likes.contains(where: {
                    try user.requireID() == $0.ownerId
                }) {
                    let like = Like(projectId: try project.requireID(), ownerId: try user.requireID())
                    return like.save(on: req).map {
                        LikeResponse(id: try $0.requireID(), user: try UserResponse(with: user))
                    }
                } else {
                    throw Abort(HTTPStatus.alreadyReported, reason: "Уже лайкнул")
                }
            }
            
        }
    }
    
    /// Удалить Лайк api/v1/project/123/like/321
    func deleteLike(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        let _ = try req.parameters.next(Project.self)
        return try req.parameters.next(Like.self).flatMap {
            guard try user.requireID() == $0.ownerId else {
                throw Abort(.forbidden, reason: "Только владелец лайка может удалить Лайк")
            }
            return $0.delete(on: req)
                .transform(to: HTTPStatus.ok)
        }
    }
    
    func getProjectLikes(_ req: Request) throws -> Future<[LikeResponse]> {
        return try req.parameters.next(Project.self).flatMap { projects in
            return try projects.likes
                .query(on: req)
                .join(\User.id, to: \Like.ownerId)
                .alsoDecode(User.self)
                .all()
                .map { results in
                    try results.map {
                        LikeResponse(id: try $0.0.requireID(), user: try UserResponse(with: $0.1))
                    }
            }
        }
    }
    
    func getProjectLikeCount(_ req: Request) throws -> Future<LikeCount> {
        return try req.parameters.next(Project.self).flatMap {
            return try $0.likes.query(on: req).count().map {
                return LikeCount(count: $0)
            }
        }
    }
}

struct LikeResponse: Content {
    let id: Int
    let user: UserResponse
}

struct LikeCount: Content {
    let count: Int
}
