import Crypto
import Vapor
import Authentication

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // public routes
    let userController = UserController()
    let projectController = ProjectController()
    let v1 = router.grouped("api", "v1")
    router.post("signup", use: userController.create)
    
    router.get("project", use: projectController.allProjects)
    // basic / password auth protected routes
    let basic = v1.grouped(User.basicAuthMiddleware(using: BCryptDigest()))
    basic.post("login", use: userController.login)
    
    // bearer / token auth protected routes
    let bearer = v1.grouped(User.tokenAuthMiddleware())
    bearer.post("project", use: projectController.createProject)
    bearer.delete("project", Project.parameter, use: projectController.createProject)
//    let todoController = TodoController()
//    bearer.get("todos", use: todoController.index)
//    bearer.post("todos", use: todoController.create)
//    bearer.delete("todos", Todo.parameter, use: todoController.delete)
}
//
//extension Digest: PasswordVerifier {
//    public func verify(_ password: LosslessDataConvertible, created hash: LosslessDataConvertible) throws -> Bool {
//        return password.convertToData() == hash.convertToData()
//    }
//    
//    
//}
