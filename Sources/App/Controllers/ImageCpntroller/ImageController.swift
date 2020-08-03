//
//  File.swift
//  
//
//  Created by 16997598 on 02.08.2020.
//

import Vapor

class ImageController {
    
    let imageFolder: String = "images"
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
            let url = URL(fileURLWithPath: workPath).appendingPathComponent("Public/images")
            let name = try "\(user.requireID())-\(UUID().uuidString).jpg"
            let parh = url.appendingPathComponent(name)
            let path = workPath + self.imageFolder + name
            FileManager().createFile(atPath: parh.path, contents: imageData.image, attributes: nil)
//            FileManager().createFile(atPath: path, contents: imageData.image, attributes: nil)
            
            //        let redirect = try req.redirect(to: "/users/\(user.requireID())")
            return ImageResponse(imagePath: parh.path)
        }
    }
    
    func imgurUploadFile(_ req: Request) throws -> Future<ImageResponse> {
//        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(ImageRequest.self).flatMap { imageRequest in
            let parameters = [
            [
              "key": "image",
              "value": "\(imageRequest.image.base64EncodedString())",
              "type": "text"
            ]] as [[String : Any]]
            let boundary = "Boundary-\(UUID().uuidString)"
            var body = ""
//            var error: Error? = nil
            for param in parameters {
              if param["disabled"] == nil {
                let paramName = param["key"]!
                body += "--\(boundary)\r\n"
                body += "Content-Disposition:form-data; name=\"\(paramName)\""
                let paramType = param["type"] as! String
                if paramType == "text" {
                  let paramValue = param["value"] as! String
                  body += "\r\n\r\n\(paramValue)\r\n"
                } else {
                  let paramSrc = param["src"] as! String
                  let fileData = try NSData(contentsOfFile:paramSrc, options:[]) as Data
                  let fileContent = String(data: fileData, encoding: .utf8)!
                  body += "; filename=\"\(paramSrc)\"\r\n"
                    + "Content-Type: \"content-type header\"\r\n\r\n\(fileContent)\r\n"
                }
              }
            }
            body += "--\(boundary)--\r\n";
//            let dataString = String(data: req.http.body.data!, encoding: .utf8)?.data(using: .utf8)
//            guard let data = dataString else { throw Abort(.badRequest)}
//            let httpData = HTTPBody(data: data)
            var headers = req.http.headers
            headers.remove(name: "Authorization")
            headers.add(name: "Authorization", value: "Client-ID 91e8d85c668e81d")
            headers.remove(name: "Content-Type")
            headers.add(name: "Content-Type", value: "multipart/form-data; boundary=\(boundary)")
            let httpData = HTTPBody(data: body.data(using: .utf8)!)
            let client = HTTPClient.connect(hostname: "https://api.imgur.com", on: req)
            let request = HTTPRequest(method: .POST, url: "/3/upload", headers: headers, body: httpData)
            print(request)
            let response = client.flatMap { client in
                return client.send(request).map { response in
                    return response
                }
            }
            
            return response.flatMap(to: ImageResponse.self) { httpResponse in
                let response = Response(http: httpResponse, using: req)
                return try response.content.decode(ImgurResponse.self).map {
                    ImageResponse(imagePath: $0.data.link)
                }
            }
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

struct ImgurResponse: Content {
    let data: Data
}

extension ImgurResponse {
    struct Data: Content {
        let link: String
    }
}
