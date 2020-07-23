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
    
    var imagePath: String?
    
    var isPublished: Int

    init(id: Int? = nil, name: String, userID: User.ID, description: String, imagePath: String? = nil, isPublished: Bool = false) {
        self.id = id
        self.title = name
        self.ownerId = userID
        self.description = description
        self.created = Date()
        self.imagePath = imagePath
        switch isPublished {
        case true:
            self.isPublished = 1
        case false:
            self.isPublished = 0
        }
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

extension Project {
    var vacancy: Children<Project, Vacancy> {
        return children(\.projectId)
    }
}

extension Project {
    var labels: Siblings<Project, LabelEnum, ProjectLabel> {
        return siblings()
    }
}


/// Allows `Todo` to be used as a Fluent migration.
extension Project: MySQLMigration {
    static func prepare(on connection: MySQLConnection) -> EventLoopFuture<Void> {
        return MySQLDatabase.create(Project.self, on: connection) { (builder) in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.title)
            builder.field(for: \.description, type: .varchar(3000, characterSet: nil, collate: nil))
            builder.field(for: \.created)
            builder.field(for: \.updated)
            builder.field(for: \.ownerId)
            builder.field(for: \.imagePath)
            builder.field(for: \.isPublished)
            builder.reference(from: \.ownerId, to: \User.id)
        }
    }
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Project: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Project: Parameter { }

extension Project: Validatable {
    static func validations() throws -> Validations<Project> {
        var validations = Validations(Project.self)
        try validations.add(\.title, .count(3...255))
        try validations.add(\.description, .count(3...3000))
        return validations
    }
}
