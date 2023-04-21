import meira
import strformat
import tables

proc searchHandler(request: Request, response: var Response): Response =
  let title = request.params["title"]
  let author = request.params["author"]
  return newResponse(200, body=fmt"title: {title}, author: {author}")

var router: Router
router.get("/search", searchHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
echo "In a browser, open: http://localhost:8080/search?title=cat&author=seuss"
server.serve(Port(8080))
