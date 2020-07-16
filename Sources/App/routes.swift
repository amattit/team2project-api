import Crypto
import Vapor
import Authentication

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // public routes
    let userController = UserController()
    let projectController = ProjectController()
    let v1 = router.grouped("api", "v1")
    router.post("api", "v1", "signup", use: userController.create)
    
    router.get("api", "v1", "project", use: projectController.allProjects)
    // basic / password auth protected routes
    let basic = v1.grouped(User.basicAuthMiddleware(using: BCryptDigest()))
    basic.post("login", use: userController.login)
    
    // MARK: projects
    let bearer = v1.grouped(User.tokenAuthMiddleware())
    bearer.post("project", use: projectController.createProject)
    bearer.delete("project", Project.parameter, use: projectController.createProject)
    bearer.put("project", Project.parameter, use: projectController.updateProject)
    bearer.get("project", Project.parameter, use: projectController.projectDetail)
    
    //MARK: links
    bearer.get("project", Project.parameter, "link", use: projectController.getLinksForProject)
    bearer.post("project", Project.parameter, "link", use: projectController.addLinkToProject)
    bearer.delete("project", Project.parameter, "link", Link.parameter, use: projectController.deleteLink)
    bearer.put("project", Project.parameter, "link", Link.parameter, use: projectController.updateLink)
    
}
