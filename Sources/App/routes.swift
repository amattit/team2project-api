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
    // MARK: User - Done
    router.post("api", "v1", "signup", use: userController.create)
    basic.post("login", use: userController.login)
    bearer.get("user", use: userController.getSelf)
    bearer.put("user", use: userController.updateUser)
    router.get("api", "v1", "user", User.parameter, use: userController.getUser)
    router.get("api", "v1", "users", use: userController.getAllUsers)
    
    //MARK: Contacts
    bearer.get("user", "contact", use: userController.getUserContacts)
    bearer.get("user", "contactType", use: userController.getContactsEnum)
    bearer.post("user", "contact", use: userController.createContact)
    bearer.put("user", "contact", Contact.parameter, use: userController.updateContact) // поправить DTO
    bearer.delete("user", "contact", Contact.parameter, use: userController.deleteContact)
    
    // MARK: projects
    bearer.get("project", use: projectController.allProjects) // - done
    bearer.get("project", "my", use: projectController.allMyProjectsWithQueryOption) // - done
    bearer.post("project", use: projectController.createProject) // - done
    bearer.delete("project", Project.parameter, use: projectController.deleteProject) // - done
    bearer.put("project", Project.parameter, use: projectController.updateProject) // - done
    bearer.get("project", Project.parameter, use: projectController.getDetails) // - done
    bearer.put("project", Project.parameter, "public", use: projectController.publicateProject) // - done
    bearer.put("project", Project.parameter, "checkout", use: projectController.checkoutProject) // - done
    
    //MARK: links
    bearer.get("project", Project.parameter, "link", use: projectController.getLinksForProject) // - done
    bearer.post("project", Project.parameter, "link", use: projectController.addLinkToProject) // - done
    bearer.delete("project", Project.parameter, "link", Link.parameter, use: projectController.deleteLink) // - done
    bearer.put("project", Project.parameter, "link", Link.parameter, use: projectController.updateLink) // - done
    
    //MARK: Labels
    bearer.get("project", "label", use: projectController.getLabels)
    bearer.post("project", Project.parameter, "label", use: projectController.addLabelToProject) // - done
    bearer.delete("project", Project.parameter, "label", use: projectController.removeLabelFromProject) //- done
    bearer.put("project", Project.parameter, "label", use: projectController.updateLabels)
    
    //MARK: Vacancy done
    bearer.get("project", Project.parameter, "vacancy", use: projectController.getProjectVacancy)
    bearer.post("project", Project.parameter, "vacancy", use: projectController.createVacancy)
    bearer.put("project", Project.parameter, "vacancy", Vacancy.parameter, use: projectController.updateVacancy)
    bearer.delete("project", Project.parameter, "vacancy", Vacancy.parameter, use: projectController.deleteVacancy)
    bearer.get("vacancy", use: projectController.getAllVacancy)
    bearer.get("vacancy", "shareType", use: projectController.getShareType)
    
    //MARK: Favorites
    bearer.get("user", "favorites", use: projectController.getFavorites)
    bearer.get("user", "favorites", "user", use: projectController.getFavoriteUsers)
    bearer.get("user", "favorites", "project", use: projectController.getFavoriteProjects)
    
    bearer.post("user", "favorites", "user", User.parameter, use: projectController.setFavoriteUser)
    bearer.post("user", "favorites", "project", Project.parameter,use: projectController.setFavoriteProject)
    
    bearer.delete("user", "favorites", "user", User.parameter, use: projectController.deleteFavoriteUser)
    bearer.delete("user", "favorites", "project", Project.parameter,use: projectController.deleteFavoriteProject)
    
    //MARK: Comments
    bearer.get("project", Project.parameter, "comment", use: projectController.getComments)
    bearer.post("project", Project.parameter, "comment", use: projectController.addComment)
    bearer.delete("project", Project.parameter, "comment", Comment.parameter, use: projectController.deleteComment)
    bearer.get("project", Project.parameter, "comment", "count", use:projectController.getCommentsCount)
    
    //MARK: Likes
    bearer.get("project", Project.parameter, "like", use: projectController.getProjectLikes)
    bearer.get("project", Project.parameter, "like", "count", use: projectController.getProjectLikeCount)
    bearer.post("project", Project.parameter, "like", use: projectController.addLike)
    bearer.delete("project", Project.parameter, "like", use: projectController.deleteLike)
}
