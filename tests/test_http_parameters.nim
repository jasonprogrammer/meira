import httpclient
import ../src/meira
import tables

var router: Router

router.notFoundHandler = proc(request: Request) =
  doAssert false
router.methodNotAllowedHandler = proc(request: Request) =
  doAssert false
router.errorHandler = proc(request: Request, e: ref Exception) =
  doAssert false

proc searchHandler(request: Request) =
  case request.params["test_number"]
  of "1":
    doAssert request.params["first_name"] == "jane"
    doAssert request.params["last_name"] == "doe"
  of "2":
    doAssert request.params["a"] == "1,2,3"
  of "3":
    doAssert request.params["a"] == "cat,dog,pig"

  request.respond(200)

router.get("/search", searchHandler)
let server = newServer(router)

var requesterThread: Thread[void]

proc requesterProc() =
  server.waitUntilReady()

  let client = newHttpClient()
  discard client.request("http://localhost:8081/search?test_number=1&first_name=jane&last_name=doe")
  discard client.request("http://localhost:8081/search?test_number=2&a=1&a=2&a=3")
  discard client.request("http://localhost:8081/search?test_number=3&a=cat&a=dog&a=pig")

  echo "Done, shutting down the server"
  server.close()

createThread(requesterThread, requesterProc)

# Start the server
server.serve(Port(8081))
