import Crypto
import Vapor
import FluentMySQL

/// Creates new users and logs them in.
final class UserController {
    /// Logs a user in, returning a token for accessing protected endpoints.
    func login(_ req: Request) throws -> Future<UserToken> {
        // get user auth'd by basic auth middleware
        let user = try req.requireAuthenticated(User.self)
        // create new token for this user
        let token = try UserToken.create(userID: user.requireID())
        // save and return token
        return token.save(on: req)
    }
    
    /// Creates a new user.
    func create(_ req: Request) throws -> Future<UserToken> {
        // decode request content
        return try req.content.decode(CreateUserRequest.self).flatMap { user -> Future<User> in
            // verify that passwords match
            guard user.password == user.verifyPassword else {
                throw Abort(.badRequest, reason: "Password and verification must match.")
            }
            let hash = try BCrypt.hash(user.password)
            let user = User(id: nil, email: user.email, passwordHash: hash)
            try user.validate()
            return user.save(on: req)
        }.flatMap { user in
            let token = try UserToken.create(userID: user.requireID())
            return token.save(on: req)
        }
    }
    
    func getSelf(_ req: Request) throws -> Future<UserResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try user.contacts.query(on: req).all().map { contacts in
            return try UserResponse(with: user, contacts: contacts)
        }
    }
    
    func getUser(_ req: Request) throws -> Future<UserResponse> {
        return try req.parameters.next(User.self).flatMap { user in
            return try user.contacts.query(on: req).all().map { contacts in
                return try UserResponse(with: user, contacts: contacts)
            }
        }
    }
    
    func updateUser(_ req: Request) throws -> Future<UserResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(UpdateUserRequest.self).flatMap { userData in
            if let email = userData.email {
                user.email = email
            }
            
            if let name = userData.name {
                user.name = name
            }
            
            if let imagePath = userData.imagePath {
                user.imagePath = imagePath
            }
            try user.validate()
            return user.save(on: req).map {
                return try UserResponse(with: $0)
            }
        }
    }
}

// MARK: Content

/// Data required to create a user.
struct CreateUserRequest: Content {
    /// User's full name.
    var name: String?
    
    /// User's email address.
    var email: String
    
    /// User's desired password.
    var password: String
    
    /// User's password repeated to ensure they typed it correctly.
    var verifyPassword: String
}

/// Public representation of user data.
struct UserResponse: Content {
    /// User's unique identifier.
    /// Not optional since we only return users that exist in the DB.
    var id: Int
    
    /// User's email address.
    var email: String
    
    var name: String?
    
    var imagePath: String?
    
    var contacts: [ContactResponse]?
    
    init(id: Int, email: String, name: String? = nil, imagePath: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.imagePath = imagePath
    }
    
    init(with user: User) throws {
        self.id = try user.requireID()
        self.email = user.email
        self.name = user.name
        self.imagePath = user.imagePath
    }
    
    init(with user: User, contacts: [Contact]) throws {
        try self.init(with: user)
        self.contacts = try contacts.map { try ContactResponse(contact: $0)}
    }
}

struct SetImageRequest: Content {
    let imagePath: String
}

struct UpdateUserRequest: Content {
    var email: String?
    
    var name: String?
    
    var imagePath: String?
}
