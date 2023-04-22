import cookies
import ../common

proc preRequestMiddleware(router: Router, request: Request, response: var Response): bool =
  if request.uri != "/login":
    return none(Response)

  let (username, password) = getCredentials(request)

  if username == "before" and password == "password123":
    var headers: HttpHeaders
    headers["Content-Type"] = "text/plain"
    return some(newResponse(200, body=getJsonResponse(true)))
  return none(Response)

  


  return false

proc postRequestMiddleware(router: Router, request: Request, response: var Response) =
  if request.uri != "/login":
    return

  let (username, password) = getCredentials(request)

  if username == "after" and password == "password123":
    response.statusCode = 200
    response.body = getJsonResponse(true)


