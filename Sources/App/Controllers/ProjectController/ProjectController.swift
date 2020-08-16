import Vapor

/// Simple todo-list controller.
final class ProjectController {
    
    func allProjects(_ req: Request) throws -> Future<[ProjectListResponse]> {
        return Project.query(on: req)
            .filter(\.isPublished, .equal, 1)
            .join(\User.id, to: \Project.ownerId)
            .alsoDecode(User.self)
            .all()
            .flatMap { results in
                return try results.map { res in
                    return try self.getFavoriteProjects(req).flatMap { favorites in
                        return try self.getLabels(for: res.0, on: req).map { labels in
                            return try ProjectListResponse(res.0, labels: labels, user: res.1, isFavorite: favorites.contains {$0.id == res.0.id})
                        }
                    }
                }.flatten(on: req)
        }
    }
    
    func allMyProjectsWithQueryOption(_ req: Request) throws -> Future<[ProjectListResponse]> {
        let user = try req.requireAuthenticated(User.self)
        let query = try req.query.decode(AllMyProjectsQuery.self)
        return try user.projects.query(on: req)
            .filter(\.isPublished, .equal, query.value)
            .all()
            .flatMap { projects in
                return try projects.compactMap { project in
                    return try self.getLabels(for: project, on: req).map {
                        return try ProjectListResponse(project, labels: $0, user: user)
                    }
                }.flatten(on: req)
        }
    }
    
    func projectDetail(_ req: Request) throws -> Future<DetailProjectResponse> {
        return try req.parameters.next(Project.self).flatMap { project in
            if project.isPublished == 0 {
                let _ = try req.requireAuthenticated(User.self)
                return try self.getLabels(for: project, on: req).flatMap { labels in
                    return try self.getLinksRs(project: project, on: req).flatMap { links in
                        return project.user.get(on: req).flatMap { user in
                            return try project.vacancy.query(on: req).all().map { vacancy in
                                return try DetailProjectResponse(project, links: links, labels: labels, user: user, vacancy: vacancy, isPublished: project.isPublished.isPublished)
                            }
                        }
                    }
                }
            } else {
                return try self.getLabels(for: project, on: req).flatMap { labels in
                    return try self.getLinksRs(project: project, on: req).flatMap { links in
                        return project.user.get(on: req).flatMap { user in
                            return try project.vacancy.query(on: req).all().flatMap { vacancy in
                                if try req.isAuthenticated(User.self) {
                                    let selfUser = try req.requireAuthenticated(User.self)
                                    return project.inFavorite.isAttached(selfUser, on: req).map { inFavorite in
                                        return try DetailProjectResponse(project, links: links, labels: labels, user: user, vacancy: vacancy, isPublished: project.isPublished.isPublished, isFavorite: inFavorite)
                                    }
                                } else {
                                    return LabelEnum.query(on: req).count().map { _ in
                                        return try DetailProjectResponse(project, links: links, labels: labels, user: user, vacancy: vacancy, isPublished: project.isPublished.isPublished, isFavorite: false)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func createProject(_ req: Request) throws -> Future<CreateProjectResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(CreateProjectRequest.self).flatMap { request in
            let project = Project(id: nil, name: request.name, userID: try user.requireID(), description: request.description, imagePath: request.imagePath)
            try project.validate()
            return project.save(on: req).map {
                return CreateProjectResponse(id: try $0.requireID(), name: $0.title, description: $0.description, created: Date(), user: UserResponse(id: try user.requireID(), email: user.email), isPublished: $0.isPublished.isPublished)
            }
        }
    }
    
    func updateProject(_ req: Request) throws -> Future<Project> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(UpdateProjectRequest.self).flatMap { updateRequest in
            return try req.parameters.next(Project.self).flatMap { project in
                guard try user.requireID() == project.ownerId else {
                    throw Abort(.forbidden)
                }
                if let title = updateRequest.name {
                    project.title = title
                }
                
                if let description = updateRequest.description {
                    project.description = description
                }
                
                if let imagePath = updateRequest.imagePath {
                    project.imagePath = imagePath
                }
                
                project.updated = Date()
                try project.validate()
                return project.save(on: req)
            }
        }
    }
    
    func publicateProject(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            guard try user.requireID() == project.ownerId else {
                throw Abort(.forbidden, reason: "Только автор проекта может публиковать проект")
            }
            project.isPublished = 1
            return project.save(on: req).transform(to: HTTPStatus.ok)
        }
    }
    
    func checkoutProject(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            guard try user.requireID() == project.ownerId else {
                throw Abort(.forbidden, reason: "Только автор проекта может вернуть проект в черновик")
            }
            project.isPublished = 0
            return project.save(on: req).transform(to: HTTPStatus.ok)
        }
    }
    
    func deleteProject(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project -> Future<Void> in
            guard try project.ownerId == user.requireID() else {
                throw Abort(.forbidden, reason: "Только автор проекта может удалить проект")
            }
            return project.delete(on: req)
        }.transform(to: .ok)
    }
 }
