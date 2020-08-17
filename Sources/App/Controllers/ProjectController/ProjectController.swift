import Vapor

/// Simple todo-list controller.
final class ProjectController {
    
    func allProjects(_ req: Request) throws -> Future<[ProjectListResponse]> {
        return Project.query(on: req)
            .filter(\.isPublished, .equal, 1)
            .join(\User.id, to: \Project.ownerId)
            .alsoDecode(User.self)
            .all()
            .flatMap { results in
                return try results.map { res in
                    return try self.getFavoriteProjects(req).flatMap { favorites in
                        return try self.getLabels(for: res.0, on: req).flatMap { labels in
                            return try self.getLikesForProject(res.0, on: req).flatMap { likes in
                                return try self.getCommentsFor(res.0, on: req).map { comments in
                                    let project = res.0
                                    let user = res.1
                                    let isFaorite = try favorites.contains(where: {
                                        try $0.id == project.requireID()
                                    })
                                    var isLike = false
                                    if try req.isAuthenticated(User.self) {
                                        let user = try req.requireAuthenticated(User.self)
                                        isLike = try likes.contains(where: {
                                            try $0.user.id == user.requireID()
                                        })
                                    } else {
                                        isLike = try likes.contains(where: {
                                            try $0.user.id == user.requireID()
                                        })
                                    }
                                    return try ProjectListResponse(res.0, labels: labels, user: res.1, isFavorite: isFaorite, isLike: isLike, likeCount: likes.count, commentCount: comments.count)
                                }
                            }
                        }
                    }
                }.flatten(on: req)
        }
    }
//    return try ProjectListResponse(res.0, labels: labels, user: res.1, isFavorite: favorites.contains {$0.id == res.0.id})
    
    
    func allMyProjectsWithQueryOption(_ req: Request) throws -> Future<[ProjectListResponse]> {
        let user = try req.requireAuthenticated(User.self)
        let query = try req.query.decode(AllMyProjectsQuery.self)
        return try user.projects.query(on: req)
            .filter(\.isPublished, .equal, query.value)
            .all()
            .flatMap { projects in
                return try projects.compactMap { project in
                    return try self.getFavoriteProjects(req).flatMap { favorites in
                        return try self.getLabels(for: project, on: req).flatMap { labels in
                            return try self.getLikesForProject(project, on: req).flatMap { likes in
                                return try self.getCommentsFor(project, on: req).map { comments in
//                                    let project = res.0
//                                    let user = res.1
                                    let isFaorite = try favorites.contains(where: {
                                        try $0.id == project.requireID()
                                    })
                                    var isLike = false
                                    if try req.isAuthenticated(User.self) {
                                        let user = try req.requireAuthenticated(User.self)
                                        isLike = try likes.contains(where: {
                                            try $0.user.id == user.requireID()
                                        })
                                    } else {
                                        isLike = try likes.contains(where: {
                                            try $0.user.id == user.requireID()
                                        })
                                    }
                                    return try ProjectListResponse(project, labels: labels, user: user, isFavorite: isFaorite, isLike: isLike, likeCount: likes.count, commentCount: comments.count)
                                }
                            }
                        }
                    }
//                    return try self.getLabels(for: project, on: req).map {
//                        return try ProjectListResponse(project, labels: $0, user: user)
//                    }
                }.flatten(on: req)
        }
    }
    
    // Проект
    // Метки
    // Автор
    // Лайки
    // Комментарии
    // Вакансии
    // Избранный
    func getDetails(_ req: Request) throws -> Future<DetailProjectResponse> {
        return try req.parameters.next(Project.self)
            .flatMap {
                let project = $0
                let labels = try self.getLabels(for: $0, on: req)
                let comments = try self.getCommentsFor($0, on: req)
                let likes = try self.getLikesForProject($0, on: req)
                let links = try self.getLinksRs(project: $0, on: req)
                let owner = $0.user.get(on: req)
                let vacancy = try $0.vacancy.query(on: req).all()
                if project.isPublished.isPublished {
                    if try req.isAuthenticated(User.self) {
                        let user = try req.requireAuthenticated(User.self)
                        let favoritesProjects = try user.favoritesProjects.query(on: req).all()
                        return try self.buildAuthProjectDetailResponse(project, labels: labels, comments: comments, likes: likes, links: links, owner: owner, vacancy: vacancy, favorites: favoritesProjects)
                    } else {
                        return try self.buildNoAuthProjectDetailResponse(project, labels: labels, comments: comments, likes: likes, links: links, owner: owner, vacancy: vacancy)
                    }
                    
                } else {
                    if try req.isAuthenticated(User.self) {
                        let user = try req.requireAuthenticated(User.self)
                        let favoritesProjects = try user.favoritesProjects.query(on: req).all()
                        return try self.buildAuthProjectDetailResponse(project, labels: labels, comments: comments, likes: likes, links: links, owner: owner, vacancy: vacancy, favorites: favoritesProjects)
                    } else {
                        throw Abort(.notFound)
                    }
                }
        }
    }
    
