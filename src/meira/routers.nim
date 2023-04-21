import ./common, std/strutils, std/tables, webby/httpheaders
import options

type
  RequestHandler* = proc(request: Request, response: var Response): Response {.gcsafe.}
  PreRequestMiddlewareHandler* = proc(router: Router, request: Request, response: var Response): bool {.gcsafe, nimcall.}
  PostRequestMiddlewareHandler* = proc(router: Router, request: Request, response: var Response) {.gcsafe, nimcall.}

  Router* = object
    ## Routes HTTP requests. See `addRoute` for more info.
    notFoundHandler*: RequestHandler
      ## Called when no routes match the request URI
    methodNotAllowedHandler*: RequestHandler
      ## Called when the HTTP method is not registered for the route
    errorHandler*: RequestErrorHandler
      ## Called when the route request handler raises an Exception
    preRequestMiddlewareProcs*: seq[PreRequestMiddlewareHandler]
    postRequestMiddlewareProcs*: seq[PostRequestMiddlewareHandler]
    routes: seq[Route]

  RequestErrorHandler* = proc(request: Request, e: ref Exception) {.gcsafe.}

  Route = object
    httpMethod: string
    parts: seq[string]
    handler: RequestHandler

proc addRoute*(
  router: var Router,
  httpMethod, route: string | static string,
  handler: RequestHandler
) =
  ## Adds a route to the router. Routes are a path string and an HTTP method.
  ## When a request comes in, it is tested against the routes in the order
  ## they were added. The handler for the first matching route is called.
  ## The route path can have `*` and `**` wildcards.
  ## The `*` wildcard represents 0 or more characters, excluding `/`.
  ## The `**` wildcard represents 1 or more path elements delimited by `/`.

  when route is static string:
    when route == "":
      {.error: "Invalid empty route".}
    when route[0] != '/':
      {.error: "Routes must begin with /".}

  var parts = route.split('/')
  parts.delete(0)

  var i: int
  while i < parts.len:
    if parts[i] == "**":
      var j = i + 1
      if j < parts.len and (parts[j] == "*" or parts[j] == "**"):
        raise newException(
          MeiraError,
          "Route ** followed by another * or ** is not supported"
        )
      else:
        break
    inc i

  router.routes.add(Route(
    httpMethod: httpMethod,
    parts: move parts,
    handler: handler
  ))

proc get*(
  router: var Router,
  route: string | static string,
  handler: RequestHandler
) =
  ## Adds a route for GET requests. See `addRoute` for more info.
  router.addRoute("GET", route, handler)

proc head*(
  router: var Router,
  route: string | static string,
  handler: RequestHandler
) =
  ## Adds a route for HEAD requests. See `addRoute` for more info.
  router.addRoute("HEAD", route, handler)

proc post*(
  router: var Router,
  route: string | static string,
  handler: RequestHandler
) =
  ## Adds a route for POST requests. See `addRoute` for more info.
  router.addRoute("POST", route, handler)

proc put*(
  router: var Router,
  route: string | static string,
  handler: RequestHandler
) =
  ## Adds a route for PUT requests. See `addRoute` for more info.
  router.addRoute("PUT", route, handler)

proc delete*(
  router: var Router,
  route: string | static string,
  handler: RequestHandler
) =
  ## Adds a route for DELETE requests. See `addRoute` for more info.
  router.addRoute("DELETE", route, handler)

proc options*(
  router: var Router,
  route: string | static string,
  handler: RequestHandler
) =
  ## Adds a route for OPTIONS requests. See `addRoute` for more info.
  router.addRoute("OPTIONS", route, handler)

proc patch*(
  router: var Router,
  route: string | static string,
  handler: RequestHandler
) =
  ## Adds a route for PATCH requests. See `addRoute` for more info.
  router.addRoute("PATCH", route, handler)

proc defaultNotFoundHandler(request: Request, response: var Response): Response =
  const body = "<h1>Not Found</h1>"
  response.headers["Content-Type"] = "text/html"

  response.statusCode = 404
  if request.httpMethod == "HEAD":
    response.headers["Content-Length"] = $body.len
    return response

  response.body = body
  return response

proc defaultMethodNotAllowedHandler(request: Request): Response =
  const body = "<h1>Method Not Allowed</h1>"

  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"

  if request.httpMethod == "HEAD":
    headers["Content-Length"] = $body.len
    return newResponse(405, headers)
  else:
    return newResponse(405, headers, body)

proc isPartialWildcard(test: string): bool {.inline.} =
  test.len > 2 and test.startsWith('*') or test.endsWith('*')

