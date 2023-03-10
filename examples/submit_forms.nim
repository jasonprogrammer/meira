import meira
import strformat
import tables

var router: Router
router.get("/public/**", staticFileDirectoryHandler)

proc createUserHandler*(request: Request) =
  let first_name = request.form["first_name"]
  let last_name = request.form["last_name"]

  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, body=fmt"first: {first_name}, author: {last_name}")

router.post("/users", createUserHandler)

let server = newServer(router, staticDir="./examples/public")
echo "Serving on http://localhost:8080"
echo "In a browser, open: http://localhost:8080/public/forms.html"
server.serve(Port(8080))
