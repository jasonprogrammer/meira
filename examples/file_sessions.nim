import cookies
import meira
import options
import os
import jsony
import tables
import uuid4

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
  return false

proc postRequestMiddleware(router: Router, request: Request, response: var Response) =
  if not request.session.sessionHasChanged:
    return

  var sessionId = ""
  if request.hasSessionValue("session_id"):
    sessionId = request.getSessionValue("session_id")
  else:
    sessionId = $uuid4()
    response.headers.add((
      "Set-Cookie",
      setCookie("session_id", sessionId, maxAge=some(60 * 60 * 12), httpOnly=true))
    )
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