proc partialWildcardMatches(partialWildcard, test: string): bool {.inline.} =
  let
    wildcardPrefix = partialWildcard[0] == '*'
    wildcardSuffix = partialWildcard[^1] == '*'

  var
    literalLen = partialWildcard.len
    literalStart = 0
  if wildcardPrefix:
    dec literalLen
    inc literalStart
  if wildcardSuffix:
    dec literalLen

  if literalLen > test.len:
    return false

  if wildcardPrefix and not wildcardSuffix:
    return equalMem(
      partialWildcard[1].unsafeAddr,
      test[test.len - literalLen].unsafeAddr,
      literalLen
    )

  if wildcardSuffix and not wildcardPrefix:
    return equalMem(
      partialWildcard[0].unsafeAddr,
      test[0].unsafeAddr,
      literalLen
    )

  # Wildcard prefix and suffix *<something>*

  let literal = partialWildcard[1 .. ^2]
  return literal in test

proc pathParts(uri: string): seq[string] =
  # The URI path is assumed to end at the first ? & #
  var
    a = uri.find('?')
    b = uri.find('&')
    c = uri.find('#')
  var len = uri.len
  if a != -1:
    len = min(len, a)
  if b != -1:
    len = min(len, b)
  if c != -1:
    len = min(len, c)

  if len != uri.len:
    result = uri[0 ..< len].split('/')
  else:
    result = uri.split('/')

  result.delete(0)

proc respond(request: Request, response: Response) =
  request.respond(response.statusCode, response.headers, response.body)

proc toHandler*(router: Router): ServerRequestHandler =
  return proc(request: Request) {.gcsafe.} =
    var response = newResponse(200)

    ## All requests arrive here to be routed
    for middlewareProc1 in router.preRequestMiddlewareProcs:
      let shouldReturnResponseEarly = middlewareProc1(router, request, response)
      if shouldReturnResponseEarly:
        # if the middleware returns a Response, that means the request has been
        # considered handled and we should return immediately
        respond(request, response)
        return

    template notFound() =
      if router.notFoundHandler != nil:
        respond(request, router.notFoundHandler(request, response))
      else:
        respond(request, defaultNotFoundHandler(request, response))

    if request.uri.len > 0 and request.uri[0] != '/' and ':' in request.uri:
      notFound()
      return

    try:
      let uriParts = request.uri.pathParts()

      var matchedSomeRoute: bool
      for route in router.routes:
        if route.parts.len > uriParts.len:
          continue

        var
          i: int
          matchedRoute = true
          atLeastOneMultiWildcardMatch = false
        for j, part in uriParts:
          if i >= route.parts.len:
            matchedRoute = false
            break

          if route.parts[i].len > 2 and route.parts[i][0] == '<' and route.parts[i][^1] == '>':
            var urlVarName = route.parts[i][1 .. ^2]
            request.context.urlArgs[urlVarName] = part
            inc i
          elif route.parts[i] == "*": # Wildcard
            inc i
          elif route.parts[i] == "**": # Multi-part wildcard
            # Do we have a required next literal?
            if i + 1 < route.parts.len and atLeastOneMultiWildcardMatch:
              let matchesNextLiteral =
                if route.parts[i + 1].isPartialWildcard():
                  partialWildcardMatches(route.parts[i + 1], part)
                else:
                  part == route.parts[i + 1]
              if matchesNextLiteral:
                i += 2
                atLeastOneMultiWildcardMatch = false
              elif j == uriParts.high:
                matchedRoute = false
                break
            else:
              atLeastOneMultiWildcardMatch = true
          elif route.parts[i].isPartialWildcard():
            if not partialWildcardMatches(route.parts[i], part):
              matchedRoute = false
              break
            inc i
          else: # Literal
            if part != route.parts[i]:
              matchedRoute = false
              break
            inc i

        if matchedRoute:
          matchedSomeRoute = true
          if request.httpMethod == route.httpMethod: # We have a winner
            var handledResponse = route.handler(request, response)

            for middlewareProc in router.postRequestMiddlewareProcs:
              # the post-request middleware can mutate the response if desired
              middlewareProc(router, request, handledResponse)

            respond(request, handledResponse)
            return

      if matchedSomeRoute: # We matched a route but not the HTTP method
        if router.methodNotAllowedHandler != nil:
          respond(request, router.methodNotAllowedHandler(request, response))
        else:
          respond(request, defaultMethodNotAllowedHandler(request))
      else:
        notFound()
    except:
      let e = getCurrentException()
      if router.errorHandler != nil:
        router.errorHandler(request, e)
      else:
        raise e

converter convertToHandler*(router: Router): ServerRequestHandler =
  router.toHandler()
