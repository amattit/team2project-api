//
//  File.swift
//  
//
//  Created by 16997598 on 16.08.2020.
//

import Vapor

extension ProjectController {
    /// POST  /api/v1/project/1/comment
    func addComment(_ req: Request) throws -> Future<CommentResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            return try req.content.decode(CreateCommentRequest.self).flatMap { commentRq in
                return Comment(title: commentRq.title, ownerId: try user.requireID(), projectId: try project.requireID()).save(on: req).map { comment in
                    return try CommentResponse(comment, user: user)
                }
            }
        }
    }
    
    func deleteComment(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        let _ = try req.parameters.next(Project.self)
        return try req.parameters.next(Comment.self).flatMap { comment in
            guard try user.requireID() == comment.ownerId else {
                throw Abort(.forbidden, reason: "Запрещено удалять чужие комментарии")
            }
            return comment.delete(on: req).transform(to: .ok)
        }
    }
    
    func getComments(_ req: Request) throws -> Future<[CommentResponse]> {
        return try req.parameters.next(Project.self).flatMap { project in
            return try project.comments
                .query(on: req)
                .join(\User.id, to: \Comment.ownerId)
                .alsoDecode(User.self)
                .all()
                .map { comments in
                    try comments.map {
                        try CommentResponse($0.0, user: $0.1)
                    }
            }
        }
    }
    
    func getCommentsCount(_ req: Request) throws -> Future<CommentCount> {
        return try req.parameters.next(Project.self).flatMap {
            return try $0.comments.query(on: req).count().map {
                CommentCount(count: $0)
            }
        }
    }
}
