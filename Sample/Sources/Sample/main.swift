import Foundation
import Kitura
import Credentials
import LoggerAPI
import Dispatch
import KituraSession
import HeliumLogger
import KituraStencil

import CredentialsToken

HeliumLogger.use()

let router = Router()
let session = Session(secret: "ThatSQuiteTheSecretBoyo")
router.all(middleware: [BodyParser(), session, StaticFileServer()])
router.add(templateEngine: StencilTemplateEngine())

let memoryTokens = MemoryTokenAuth()

let credentials = Credentials()
let memTokenCred = CredendialsToken(memoryTokens)
memTokenCred.storeDataInSession = true

credentials.register(plugin: memTokenCred)

router.get("/login") { request, response, next in
    if let s = request.session, let u = memTokenCred.userFromSession(s) {
        try response.render("Logout.stencil", context: ["userLogin" : u.login])
    } else {
        var c = [String:Any]()
        if let back = request.queryParameters["back"]  {
            c["backURL"] = back
        }
        
        try response.render("Login.stencil", context: c)
    }
    
    next()
}

router.post("/login", handler:[credentials.authenticate(credentialsType: memTokenCred.name, successRedirect: nil, failureRedirect: "/login")])
router.post("/login") { request, response, next in
    if let _ = request.userProfile {
        if let back = request.body?.asURLEncoded?["back"] {
            try response.redirect(back)
        } else {
            try response.redirect("/hello")
        }
    }
}

router.post("/logout") { request, response, next in
    credentials.logOut(request: request)
    request.session?.remove(key: memTokenCred.sessionKey) // could be the same, could be something else
    try response.redirect("/login")
    next()
}

router.get("/register") { request, response, next in
    if let s = request.session, let u = memTokenCred.userFromSession(s) {
        try response.render("Logout.stencil", context: ["userLogin" : u.login])
    } else {
        try response.render("Register.stencil", context: [:])
    }
    
    next()
}

router.post("/register") {request, response, next in
    let fail = { try? response.status(.internalServerError).end() ; next() }
    do {
        guard let formData = request.body?.asURLEncoded else { fail() ; return }
        guard let name = formData["username"] else { fail() ; return }
        guard let pass = formData["password"] else { fail() ; return }
        let token = try memoryTokens.registerUser(name: name, password: pass, keepAlive: nil)
        response.send(
        """
            <!DOCTYPE html>
            <html>
            <head>
                <title></title>
            </head>
            <body>
            \(token)
            <a href="/hello">Hello</a>
            </body>
            </html>
        """
        )
    } catch {
        try? response.status(.badRequest).end()
    }
    
    next()
}

router.all("/profile", handler: [credentials.authenticate(credentialsType: memTokenCred.name, successRedirect: nil, failureRedirect: "/login")])
router.get("/profile") { request, response, next in
    if let s = request.session, let u = memTokenCred.userFromSession(s) {
        try response.render("Profile.stencil", context: ["username" : u.login, "firstname": u.firstName ?? "", "lastname":u.lastName ?? ""])
    }
    next()
}

router.post("/profile") { request, response, next in
    if let uid = request.userProfile?.id, let s = request.session, let u = memTokenCred.userFromSession(s),
    let params = request.body?.asURLEncoded,
        let login = params["username"],
        let fn = params["firstname"],
        let ln = params["lastname"] {
        let nu = User(login: login, firstName: fn, lastName: ln, hashedPassword: u.hashedPassword)
        memoryTokens.save(nu, for: uid, keepAlive: nil)
        memTokenCred.updateSession(s, with: nu)
        try response.render("Profile.stencil", context: ["username" : nu.login, "firstname": nu.firstName ?? "", "lastname":nu.lastName ?? ""])
    }
    next()
}

router.all("/hello.*", handler:[credentials.authenticate(credentialsType: memTokenCred.name, successRedirect: nil, failureRedirect: "/login")])
router.get("/helloToken") { request, response, next in
    if let s = request.session {
        if let u = memTokenCred.userFromSession(s) {
            response.send(u)
        } else {
            response.send("no user in session")
        }
    } else {
        response.send("no session")
    }
    next()
}

router.get("/hello") { request, response, next in
    if let s = request.session {
        if let u = memTokenCred.userFromSession(s) {
            try response.render("Hello.stencil", with: u)
        } else {
            response.send("no user in session")
        }
    } else {
        response.send("no session")
    }
    next()
}

router.all("/api/.*", handler:[credentials.authenticate(credentialsType: memTokenCred.name, successRedirect: nil, failureRedirect: nil)])
router.post("/api/login") { request, response, next in
    let fail = { try response.status(.unauthorized).end() }
    guard let userProfile = request.userProfile else { try fail() ; return }
    guard let userData = memoryTokens.user(for: userProfile.id, keepAlive: nil) else { try fail() ; return }
    
    var data = [
        "username" : userData.login,
        "token" : try memoryTokens.generateToken(userID: userProfile.id, keepAlive: nil)
    ]
    
    if let fn = userData.firstName { data["firstName"] = fn }
    if let ln = userData.lastName { data["lastName"] = ln }

    response.send(data)
    next()
}

router.get("/api/hello") { request, response, next in
    let fail = { try response.status(.unauthorized).end() }

    guard let userProfile = request.userProfile else { try fail() ; return }
    guard let userData = memoryTokens.user(for: userProfile.id, keepAlive: nil) else { try fail() ; return }

    var u = ( (userData.firstName != nil) ? userData.firstName! : "" ) + ( (userData.lastName != nil) ? userData.lastName! : "" )
    if u.lengthOfBytes(using: .utf8) == 0 { u = userData.login }
    
    response.send("Hello \(u)")
    next()
}

router.get("/api/hellopassthrough") { request, response, next in
    if let userProfile = request.userProfile {
        if userProfile.isAuthenticated {
            guard let userData = memoryTokens.user(for: userProfile.id, keepAlive: nil) else {
                response.send("hello problematic user!")
                next()
                return
            }

            var u = ((userData.firstName != nil) ? userData.firstName! : "") + ((userData.lastName != nil) ? userData.lastName! : "")
            if u.lengthOfBytes(using: .utf8) == 0 {
                u = userData.login
            }

            response.send("Hello \(u)!")
        } else {
            let u = userProfile.displayName
            response.send("Hello \(u)!")
        }
    } else { // we're not authenticated AND have no session
        response.send("Hello new user!")
    }

    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
