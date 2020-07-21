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
    
    
}
