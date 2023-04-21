import meira
import jsony

var router: Router
router.get("/public/**", staticFileDirectoryHandler)

type User = object
  first_name: string
  last_name: string

proc createUserHandler*(request: Request, response: var Response): Response =
  let user = request.body.fromJson(User)

  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  return newResponse(200, headers, body=user.toJson())

router.post("/users", createUserHandler)

let server = newServer(router, staticDir="./examples/public")
echo "Serving on http://localhost:8080"
echo "In a browser, open: http://localhost:8080/public/submit-json.html"
server.serve(Port(8080))
