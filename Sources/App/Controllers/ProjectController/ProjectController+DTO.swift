//
//  File.swift
//  
//
//  Created by 16997598 on 22.07.2020.
//

import Vapor

// MARK: Content
/// Represents data required to create a new todo.
extension ProjectController {
    struct CreateProjectRequest: Content {
        /// Todo title.
        let name: String
        let description: String
        let imagePath: String?
    }
    
    struct UpdateProjectRequest: Content {
        let name: String?
        let description: String?
        let imagePath: String?
    }
    
    struct ProjectListResponse: Content {
        let id: Int
        let name: String
        let description: String
        let useremail: String
        let created: Date
        let user: UserResponse
        var labels: [LabelEnum]?
        let imagePath: String?
        let isPublished: Bool
        var isFavorite: Bool = false
        var isLike: Bool = false
        var likeCount: Int?
        var commentCount: Int?
        
        init(_ project: Project, labels: [LabelEnum], user: User) throws {
            self.id = try project.requireID()
            self.name = project.title
            self.description = project.description
            self.useremail = ""
            self.created = project.created
            self.user = try UserResponse(with: user)
            self.labels = labels
            self.imagePath = project.imagePath
            self.isPublished = project.isPublished.isPublished
            self.isFavorite = false
        }
        
        init(_ project: Project, labels: [LabelEnum], user: User, isFavorite: Bool) throws {
            self.id = try project.requireID()
            self.name = project.title
            self.description = project.description
            self.useremail = ""
            self.created = project.created
            self.user = try UserResponse(with: user)
            self.labels = labels
            self.imagePath = project.imagePath
            self.isPublished = project.isPublished.isPublished
            self.isFavorite = isFavorite
        }
        
        init(_ project: Project, labels: [LabelEnum], user: User, isFavorite: Bool, isLike: Bool = false, likeCount: Int = 0, commentCount: Int = 0) throws {
            self.id = try project.requireID()
            self.name = project.title
            self.description = project.description
            self.useremail = ""
            self.created = project.created
            self.user = try UserResponse(with: user)
            self.labels = labels
            self.imagePath = project.imagePath
            self.isPublished = project.isPublished.isPublished
            self.isFavorite = isFavorite
            self.isLike = isLike
            self.likeCount = likeCount
            self.commentCount = commentCount
        }
        
        init(id: Int, name: String, description: String, useremail: String, created: Date, user: UserResponse, labels: [LabelEnum] = [], imagePath: String?, isPublished: Bool, isFavorite: Bool = false) {
            self.id = id
            self.name = name
            self.description = description
            self.useremail = ""
            self.created = created
            self.user = user
            self.labels = labels
            self.imagePath = imagePath
            self.isPublished = isPublished
            self.isFavorite = isFavorite
        }
        
        mutating func addLabels(_ labels: [LabelEnum]) {
            self.labels = labels
        }
        
        mutating func setCommentsCount(_ commentCount: Int) {
            self.commentCount = commentCount
        }
        
        mutating func setIsFavorite(_ isFavorite: Bool) {
            self.isFavorite = isFavorite
        }
        
        mutating func setIsLike(_ isLike: Bool) {
            self.isLike = isLike
        }
        
        mutating func setLikeCount(_ likeCount: Int) {
            self.likeCount = likeCount
        }
    }
    
    struct VacancyProjectListResponse: Content {
        let id: Int
        let name: String
        let description: String
        let useremail: String
        let created: Date
        let user: UserResponse?
        let labels: [LabelEnum]?
        let imagePath: String?
    }
    
    struct CreateProjectResponse: Content {
        let id: Int
        let name: String
        let description: String
        let created: Date
        let user: UserResponse
        let isPublished: Bool
    }
    
    struct DetailProjectResponse: Content {
        let id: Int
        let name: String
        let description: String
        let created: Date
        let links: [LinkResponse]?
        let labels: [LabelEnum]?
        let user: UserResponse
        let imagePath: String?
        let vacancy: [VacancyResponse]?
        let isPublished: Bool
        let isFavorite: Bool
        let likes: [LikeResponse]?
        let comments: [CommentResponse]?
        
        init(_ project: Project,
             links: [LinkResponse],
             labels: [LabelEnum],
             user: User,
             vacancy: [Vacancy]? = nil,
             isPublished: Bool,
             isFavorite: Bool = false,
             likes: [LikeResponse]? = nil,
             comments: [CommentResponse]? = nil) throws {
            self.id = try project.requireID()
            self.name = project.title
            self.description = project.description
            self.created = project.created
            self.user = try UserResponse(with: user)
            self.labels = labels
            self.links = links
            self.imagePath = project.imagePath
            self.vacancy = try vacancy?.compactMap { try VacancyResponse(with: $0, contact: user) }
            self.isPublished = isPublished
            self.isFavorite = isFavorite
            self.likes = likes
            self.comments = comments
        }
    }
    
    
    struct AddLinkRequest: Content {
        let title: String
        let link: String
    }
    
    struct UpdateLinkRequest: Content {
        let title: String
        let link: String
    }
    
    struct LinkResponse: Content {
        let id: Int
        let title: String
        let link: String
    }
    
    struct AddLabelToProject: Content {
        let labelId: Int
    }
    
    struct AllMyProjectsQuery: Content {
        let isPublished: Bool
    }
}

extension ProjectController.AllMyProjectsQuery {
    var value: Int {
        switch isPublished {
        case false:
            return 0
        default:
            return 1
        }
    }
}
