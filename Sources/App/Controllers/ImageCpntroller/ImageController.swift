//
//  File.swift
//  
//
//  Created by 16997598 on 02.08.2020.
//

import Vapor

class ImageController {
    
    let imageFolder: String = "Public/images/"
//    func imageUpload(_ req: Request) throws -> Future<ImageResponse> {
//        return try req.content.decode(ImageRequest.self).map { imageRequest in
//            
//        }
//    }
//    
//    func save(with data: Data) throws {
//        
//    }
    
    func addProfilePicturePostHandler(_ req: Request) throws -> Future<ImageResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(ImageRequest.self).map { imageData in
            let workPath = try req.make(DirectoryConfig.self).workDir
            let name = try "\(user.requireID())-\(UUID().uuidString).jpg"
            let path = workPath + self.imageFolder + name
            FileManager().createFile(atPath: path, contents: imageData.image, attributes: nil)
            
            //        let redirect = try req.redirect(to: "/users/\(user.requireID())")
            return ImageResponse(imagePath: path)
        }
    }
}



struct ImageRequest: Content {
    let filename: String
    let image: Data
}

struct ImageResponse: Content {
    let imagePath: String
}
