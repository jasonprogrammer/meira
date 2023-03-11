import httpclient
import ../src/meira
import tables

var router: Router

router.notFoundHandler = proc(request: Request) =
  doAssert false
router.methodNotAllowedHandler = proc(request: Request) =
  doAssert false
router.errorHandler = proc(request: Request, e: ref Exception) =
  echo "An error has occurred!"
  echo e.msg
  doAssert false

proc createUserHandler*(request: Request) =
  case request.params["test_number"]
  of "1":
    doAssert request.form["first_name"] == "jane"
    doAssert request.form["last_name"] == "doe"

  request.respond(200)


router.get("/users", createUserHandler)
let server = newServer(router)

var requesterThread: Thread[void]

proc requesterProc() =
  server.waitUntilReady()

  let client = newHttpClient()
  discard client.post("http://localhost:8081/users", "test_number=1&first_name=jane&last_name=doe")

  echo "Done, shutting down the server"
  server.close()

createThread(requesterThread, requesterProc)

# Start the server
server.serve(Port(8081))
