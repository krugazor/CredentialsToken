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

### Setup the routes

Setup the routes that will be authenticated using this plugin in one of two ways:

`router.all("/hello", middleware: [creds])`
`router.all("/profile", handler: [CredentialsToken.authenticate(credentialsType: memTokenCred.name, successRedirect: nil, failureRedirect: "/login")])`

## Usage scenarios

### API/Mostly Token

You will need a login (and possibly register) routes that are handling the POST forms to generate or get the access tokens.
Then, all the protected routes can be used with the Credentials middleware, and will be matched to the token passed in the relevant header.

### Front/Mostly Session

You cannot really use the middleware mechanism for this. You will need to protect the routes using the handler system instead, because of the session management and the potential redirects to the login page.

### Mixed

Of course, you can use a mix of the two, using the wildcard system.