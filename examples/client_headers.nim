import meira

## This example shows how to access client request headers.

proc indexHandler(request: Request, response: var Response): Response =
  # Access specific request headers
  echo request.headers["Host"]

  # Access request headers in an iterator
  for (key, value) in request.headers:
    echo key, " = ", value

  # Send all of the request headers back to the client as text
  response.headers["Content-Type"] = "text/plain"
  response.statusCode = 200
  response.body = $request.headers
  return response

var router: Router
router.get("/", indexHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
