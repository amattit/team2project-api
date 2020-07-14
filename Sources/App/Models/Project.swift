import FluentMySQL
import Vapor

/// A single entry of a todo list.
final class Project: MySQLModel {
    
    /// The unique identifier for this `project`.
    var id: Int?

    /// A title describing what this `Todo` entails.
    var title: String
    
    var description: String
    
    var created: Date
    
    var updated: Date?
    
    /// Reference to user that owns this TODO.
    var ownerId: User.ID

    /// Creates a new `Todo`.
    init(id: Int? = nil, name: String, userID: User.ID, description: String) {
        self.id = id
        self.title = name
        self.ownerId = userID
        self.description = description
        self.created = Date()
    }
}

extension Project {
    /// Fluent relation to user that owns this todo.
    var user: Parent<Project, User> {
        return parent(\.ownerId)
    }
}

extension Project {
    var links: Children<Project, Link> {
        return children(\.projectId)
    }
}

/// Allows `Todo` to be used as a Fluent migration.
extension Project: MySQLMigration {
    static func prepare(on connection: MySQLConnection) -> EventLoopFuture<Void> {
        return MySQLDatabase.create(Project.self, on: connection) { (builder) in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.title)
            builder.field(for: \.description)
            builder.field(for: \.created)
            builder.field(for: \.updated)
            builder.field(for: \.ownerId)
            builder.reference(from: \.ownerId, to: \User.id)
        }
    }
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Project: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Project: Parameter { }
