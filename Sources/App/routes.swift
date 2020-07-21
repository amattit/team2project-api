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
    bearer.get("api", "v1", "user", User.parameter, use: userController.getUser)
    
    //MARK: Contacts
    /// get      /user/contact - все контакты + добавить в ответ user  -> getUserContacts
    bearer.get("user", "contact", use: userController.getUserContacts)
    /// get      /user/contactType - справочник видов контактов для предзаполнения -> userController.getContactsEnum
    bearer.get("user", "contactType", use: userController.getContactsEnum)
    /// post     /user/contact - создание контакта -> userController.createContact
    bearer.post("user", "contact", use: userController.createContact)
    /// put      /user/contact/{id} - изменение контакта -> userController.updateContact
    bearer.put("user", "contact", Contact.parameter, use: userController.updateContact)
    /// delete   /user/contact/{id} - удаление контакта -> userController.deleteContact
    bearer.delete("user", "contact", Contact.parameter, use: userController.deleteContact)
    // MARK: projects
    
    router.get("api", "v1", "project", use: projectController.allProjects)
    bearer.get("project", "my", use: projectController.allMyPublickProjects)
    bearer.post("project", use: projectController.createProject)
    bearer.delete("project", Project.parameter, use: projectController.deleteProject)
    bearer.put("project", Project.parameter, use: projectController.updateProject)
    bearer.get("project", Project.parameter, use: projectController.projectDetail)
    bearer.put("project", Project.parameter, "public", use: projectController.publicateProject)
    bearer.put("project", Project.parameter, "checkout", use: projectController.checkoutProject)
    bearer.get("project","checkout", use: projectController.checkoutProjects)
    
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
