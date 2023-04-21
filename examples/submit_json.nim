import meira
import jsony

var router: Router
router.get("/public/**", staticFileDirectoryHandler)

type User = object
  first_name: string
  last_name: string

proc createUserHandler*(request: Request, response: var Response): Response =
  let user = request.body.fromJson(User)

  response.headers["Content-Type"] = "application/json"
  response.statusCode = 200
  response.body=user.toJson()
  return response

router.post("/users", createUserHandler)

let server = newServer(router, staticDir="./examples/public")
echo "Serving on http://localhost:8080"
echo "In a browser, open: http://localhost:8080/public/submit-json.html"
server.serve(Port(8080))
