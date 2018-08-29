import Foundation
import KituraSession
import Credentials
import Kitura

public protocol CredentialTokenVerifier  {
    associatedtype UserStructure where UserStructure : Codable
    // keepAlive is a function that notifies us that the process is still going
    
    func user(for id: String, keepAlive: (()->Void)?) -> UserStructure? /// returns the user data for that user ID
    func save(_ data: UserStructure, for id: String, keepAlive: (()->Void)?) /// stores the user data for that user ID
    func verifyToken(_ token: String, keepAlive: (()->Void)?) -> String? /// Returns a unique ID for the user
    func registerUser(name: String, password: String, keepAlive: (()->Void)?) throws -> String /// Returns a unique ID for the user
    func verifyUser(name: String, password: String, keepAlive: (()->Void)?) -> String? /// Returns a unique ID for the user
    func generateToken(userID: String, keepAlive: (()->Void)?) throws -> String /// Generates a token, throws if the user id is invalid
    func expireDate(for id: String, keepAlive: (()->Void)?) -> Date? /// Expire date for the token
    
    // redirection for web forms etc or not
    func shouldRedirect() -> Bool
    func failureRedirectURL(for route: String) -> String?
    
    // app key if needed
    func needsAppKey() -> Bool
    func checkAppKey(_ key: String) -> Bool
}

public class CredendialsToken<T>: CredentialsPluginProtocol where T : CredentialTokenVerifier {
    public let name: String = "XToken"
    public var usersCache: NSCache<NSString, BaseCacheElement>?
    public var redirecting: Bool { return self.tokenVerifier.shouldRedirect() }
    
    // variables to look for in the headers / post data
    public var userNameField : String
    public var passwordField : String
    public var tokenHeaderName : String
    public var storeDataInSession : Bool
    public var sessionKey: String
    public var appKey: String

    private var tokenVerifier : T
    
    public init(_ verif: T,
                nameField: String = "username",
                passField : String = "password",
                tokenHeader : String = "X-Token",
                appHeader : String = "A-Token",
                storeInSession: Bool = false,
                sessionKey: String = "userData") {
        self.tokenVerifier = verif
        self.userNameField = nameField
        self.passwordField = passField
        self.tokenHeaderName = tokenHeader
        self.storeDataInSession = storeInSession
        self.sessionKey = sessionKey
        self.appKey = appHeader
    }

    public func authenticate(
        request: RouterRequest,
        response: RouterResponse,
        options: [String : Any],
        onSuccess: @escaping (UserProfile) -> Void,
        onFailure: @escaping (HTTPStatusCode?, [String : String]?) -> Void,
        onPass: @escaping (HTTPStatusCode?, [String : String]?) -> Void,
        inProgress: @escaping () -> Void) {
        
        if let u = request.userProfile {
            onSuccess(u) // already done?
            return
        }
        
        let fail = {
            if self.tokenVerifier.shouldRedirect() { onPass(nil,nil) }
            else { onFailure(HTTPStatusCode.unauthorized, nil) }
        }
        
        if self.tokenVerifier.needsAppKey() {
            guard let key = request.headers[self.appKey] else { fail() ; return }
            if !self.tokenVerifier.checkAppKey(key) { fail() ; return }
        }
        
        if let token = request.headers[self.tokenHeaderName],
            let userID = self.tokenVerifier.verifyToken(token, keepAlive: inProgress) {
            if self.storeDataInSession {
                if let user = self.tokenVerifier.user(for: userID, keepAlive: inProgress){
                    self.updateSession(request.session, with: user)
                }
            }
            
            onSuccess(UserProfile(id: userID, displayName: userID, provider: self.name))
        } else if let r = request.body?.asURLEncoded,
            let user = r[self.userNameField],
            let pass = r[self.passwordField],
            let userID = self.tokenVerifier.verifyUser(name: user, password: pass, keepAlive: inProgress) {
            if self.storeDataInSession {
                if let user = self.tokenVerifier.user(for: userID, keepAlive: inProgress) {
                    self.updateSession(request.session, with: user)
                }
            }
            onSuccess(UserProfile(id: userID, displayName: userID, provider: self.name))
        } else {
            if self.self.tokenVerifier.shouldRedirect() {
                if let url = self.tokenVerifier.failureRedirectURL(for: request.matchedPath) {
                    try? response.redirect(url).end()
                    onPass(.temporaryRedirect, nil)
                } else {
                    fail()
                }
            } else {
                fail()
            }
        }
    }

    // For session storing after (for example) register actions etc
    public func loginSession( request: RouterRequest, response: RouterResponse, userID: String) throws {
        if let user = self.tokenVerifier.user(for: userID, keepAlive: nil) {
            if self.storeDataInSession {
                self.updateSession(request.session, with: user)
            }
            
        }
    }
    
    // For extracting the UserStructure from the session
    public func userFromSession(_ s:SessionState) -> T.UserStructure? {
        if let str = s[self.sessionKey] as? String, let d = str.data(using: .utf8) {
            return try? JSONDecoder().decode(T.UserStructure.self, from: d)
        }
        
        return nil
    }
    
    // In case something changes in the structure and it's too heavy to reload it from the db/...
    public func updateSession(_ session:SessionState?, with: T.UserStructure) {
        if self.storeDataInSession {
            if let ds = try? JSONEncoder().encode(with), let s = String(data: ds, encoding: .utf8) {
                session?[self.sessionKey] = s
            }
        }
    }
}