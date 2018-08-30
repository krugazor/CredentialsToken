# CredentialsToken

Kitura plugin for the [Credentials](https://github.com/IBM-Swift/Kitura-Credentials) system that enables connection management through user/password of token header
Sample code can be found in the Sample directory

## Generic `CredentialsToken` type

This is the wrapper/plugin for the token system. It handles the authentication middleware mechanisms and is fairly transparent and configurable:

- userNameField/passwordField (`String`) : the names of the form fields to look for in case of a username/password authentication page
- tokenHeaderName(`String`) : the name of the header in which the token is passed if there is one
- storeDataInSession/sessionKey(`Bool`/`String`) : in case the developer wants to store the user data structure in the session dictionary (there are other ways to get it, but it might help for cache purposes)
- appKey(`String`) (optional) : sometimes we want to lock out or separate apps that access our APIs, so it's included here 

## `CredentialTokenVerifier` type specification

This is the heart of the system : depending on how the tokens and user/pass combinations are stored, the developer has to provide a compliant type to allow the plugin to function properly. In the sample, we use a simple (and stupid) in-memory system, but that is where one would use files/databases/...

## Basic usage 

### Configure the plugin

```
let memoryTokens = MemoryTokenAuth()
let memTokenCred = CredendialsToken(memoryTokens)

let credentials = Credentials()
credentials.register(plugin: memTokenCred)
```

(From the sample code, just a stupid in-memory user management class that will *not* survive restarts)

### Setup the routes

Setup the routes that will be authenticated using this plugin in one of two ways:

`router.all("/hello.*", middleware: [credentials])`

Sets these routes to **have** to have a token or user/password at every request (useful for token authed APIs)

`router.all("/profile", handler: [credentials.authenticate(credentialsType: memTokenCred.name, successRedirect: nil, failureRedirect: "/login")])`

Sets these routes to have to either have the authentication in the headers/form-data, or the session, and to store in the session the credentials when needed.

## Usage scenarios

### API/Mostly Token

You will need a login (and possibly register) routes that are handling the POST forms to generate or get the access tokens.
Then, all the protected routes can be used with the Credentials middleware, and will be matched to the token passed in the relevant header.

### Front/Mostly Session

You cannot really use the middleware mechanism for this. You will need to protect the routes using the handler system instead, because of the session management and the potential redirects to the login page.

### Mixed

Of course, you can use a mix of the two, using the wildcard system. The only issue is, you *cannot* use the middleware mechanism with a redirecting plugin. If you mix the two, you will have to decide whether or not the plugin might redirect, and if so,

- if the plugin redirects, you *need* to use the `handler` method
- if the plugin does not redirect, you can use the `middleware` method

## Caveats

The way the Credential system works, your program might have to talk to the `CredentialTokenVerifier` instance separately from the top-level credentials system, like if you want to have a register/login mechanism that saves your data for instance.

It might make the code kind of wonky sometimes, which is why it's a protocol: You can implement your database connection class that will handle all the load/save actions, and it can conform to the protocol to coalesce the credentials plugin and the singleton you would be using anyways.
