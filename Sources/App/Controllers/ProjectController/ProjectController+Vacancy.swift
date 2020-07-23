//
//  File.swift
//  
//
//  Created by 16997598 on 23.07.2020.
//

import Vapor

extension ProjectController {
    func getAllVacancy(_ req: Request) throws -> Future<[VacancyResponse]> {
        return Vacancy.query(on: req).filter(\.isVacant, .equal, true).all().flatMap { vacancys in
            let vac = vacancys.map { vacancy in
                return vacancy.owner.get(on: req).map { user in
                    return vacancy.project.get(on: req).map { project in
                        return try VacancyResponse(with: vacancy, contact: user, project: project)
                    }
                }
            }
            return vac.flatten(on: req)
                .flatMap{ $0.flatten(on: req) }
        }
    }
    
    func getProjectVacancy(_ req: Request) throws -> Future<[VacancyResponse]> {
        return try req.parameters.next(Project.self).flatMap { project in
            return try project.vacancy.query(on: req).filter(\.isVacant, .equal, true).all().flatMap { vacancys in
                return vacancys.map { vacancy in
                    return project.user.get(on: req).map { user in
                        return try VacancyResponse(with: vacancy, contact: user)
                    }
                }.flatten(on: req)
            }
        }
    }
    
    func createVacancy(_ req: Request) throws -> Future<VacancyResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            return try req.content.decode(CreateVacancyRequest.self).flatMap { request in
                return Vacancy.ShareType.query(on: req).all().flatMap { shareTypes in
                    if shareTypes.contains(where: { $0.title == request.shareType }) {
                        return try Vacancy(with: request, for: try project.requireID(), ownerId: try user.requireID()).save(on: req).map {
                            return try VacancyResponse(with: $0, contact: user)
                        }
                    } else {
                        throw Abort(.notFound, reason: "Не найден передаваемый тип Share")
                    }
                }
            }
        }
    }
    
    func deleteVacancy(_ req: Request) throws -> Future<HTTPStatus> {
        let _ = try req.parameters.next(Project.self)
        return try req.parameters.next(Vacancy.self).flatMap { vacancy in
            return vacancy.delete(on: req).transform(to: .ok)
        }
    }
    
    func updateVacancy(_ req: Request) throws -> Future<VacancyResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            return try req.parameters.next(Vacancy.self).flatMap { vacancy in
                guard try user.requireID() == vacancy.ownerId else { throw Abort(.forbidden, reason: "Только пользователь создавший вакансию может изменять запись")}
                return Vacancy.ShareType.query(on: req).all().flatMap { shareTypes in
                    return try req.content.decode(UpdateVacancyRequest.self).flatMap { request in
                        if shareTypes.contains(where: { $0.title == request.shareType }) {
                            if let title = request.title {
                                vacancy.title = title
                            }
                            
                            if let shareType = request.shareType {
                                vacancy.shareType = shareType
                            }
                            
                            if let shareValue = request.value {
                                vacancy.shareValue = shareValue
                            }
                            
                            if let aboutVacancy = request.aboutVacancy {
                                vacancy.aboutVacancy = aboutVacancy
                            }
                            
                            if let aboutFeatures = request.aboutFeatures {
                                vacancy.aboutFeatures = aboutFeatures
                            }
                            
                            if let isVacant = request.isVacant {
                                vacancy.isVacant = isVacant
                            }
                            
                            return vacancy.update(on: req).map { updated in
                                return try VacancyResponse(with: updated, contact: user)
                            }
                        } else {
                            throw Abort(.notFound, reason: "Не найден передаваемый тип Share")
                        }

                    }
                }
            }
        }
    }
    
    func getShareType(_ req: Request) throws -> Future<[Vacancy.ShareType]> {
        return try Vacancy.ShareType.query(on: req).all()
    }
    
}

//MARK: DTO

struct CreateVacancyRequest: Content {
    let title: String
    let shareType: String
    let value: Int?
    let aboutVacancy: String?
    let aboutFeatures: String?
    let isVacant: Bool?
}

struct UpdateVacancyRequest: Content {
    let title: String?
    let shareType: String?
    let value: Int?
    let aboutVacancy: String?
    let aboutFeatures: String?
    let isVacant: Bool?
}

struct VacancyResponse: Content {
    let id: Int
    let title: String
    let shareType: String
    let value: Int?
    let aboutVacancy: String?
    let aboutFeatures: String?
    let contact: UserResponse
    let project: ProjectController.ProjectListResponse?
    
    init(with vacancy: Vacancy, contact: User, project: Project? = nil) throws {
        self.id = try vacancy.requireID()
        self.title = vacancy.title
        self.shareType = vacancy.shareType
        self.value = vacancy.shareValue
        self.aboutVacancy = vacancy.aboutVacancy
        self.aboutFeatures = vacancy.aboutFeatures
        self.contact = try UserResponse(with: contact)
        if  let project = project {
            self.project = ProjectController.ProjectListResponse(id: try project.requireID(), name: project.title, description: project.description, useremail: "", created: project.created, user: nil, labels: nil, imagePath: project.imagePath)
        } else {
            self.project = nil
        }
        
    }
}

extension Vacancy {
    convenience init(with dto: CreateVacancyRequest, for projectId: Int, ownerId: Int) throws {
        self.init(title: dto.title,
                  shareType: dto.shareType,
                  shareValue: dto.value,
                  projectId: projectId,
                  ownerId: ownerId,
                  isVacant: dto.isVacant ?? true,
                  aboutVacancy: dto.aboutVacancy,
                  aboutFeatures: dto.aboutFeatures)
    }
}
