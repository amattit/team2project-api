import FluentMySQL
import Vapor

/// A single entry of a todo list.
final class Project: MySQLModel {
    
    
    static var name: String = "project"
    
    /// The unique identifier for this `project`.
    var id: Int?

    /// A title describing what this `Todo` entails.
    var name: String
    
    var description: String
    
    var link_to_description: String?
    
    var link_to_app: String?
    
    var link_to_site: String?
    
    var created: Date
    
    var updated: Date?
    
    /// Reference to user that owns this TODO.
    var creator_id: User.ID

    /// Creates a new `Todo`.
    init(id: Int? = nil, name: String, userID: User.ID, description: String) {
        self.id = id
        self.name = name
        self.creator_id = userID
        self.description = description
        self.created = Date()
    }
}

extension Project {
    /// Fluent relation to user that owns this todo.
    var user: Parent<Project, User> {
        return parent(\.creator_id)
    }
}

/// Allows `Todo` to be used as a Fluent migration.
extension Project: MySQLMigration {
    
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Project: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Project: Parameter { }
