//
//  File.swift
//  
//
//  Created by 16997598 on 28.07.2020.
//

import Vapor

extension ProjectController {
    /// GET /api/v1/user/favorites - сразу все избранные проекты и пользователи
    func getFavorites(_ req: Request) throws -> Future<FavoritesResponse> {
        return try getFavoriteProjects(req).flatMap { projectList in
            return try self.getFavoriteUsers(req).map { userList in
                return FavoritesResponse(projects: projectList, users: userList)
            }
        }
    }
    
    /// GET /api/v1/user/favorites/user - только избранные пользователи
    func getFavoriteUsers(_ req: Request) throws -> Future<[UserResponse]> {
        let user = try req.requireAuthenticated(User.self)
        return try user.favoriteUsers.query(on: req).all().flatMap { favUsers in
            favUsers.map {
                $0.user.query(on: req).first().unwrap(or: Abort(.badRequest, reason: "Плохой запрос")).map { try UserResponse(with: $0)}
            }.flatten(on: req)
        }
    }
    /// GET /api/v1/user/favorites/project - только избранные проекты
    func getFavoriteProjects(_ req: Request) throws -> Future<[ProjectListResponse]> {
        if try req.isAuthenticated(User.self) {
            let user = try req.requireAuthenticated(User.self)
            return try user.favoritesProjects.query(on: req).filter(\.isPublished, .equal, 1)
                .join(\User.id, to: \Project.ownerId)
                .alsoDecode(User.self)
                .all().flatMap { result in
                return try result.map { res in
//                    return try self.getFavoriteProjects(req).flatMap { favorites in
                        return try self.getLabels(for: res.0, on: req).flatMap { labels in
                            return try self.getLikesForProject(res.0, on: req).flatMap { likes in
                                return try self.getCommentsFor(res.0, on: req).map { comments in
                                    let user = res.1
                                    var isLike = false
                                    if try req.isAuthenticated(User.self) {
                                        let user = try req.requireAuthenticated(User.self)
                                        isLike = try likes.contains(where: {
                                            try $0.user.id == user.requireID()
                                        })
                                    } else {
                                        isLike = try likes.contains(where: {
                                            try $0.user.id == user.requireID()
                                        })
                                    }
                                    return try ProjectListResponse(res.0, labels: labels, user: res.1, isFavorite: true, isLike: isLike, likeCount: likes.count, commentCount: comments.count)
                                }
                            }
                        }
//                    }
                }.flatten(on: req)
            }
        } else {
            return LabelEnum.query(on: req).all().map { _ in
                return [ProjectListResponse]()
            }
            
        }
        
    }
    /// POST /api/v1/user/favorites/user/:userId - добавление пользователя в избранное
    func setFavoriteUser(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(User.self).flatMap { addedUser in
            return FavoriteUser.query(on: req).filter(\.ownerId, .equal, try user.requireID()).all().flatMap { favUsers in
                if  try !favUsers.contains(where: { try addedUser.requireID() == $0.favoriteUserId }) {
                    return FavoriteUser(ownerId: try user.requireID(), favUserId: try addedUser.requireID()).save(on: req).transform(to: HTTPStatus.ok)
                } else {
                    throw Abort(.alreadyReported, reason: "")
                }
            }
        }
    }
    /// POST /api/v1/user/favorites/project/:projectId - добавление пользователя в избранное
    func setFavoriteProject(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            return user.favoritesProjects.isAttached(project, on: req).flatMap { isAttached in
                if !isAttached {
                    return user.favoritesProjects.attach(project, on: req).transform(to: HTTPStatus.ok)
                } else {
                    throw Abort(.alreadyReported, reason: "Уже в избранном")
                }
            }
        }
    }
    
    /// DELETE /api/v1/user/favorites/user/:userId - удаление пользователя из избранного
    func deleteFavoriteUser(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(User.self).flatMap { addedUser in
            //            return
            return FavoriteUser.query(on: req).filter(\.favoriteUserId, .equal, try addedUser.requireID()).filter(\.ownerId, .equal, try user.requireID()).all().map {
                return $0.map {$0.delete(on: req)}
            }.transform(to: .ok)
        }
    }
    
    /// DELETE /api/v1/user/favorites/project/:projectId - удаление проекта из избранного
    func deleteFavoriteProject(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            return user.favoritesProjects.detach(project, on: req).transform(to: HTTPStatus.ok)
        }
    }
}

extension ProjectController.ProjectListResponse {
    init(with project: Project, and user: User) throws {
        self.id = try project.requireID()
        self.name = project.title
        self.description = project.description
        self.useremail = ""
        self.created = project.created
        self.user = try UserResponse(with: user)
        self.labels = nil
        self.imagePath = project.imagePath
        if project.isPublished == 1 {
            self.isPublished = true
        } else {
            self.isPublished = false
        }
    }
}

extension ProjectController.ProjectListResponse {
    init(with project: Project, and user: User, isFavorite: Bool = false) throws {
        self.id = try project.requireID()
        self.name = project.title
        self.description = project.description
        self.useremail = ""
        self.created = project.created
        self.user = try UserResponse(with: user)
        self.labels = nil
        self.imagePath = project.imagePath
        if project.isPublished == 1 {
            self.isPublished = true
        } else {
            self.isPublished = false
        }
        self.isFavorite = isFavorite
    }
}

extension ProjectController {
    struct FavoritesResponse: Content {
        let projects: [ProjectListResponse]
        let users: [UserResponse]
    }
}

extension Int {
    var isPublished: Bool {
        switch self {
        case 1:
            return true
        default:
            return false
        }
    }
}
