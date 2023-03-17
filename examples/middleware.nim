import ../src/meira
import jsony
import options
import tables

var router: Router
router.get("/public/**", staticFileDirectoryHandler)

type UserCredentials = object
  username: string
  password: string

proc getCredentials(request: Request): (string, string) =
  let credentials = request.body.fromJson(UserCredentials)
  return (credentials.username, credentials.password)

proc getJsonResponse(loginIsSuccessful: bool): string =
  return {"success": loginIsSuccessful}.toTable().toJson()

proc preRequestMiddleware(router: Router, request: Request): Option[Response] =
  if request.uri != "/login":
    return none(Response)

  let (username, password) = getCredentials(request)

  if username == "before" and password == "password123":
    var headers: HttpHeaders
    headers["Content-Type"] = "text/plain"
    return some(newResponse(200, body=getJsonResponse(true)))
  return none(Response)

proc postRequestMiddleware(router: Router, request: Request, response: var Response) =
  if request.uri != "/login":
    return

  let (username, password) = getCredentials(request)

  if username == "after" and password == "password123":
    response.statusCode = 200
    response.body = getJsonResponse(true)

router.preRequestMiddlewareProcs = @[
  preRequestMiddleware
]

router.postRequestMiddlewareProcs = @[
  postRequestMiddleware
]

proc loginHandler(request: Request): Response =
  let (username, password) = getCredentials(request)

  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"

  if username == "handler" and password == "password123":
    return newResponse(200, headers, body=getJsonResponse(true))

  return newResponse(400, headers, body=getJsonResponse(false))

router.post("/login", loginHandler)

let server = newServer(router, staticDir="./examples/public")
echo "Serving on http://localhost:8080"
echo "In a browser, open: http://localhost:8080/public/middleware.html"
server.serve(Port(8080))
