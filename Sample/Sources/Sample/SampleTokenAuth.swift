//
//  SampleTokenAuth.swift
//  KitTokenAuth
//
//  Created by Nicolas Zinovieff on 8/24/18.
//

import Foundation

public class InvalidIDError : Error {
    
}

public class InvalidLoginError : Error {
    
}

public struct User : Codable {
    var login: String
    var firstName: String?
    var lastName: String?
    var hashedPassword : String // stupid implementation
}

public class MemoryTokenAuth : CredentialTokenVerifier {
    public typealias UserStructure = User
    private var memory = [String:(user: User, tokens: [String])]() // stupid token implementation, no expiry
    
   public func user(for id: String, keepAlive: (() -> Void)?) -> User? {
        return memory[id]?.user
    }
    
    public func save(_ data: User, for id: String, keepAlive: (() -> Void)?) {
        if let oldData = memory[id] {
            let newData = (data, oldData.tokens)
            memory[id] = newData
        } else {
            memory[id] = (data, [])
        }
    }
    
    public func verifyToken(_ token: String, keepAlive: (() -> Void)?) -> String? {
        let matches = memory.filter { (k,v) -> Bool in
            return v.tokens.contains(token)
        }
        
        return matches.first?.key
    }
    
    public func registerUser(name: String, password: String, keepAlive: (() -> Void)?) throws -> String {
        let matches = memory.filter { (k,v) -> Bool in
            return v.user.login == name
        }
        
        guard matches.count == 0 else { throw InvalidLoginError() }

        let hash = password.digest(using: .sha512)
        let id = UUID().uuidString
        let tok = UUID().uuidString
        let u = User(login: name, firstName: nil, lastName: nil, hashedPassword: hash)
        memory[id] = (u,[tok])
        
        return tok
    }
    public func verifyUser(name: String, password: String, keepAlive: (() -> Void)?) -> String? {
        let hash = password.digest(using: .sha512)
        let matches = memory.filter { (k,v) -> Bool in
            return (v.user.login == name && v.user.hashedPassword == hash)
        }
        
        return matches.first?.key
    }
    
    public func generateToken(userID: String, keepAlive: (() -> Void)?) throws -> String {
        guard let _ = memory[userID] else { throw InvalidIDError() }
        
        let tok = UUID().uuidString
        memory[userID]?.tokens.append(tok)
        
        return tok
    }
    
    public func expireDate(for: String, keepAlive: (() -> Void)?) -> Date? {
        return Date.distantFuture
    }
    
    public func shouldRedirect() -> Bool {
        return true
    }
    
    public func failureRedirectURL(for route: String) -> String? {
        if let back = route.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            return "/login?back=\(back)"
        } else {
            return "/login"
        }
    }
    
    // App Key
    public func needsAppKey() -> Bool {
        return false
    }
    
    public func checkAppKey(_ key: String) -> Bool {
        return true
    }
    

}
