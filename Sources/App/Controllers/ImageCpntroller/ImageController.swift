//
//  File.swift
//  
//
//  Created by 16997598 on 02.08.2020.
//

import Vapor

class ImageController {
    
//    func imageUpload(_ req: Request) throws -> Future<ImageResponse> {
//        return try req.content.decode(ImageRequest.self).map { imageRequest in
//            
//        }
//    }
//    
//    func save(with data: Data) throws {
//        
//    }
}



struct ImageRequest: Content {
    let filename: String
    let image: Data
}

struct ImageResponse: Content {
    let imagePath: String
}
