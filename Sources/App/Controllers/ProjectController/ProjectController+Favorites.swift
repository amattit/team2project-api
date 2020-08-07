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
        let user = try req.requireAuthenticated(User.self)
        return try user.favoritesProjects.query(on: req).filter(\.isPublished, .equal, 1).all().flatMap { projects in
            return projects.map { project in
                return project.user.query(on: req).first().unwrap(or: Abort(.badRequest)).map { user in
                    return try ProjectListResponse(with: project, and: user)
                }
            }.flatten(on: req)
        }
    }
    /// POST /api/v1/user/favorites/user/:userId - добавление пользователя в избранное
    func setFavoriteUser(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(User.self).flatMap { addedUser in
            return FavoriteUser(ownerId: try user.requireID(), favUserId: try addedUser.requireID()).save(on: req).transform(to: HTTPStatus.ok)
        }
    }
    /// POST /api/v1/user/favorites/project/:projectId - добавление пользователя в избранное
    func setFavoriteProject(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            return user.favoritesProjects.attach(project, on: req).transform(to: HTTPStatus.ok)
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
