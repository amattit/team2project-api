import Authentication
import Vapor
import FluentPostgreSQL

/// A registered user, capable of owning todo items.
final class User: PostgreSQLModel {
    /// User's unique identifier.
    /// Can be `nil` if the user has not been saved yet.
    var id: Int?
    
    /// User's full name.
    var name: String?
    
    /// User's email address.
    var email: String
    
    /// BCrypt hash of the user's password.
    var password: String
    
    var created: Date
    
    var auth_key: String
    
    var imagePath: String?
    
    var role: String?
    
    var about: String?
    
    var location: String?
    /// Creates a new `User`.
    init(id: Int? = nil, email: String, passwordHash: String, name: String? = nil, imagePath: String? = nil, location: String? = nil) {
        self.id = id
//        self.name = name
        self.email = email
        self.password = passwordHash
        self.created = Date()
        self.auth_key = String(UUID().uuidString.prefix(32))
        self.name = name
        self.imagePath = imagePath
        self.location = location
    }
}

/// Allows users to be verified by basic / password auth middleware.
extension User: PasswordAuthenticatable {
    /// See `PasswordAuthenticatable`.
    static var usernameKey: WritableKeyPath<User, String> {
        return \.email
    }
    
    /// See `PasswordAuthenticatable`.
    static var passwordKey: WritableKeyPath<User, String> {
        return \.password
    }
}

extension User {
    var contacts: Children<User, Contact> {
        return children(\.ownerId)
    }
}

extension User {
    var favoritesProjects: Siblings<User, Project, UserProject> {
        return siblings()
    }
}

extension User {
    var favoriteUsers: Children<User, FavoriteUser> {
        return children(\.ownerId)
    }
}

/// Allows users to be verified by bearer / token auth middleware.
extension User: TokenAuthenticatable {
    /// See `TokenAuthenticatable`.
    typealias TokenType = UserToken
}

/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter { }

extension User: PostgreSQLMigration {
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.create(User.self, on: conn) { (builder) in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.name)
            builder.field(for: \.email)
            builder.field(for: \.password)
            builder.field(for: \.created)
            builder.field(for: \.auth_key)
            builder.field(for: \.imagePath)
            builder.field(for: \.role)
            builder.field(for: \.about)
            builder.field(for: \.location)
        }
    }
}

extension User: Validatable {
    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)
        try validations.add(\.email, .email)
        try validations.add(\.about, .count(0...6000) || .nil)
        return validations
    }
}
