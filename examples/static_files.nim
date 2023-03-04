import meira
import meira/handlers
import meira/routers

var router: Router
router.get("/public/**", staticFileDirectoryHandler)

let server = newServer(router, staticDir="./examples/public")
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
