import Crypto
import Vapor
import Authentication

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // public routes
    let userController = UserController()
    let projectController = ProjectController()
    let v1 = router.grouped("api", "v1")
    let basic = v1.grouped(User.basicAuthMiddleware(using: BCryptDigest()))
    let bearer = v1.grouped(User.tokenAuthMiddleware())
    // MARK: User
    router.post("api", "v1", "signup", use: userController.create)
    basic.post("login", use: userController.login)
    bearer.get("user", use: userController.getSelf)
    bearer.put("user", use: userController.updateUser)
    
    // MARK: projects
    
    router.get("api", "v1", "project", use: projectController.allProjects)
    bearer.post("project", use: projectController.createProject)
    bearer.delete("project", Project.parameter, use: projectController.deleteProject)
    bearer.put("project", Project.parameter, use: projectController.updateProject)
    bearer.get("project", Project.parameter, use: projectController.projectDetail)
    bearer.put("project", Project.parameter, "public", use: projectController.publicateProject)
    bearer.put("project", Project.parameter, "checkout", use: projectController.checkoutProject)
    
    //MARK: links
    bearer.get("project", Project.parameter, "link", use: projectController.getLinksForProject)
    bearer.post("project", Project.parameter, "link", use: projectController.addLinkToProject)
    bearer.delete("project", Project.parameter, "link", Link.parameter, use: projectController.deleteLink)
    bearer.put("project", Project.parameter, "link", Link.parameter, use: projectController.updateLink)
    
    //MARK: Labels
    bearer.get("project", "label", use: projectController.getLabels)
    bearer.post("project", Project.parameter, "label", use: projectController.addLabelToProject)
    bearer.delete("project", Project.parameter, "label", use: projectController.removeLabelFromProject)
}
