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
        let user: UserResponse?
        let labels: [LabelEnum]?
    }
    
    struct CreateProjectResponse: Content {
        let id: Int
        let name: String
        let description: String
        let created: Date
        let user: UserResponse?
    }
    
    struct DetailProjectResponse: Content {
        let id: Int
        let name: String
        let description: String
        let created: Date
        let links: [LinkResponse]?
        let labels: [LabelEnum]?
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