    func createProject(_ req: Request) throws -> Future<CreateProjectResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(CreateProjectRequest.self).flatMap { request in
            let project = Project(id: nil, name: request.name, userID: try user.requireID(), description: request.description, imagePath: request.imagePath)
            try project.validate()
            return project.save(on: req).map {
                return CreateProjectResponse(id: try $0.requireID(), name: $0.title, description: $0.description, created: Date(), user: UserResponse(id: try user.requireID(), email: user.email), isPublished: $0.isPublished.isPublished)
            }
        }
    }
    
    func updateProject(_ req: Request) throws -> Future<Project> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(UpdateProjectRequest.self).flatMap { updateRequest in
            return try req.parameters.next(Project.self).flatMap { project in
                guard try user.requireID() == project.ownerId else {
                    throw Abort(.forbidden)
                }
                if let title = updateRequest.name {
                    project.title = title
                }
                
                if let description = updateRequest.description {
                    project.description = description
                }
                
                if let imagePath = updateRequest.imagePath {
                    project.imagePath = imagePath
                }
                
                project.updated = Date()
                try project.validate()
                return project.save(on: req)
            }
        }
    }
    
    func publicateProject(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            guard try user.requireID() == project.ownerId else {
                throw Abort(.forbidden, reason: "Только автор проекта может публиковать проект")
            }
            project.isPublished = 1
            return project.save(on: req).transform(to: HTTPStatus.ok)
        }
    }
    
    func checkoutProject(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project in
            guard try user.requireID() == project.ownerId else {
                throw Abort(.forbidden, reason: "Только автор проекта может вернуть проект в черновик")
            }
            project.isPublished = 0
            return project.save(on: req).transform(to: HTTPStatus.ok)
        }
    }
    
    func deleteProject(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Project.self).flatMap { project -> Future<Void> in
            guard try project.ownerId == user.requireID() else {
                throw Abort(.forbidden, reason: "Только автор проекта может удалить проект")
            }
            return project.delete(on: req)
        }.transform(to: .ok)
    }
    
    private func buildNoAuthProjectDetailResponse(_ project: Project,
                                              labels: EventLoopFuture<[LabelEnum]>,
                                              comments: EventLoopFuture<[CommentResponse]>,
                                              likes: EventLoopFuture<[LikeResponse]>,
                                              links: EventLoopFuture<[ProjectController.LinkResponse]>,
                                              owner: EventLoopFuture<User>,
                                              vacancy: EventLoopFuture<[Vacancy]>,
                                              isFavorite: Bool = false) throws -> Future<DetailProjectResponse> {
          return labels.flatMap { labels in
              return comments.flatMap { comments in
                  return likes.flatMap { likes in
                      return links.flatMap { links in
                          return owner.flatMap { owner in
                              return vacancy.map { vacancys in
                                return try DetailProjectResponse(project, links: links, labels: labels, user: owner, isPublished: project.isPublished.isPublished, isFavorite: isFavorite, likes: likes, comments: comments)
                              }
                          }
                      }
                  }
              }
          }
      }
      
      private func buildAuthProjectDetailResponse(_ project: Project,
                                              labels: EventLoopFuture<[LabelEnum]>,
                                              comments: EventLoopFuture<[CommentResponse]>,
                                              likes: EventLoopFuture<[LikeResponse]>,
                                              links: EventLoopFuture<[ProjectController.LinkResponse]>,
                                              owner: EventLoopFuture<User>,
                                              vacancy: EventLoopFuture<[Vacancy]>,
                                              favorites: EventLoopFuture<[Project]>) throws -> Future<DetailProjectResponse> {
          return labels.flatMap { labels in
              return comments.flatMap { comments in
                  return likes.flatMap { likes in
                      return links.flatMap { links in
                          return owner.flatMap { owner in
                              return vacancy.flatMap { vacancys in
                                  return favorites.map { favorites in
                                      return try DetailProjectResponse(project,
                                                                       links: links,
                                                                       labels: labels,
                                                                       user: owner,
                                                                       isPublished: project.isPublished.isPublished,
                                                                       isFavorite: favorites.contains(where: {
                                          try $0.requireID() == project.requireID()
                                      }),
                                    likes: likes,
                                    comments: comments)
                                  }
                              }
                          }
                      }
                  }
              }
          }
      }
 }
