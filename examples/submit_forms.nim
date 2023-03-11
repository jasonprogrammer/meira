import meira
import strformat
import tables

var router: Router
router.get("/public/**", staticFileDirectoryHandler)

proc createUserHandler*(request: Request) =
  let firstName = request.form["first_name"]
  let lastName = request.form["last_name"]
  let foodsStr = request.form["food"]

  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, body=fmt"first: {firstName}, author: {lastName}, foods: {foodsStr}")

router.post("/users", createUserHandler)

let server = newServer(router, staticDir="./examples/public")
echo "Serving on http://localhost:8080"
echo "In a browser, open: http://localhost:8080/public/forms.html"
server.serve(Port(8080))
