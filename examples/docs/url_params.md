## Accessing URL parameters

### Example code

You can access URL parameters using `request.params`:

```nim
import meira
import strformat
import tables

proc searchHandler(request: Request) =
  let title = request.params["title"]
  let author = request.params["author"]
  request.respond(200, body=fmt"title: {title}, author: {author}")

var router: Router
router.get("/search", searchHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
echo "In a browser, open: http://localhost:8080/search?title=cat&author=seuss"
server.serve(Port(8080))
```

### Running the example

The example is available by running [url_params.nim](../url_params.nim).
From the project root, run:

```
nimble install
nim c examples/url_params.nim
./examples/url_params
```

### Example output:

```
➜  meira git:(main) ✗ ./examples/url_params
Serving on http://localhost:8080
In a browser, open: http://localhost:8080/search?title=cat&author=seuss
```

Open the suggested link in a browser, and see the author and title printed to the page.


