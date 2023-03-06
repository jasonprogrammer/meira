import httpclient
import ../src/meira
import tables

var router: Router

router.notFoundHandler = proc(request: Request) =
  doAssert false
router.methodNotAllowedHandler = proc(request: Request) =
  doAssert false
router.errorHandler = proc(request: Request, e: ref Exception) =
  # echo e.msg
  doAssert false

proc searchHandler(request: Request) =
  doAssert request.params["first_name"] == "jane"
  doAssert request.params["last_name"] == "doe"
  request.respond(200)

router.get("/search", searchHandler)
let server = newServer(router)

var requesterThread: Thread[void]

proc requesterProc() =
  server.waitUntilReady()

  block:
    let client = newHttpClient()
    let response = client.request("http://localhost:8081/search?first_name=jane&last_name=doe")
    doAssert response.status == "200"

  echo "Done, shutting down the server"
  server.close()

createThread(requesterThread, requesterProc)

# Start the server
server.serve(Port(8081))
