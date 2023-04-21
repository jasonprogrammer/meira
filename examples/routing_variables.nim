import meira, std/tables

proc indexHandler(request: Request, response: var Response): Response =
  response.headers["Content-Type"] = "text/plain"
  response.statusCode = 200
  response.body = "Hello, World!"
  return response

proc nameHandler(request: Request, response: var Response): Response =
  response.headers["Content-Type"] = "text/plain"
  response.statusCode = 200
  response.body = "Hello " & request.context.urlArgs["first"] & " " & request.context.urlArgs["last"]
  return response

var router: Router
router.get("/", indexHandler)
router.get("/name/<first>/<last>", nameHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
