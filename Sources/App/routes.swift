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
    /// get      /user/contact - все контакты + добавить в ответ user  -> getUserContacts
    bearer.get("user", "contact", use: userController.getUserContacts)
    /// get      /user/contactType - справочник видов контактов для предзаполнения -> userController.getContactsEnum
    bearer.get("user", "contactType", use: userController.getContactsEnum)
    /// post     /user/contact - создание контакта -> userController.createContact
    bearer.post("user", "contact", use: userController.createContact)
    /// put      /user/contact/{id} - изменение контакта -> userController.updateContact
    bearer.put("user", "contact", Contact.parameter, use: userController.updateContact) // поправить DTO
    /// delete   /user/contact/{id} - удаление контакта -> userController.deleteContact
    bearer.delete("user", "contact", Contact.parameter, use: userController.deleteContact)
    
    // MARK: projects
    router.get("api", "v1", "project", use: projectController.allProjects) // - done
    bearer.get("project", "my", use: projectController.allMyPublickProjects) // - done
    bearer.post("project", use: projectController.createProject) // - done
    bearer.delete("project", Project.parameter, use: projectController.deleteProject) // - done
    bearer.put("project", Project.parameter, use: projectController.updateProject) // - done
    bearer.get("project", Project.parameter, use: projectController.projectDetail) // - done
    bearer.put("project", Project.parameter, "public", use: projectController.publicateProject) // - done
    bearer.put("project", Project.parameter, "checkout", use: projectController.checkoutProject) // - done
//    bearer.get("project","checkout", use: projectController.checkoutProjects)
    
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
    /// get         project/:id/vacancy - Список всех вакансий для проекта
    bearer.get("project", Project.parameter, "vacancy", use: projectController.getProjectVacancy)
    /// post       project/:id/vacancy - Создание вакансии
    bearer.post("project", Project.parameter, "vacancy", use: projectController.createVacancy)
    /// put         project/:id/vacancy/:id - Изменение вакансии
    bearer.put("project", Project.parameter, "vacancy", Vacancy.parameter, use: projectController.updateVacancy)
    /// delete    project/:id/vacancy/:id
    bearer.delete("project", Project.parameter, "vacancy", Vacancy.parameter, use: projectController.deleteVacancy)
    /// get vacancy -  все незанятые вакансии
    bearer.get("vacancy", use: projectController.getAllVacancy)
    
    bearer.get("vacancy", "shareType", use: projectController.getShareType)
}
