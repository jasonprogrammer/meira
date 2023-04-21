import meira
import strformat
import tables

var router: Router
router.get("/public/**", staticFileDirectoryHandler)

proc createUserHandler*(request: Request, response: var Response): Response =
  let firstName = request.form["first_name"]
  let lastName = request.form["last_name"]
  let foodsStr = request.form["food"]

  response.headers["Content-Type"] = "text/plain"
  response.statusCode = 200
  response.body = fmt"first: {firstName}, author: {lastName}, foods: {foodsStr}"
  return response

router.post("/users", createUserHandler)

let server = newServer(router, staticDir="./examples/public")
echo "Serving on http://localhost:8080"
echo "In a browser, open: http://localhost:8080/public/forms.html"
server.serve(Port(8080))
