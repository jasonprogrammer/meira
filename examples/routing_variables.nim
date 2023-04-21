import meira, std/tables

proc indexHandler(request: Request, response: var Response): Response =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  return newResponse(200, headers, "Hello, World!")

proc nameHandler(request: Request, response: var Response): Response =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  return newResponse(200, headers, "Hello " & request.context.urlArgs["first"] & " " & request.context.urlArgs["last"])

var router: Router
router.get("/", indexHandler)
router.get("/name/<first>/<last>", nameHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
