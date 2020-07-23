import Vapor
import FluentSQLite

/// Simple todo-list controller.
final class ProjectController {

    func allProjects(_ req: Request) throws -> Future<[ProjectListResponse]> {
        return Project.query(on: req).filter(\.isPublished, .equal, 1).all().flatMap {
            return try $0.map { project in
                return try self.getUserFor(project, on: req).map { user in
                    return try self.getLabels(for: project, on: req).map { labels in
                        return ProjectListResponse(id: project.id!, name: project.title, description: project.description, useremail: user.email, created: project.created, user: try UserResponse(with: user), labels: labels)
                    }
                }
            }.flatten(on: req)
        }.flatMap { $0.flatten(on: req) }
    }
    
    func allMyPublickProjects(_ req: Request) throws -> Future<[ProjectListResponse]> {
        let user = try req.requireAuthenticated(User.self)
        let query = try req.query.decode(AllMyProjectsQuery.self)
        return Project.query(on: req).filter(\.ownerId, .equal, try user.requireID()).filter(\.isPublished, .equal, query.value).all().flatMap {
            return try $0.map { project in
                return try self.getUserFor(project, on: req).map { user in
                    return try self.getLabels(for: project, on: req).map { labels in
                        return ProjectListResponse(id: project.id!, name: project.title, description: project.description, useremail: user.email, created: project.created, user: try UserResponse(with: user), labels: labels)
                    }
                }
            }.flatten(on: req)
        }.flatMap { $0.flatten(on: req) }
    }
    
    func checkoutProjects(_ req: Request) throws -> Future<[ProjectListResponse]> {
        let user = try req.requireAuthenticated(User.self)
        return Project.query(on: req).filter(\.ownerId, .equal, try user.requireID()).filter(\.isPublished, .equal, 0).all().flatMap {
            return try $0.map { project in
                return try self.getUserFor(project, on: req).map { user in
                    return try self.getLabels(for: project, on: req).map { labels in
                        return ProjectListResponse(id: try project.requireID(), name: project.title, description: project.description, useremail: user.email, created: project.created, user: UserResponse(id: try user.requireID(), email: user.email), labels: labels)
                    }
                }
            }.flatten(on: req)
        }.flatMap { $0.flatten(on: req) }
    }
    
    func projectDetail(_ req: Request) throws -> Future<DetailProjectResponse> {
        return try req.parameters.next(Project.self).flatMap { project in
            return try self.getLabels(for: project, on: req).flatMap { labels in
                return try self.getLinksRs(project: project, on: req).flatMap { links in
                    return project.user.get(on: req).map { user in
                        return try DetailProjectResponse(project, links: links, labels: labels, user: user)
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
                return CreateProjectResponse(id: try $0.requireID(), name: $0.title, description: $0.description, created: Date(), user: UserResponse(id: try user.requireID(), email: user.email))
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
    
    /// don't use
    private func getUserFor(_ project: Project, on req: Request) throws -> Future<User> {
        return project.user.query(on: req).first().unwrap(or: Abort(.notFound, reason: "Пользователь не найден"))
    }
    
 }
