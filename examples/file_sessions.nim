import meira
import os
import jsony
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

proc preRequestMiddleware(router: Router, request: Request, response: var Response): bool =
  response.statusCode = 200
  response.body = getJsonResponse(true)

proc postRequestMiddleware(router: Router, request: Request, response: var Response) =
  response.headers.add(("Set-Cookie", "there"))
  let sessionId = "abcdef12345"
  if request.session.sessionHasChanged:
    writeFile(
      getTempDir() / sessionId,
      request.session.toJson()
    )

router.preRequestMiddlewareProcs = @[
  preRequestMiddleware
]

router.postRequestMiddlewareProcs = @[
  postRequestMiddleware
]

proc loginHandler(request: Request, response: var Response): Response =
  let (username, password) = getCredentials(request)

  response.headers["Content-Type"] = "application/json"

  if username == "amy" and password == "password123":
    request.setSessionValue("user_id", "12345")

    response.statusCode = 200
    response.body = getJsonResponse(true)
    return response

  response.statusCode = 401
  response.body = getJsonResponse(false)
  return response

router.post("/login", loginHandler)

let server = newServer(router, staticDir="./examples/public")
echo "Serving on http://localhost:8080"
echo "In a browser, open: http://localhost:8080/public/file_sessions.html"
server.serve(Port(8080))
