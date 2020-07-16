import Vapor
import FluentSQLite

/// Simple todo-list controller.
final class ProjectController {

    func allProjects(_ req: Request) throws -> Future<[ProjectListResponse]> {
        return Project.query(on: req).all().flatMap {
            return try $0.map { project in
                return try self.getUserFor(project, on: req).map { user in
                    return ProjectListResponse(id: project.id!, name: project.title, description: project.description, useremail: user.email, created: project.created, user: UserResponse(id: try user.requireID(), email: user.email))
                }
            }.flatten(on: req)
        }
    }
    
    func projectDetail(_ req: Request) throws -> Future<DetailProjectResponse> {
        return try req.parameters.next(Project.self).flatMap { project in
            return try self.getLinksRs(project: project, on: req).map { links in
                return DetailProjectResponse(id: try project.requireID(), name: project.title, description: project.description, created: project.created, links: links)
            }
            
        }
    }
    
    func createProject(_ req: Request) throws -> Future<CreateProjectResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(CreateProjectRequest.self).flatMap { request in
            return Project(id: nil, name: request.name, userID: try user.requireID(), description: request.description).save(on: req).map {
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
                project.title = updateRequest.name
                project.description = updateRequest.description
                project.updated = Date()
                return project.save(on: req)
            }
        }
    }
    
    func deleteProject(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project -> Future<Void> in
            guard try project.ownerId == user.requireID() else {
                throw Abort(.forbidden)
            }
            return project.delete(on: req)
        }.transform(to: .ok)
    }
    
    func addLinkToProject(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project -> Future<Void> in
            guard try user.requireID() == project.ownerId else {
                throw Abort(.forbidden)
            }
            return try req.content.decode(AddLinkRequest.self).map { link in
                return Link(title: link.title, link: link.link, ownerId: try user.requireID(), projectId: try project.requireID()).save(on: req)
            }
        }.transform(to: .ok)
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
    
    func updateLink(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        let _ = try req.parameters.next(Project.self)
        return try req.parameters.next(Link.self).flatMap { link in
            guard try user.requireID() == link.ownerId else {
                throw Abort(.forbidden)
            }
        
            return try req.content.decode(UpdateLinkRequest.self).flatMap { t in
                link.title = t.title
                link.link = t.link
                return link.update(on: req).transform(to: HTTPStatus.ok)
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
    
    private func getUserFor(_ project: Project, on req: Request) throws -> Future<User> {
        return project.user.query(on: req).first().unwrap(or: Abort(.notFound, reason: "Пользователь не найден"))
    }
    
    private func getLinksRs(project: Project, on req: Request) throws -> Future<[LinkResponse]> {
        
        return try project.links.query(on: req).all().map {
            return try $0.map {
                LinkResponse(id: try $0.requireID(), title: $0.title, link: $0.link)
            }
        }
    }
    
 }

// MARK: Content

/// Represents data required to create a new todo.
struct CreateProjectRequest: Content {
    /// Todo title.
    let name: String
    let description: String
}

struct UpdateProjectRequest: Content {
    let id: Int
    let name: String
    let description: String
}

struct ProjectListResponse: Content {
    let id: Int
    let name: String
    let description: String
    let useremail: String
    let created: Date
    let user: UserResponse?
}

struct CreateProjectResponse: Content {
    let id: Int
    let name: String
    let description: String
    let created: Date
    let user: UserResponse?
}

struct DetailProjectResponse: Content {
    let id: Int
    let name: String
    let description: String
    let created: Date
    let links: [LinkResponse]?
}


struct AddLinkRequest: Content {
    let title: String
    let link: String
}

struct UpdateLinkRequest: Content {
    let title: String
    let link: String
//    let id: Int
}

struct LinkResponse: Content {
    let id: Int
    let title: String
    let link: String
}
