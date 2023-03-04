import mummy, mummy/routers, std/tables

proc indexHandler(request: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, "Hello, World!")

proc nameHandler(request: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, "Hello " & request.context.urlArgs["first"] & " " & request.context.urlArgs["last"])

var router: Router
router.get("/", indexHandler)
router.get("/name/<first>/<last>", nameHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
