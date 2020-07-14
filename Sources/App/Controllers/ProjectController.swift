import Vapor
import FluentSQLite

/// Simple todo-list controller.
final class ProjectController {

    func allProjects(_ req: Request) throws -> Future<[ProjectListResponse]> {
        return Project.query(on: req).all().flatMap {
            return try $0.map { project in
                return try self.getUserFor(project, on: req).map {
                    return ProjectListResponse(id: project.id!, name: project.title, description: project.description, username: $0.name, useremail: $0.email, created: project.created)
                }
            }.flatten(on: req)
        }
    }
    
    
    func createProject(_ req: Request) throws -> Future<CreateProjectResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(CreateProjectRequest.self).flatMap { request in
            return Project(id: nil, name: request.name, userID: try user.requireID(), description: request.description).save(on: req)
        }.map { pr in
            return CreateProjectResponse(id: try pr.requireID(), name: pr.title, description: pr.description, created: pr.created)
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
    
    private func getUserFor(_ project: Project, on req: Request) throws -> Future<User> {
        return project.user.query(on: req).first().unwrap(or: Abort(.notFound, reason: "Пользователь не найден"))
    }
 }

// MARK: Content

/// Represents data required to create a new todo.
struct CreateProjectRequest: Content {
    /// Todo title.
    let name: String
    let description: String
}

struct ProjectListResponse: Content {
    let id: Int
    let name: String
    let description: String
    let username: String?
    let useremail: String
    let created: Date
}

struct CreateProjectResponse: Content {
    let id: Int
    let name: String
    let description: String
    let created: Date
}
