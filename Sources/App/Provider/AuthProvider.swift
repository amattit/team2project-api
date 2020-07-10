//
//  File.swift
//  
//
//  Created by 16997598 on 10.07.2020.
//

//import Authentication
//import AuthenticationServices
//
///// Adds authentication services to a container
//public final class MD5AuthenticationProvider: Provider {
//    /// Create a new `AuthenticationProvider`.
//    public init() { }
//
//    /// See `Provider`.
//    public func register(_ services: inout Services) throws {
//        services.register(PasswordVerifier.self) { container in
//            return MD5
//        }
//        services.register(PasswordVerifier.self) { container in
//            return PlaintextVerifier()
//        }
//        services.register { container in
//            return AuthenticationCache()
//        }
//    }
//
//    /// See Provider.boot
//    public func didBoot(_ worker: Container) throws -> Future<Void> {
//        return .done(on: worker)
//    }
//}
//
///// A struct password verifier around bcrypt
////extension BCryptDigest: PasswordVerifier { }
////extension MD5: PasswordVerifier { }
//extension Digest: Service {}
