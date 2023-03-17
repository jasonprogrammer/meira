## Middlware

### Example code

You can write middleware procedures that run before or after a request is
handled. In the case of post-request handling, the response is passed into the
handler so that the response can be modified.

### Nim code that parses JSON data

```nim
import meira
import jsony
import options
import tables

var router: Router
router.get("/public/**", staticFileDirectoryHandler)

type UserCredentials = object
  username: string
  password: string

proc getCredentials(request: Request): (string, string) =
  let credentials = request.body.fromJson(UserCredentials)
  return (credentials.username, credentials.password)

proc getJsonResponse(loginIsSuccessful: bool): string =
  return {"success": loginIsSuccessful}.toTable().toJson()

proc preRequestMiddleware(router: Router, request: Request): Option[Response] =
  if request.uri != "/login":
    return none(Response)

  let (username, password) = getCredentials(request)

  if username == "before" and password == "password123":
    var headers: HttpHeaders
    headers["Content-Type"] = "text/plain"
    return some(newResponse(200, body=getJsonResponse(true)))
  return none(Response)

proc postRequestMiddleware(router: Router, request: Request, response: var Response) =
  if request.uri != "/login":
    return

  let (username, password) = getCredentials(request)

  if username == "after" and password == "password123":
    response.statusCode = 200
    response.body = getJsonResponse(true)

router.preRequestMiddlewareProcs = @[
  preRequestMiddleware
]

router.postRequestMiddlewareProcs = @[
  postRequestMiddleware
]

proc loginHandler(request: Request): Response =
  let (username, password) = getCredentials(request)

  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"

  if username == "handler" and password == "password123":
    return newResponse(200, headers, body=getJsonResponse(true))

  return newResponse(400, headers, body=getJsonResponse(false))

router.post("/login", loginHandler)

let server = newServer(router, staticDir="./examples/public")
echo "Serving on http://localhost:8080"
echo "In a browser, open: http://localhost:8080/public/middleware.html"
server.serve(Port(8080))
```

### HTML form that submits requests to exercise the middleware

```html
<!DOCTYPE html>
<html lang="en-US">
  <head>
    <meta charset="utf-8" />
    <title>Test</title>
  </head>
  <body>
    <h1>Submit requests to test middleware</h1>

    <input type="submit" value="Submit" onclick="submitForms()"/>
    <div id="results" style="margin-top: 10px"></div>
    <script>
      function appendResult(username, password, responseBody) {
        var container = document.getElementById('results');
        var subContainer = document.createElement('div');
        subContainer.innerHTML = `For ${username}:${password}, response: ${responseBody}`;
        container.appendChild(subContainer);
      }

      function submitForm(username, password) {
        // this code is a modified version of this code:
        //   https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch
        const data = {
          username,
          password
        };

        fetch("http://localhost:8080/login", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(data),
        })
          .then((response) => response.json())
          .then((data) => {
            appendResult(username, password, JSON.stringify(data));
          })
          .catch((error) => {
            appendResult(username, password, JSON.stringify(error));
          });
      }

      function submitForms() {
        submitForm("before", "password123");
        submitForm("handler", "password123");
        submitForm("after", "password123");

        submitForm("before", "wrongpassword");
        submitForm("handler", "wrongpassword");
        submitForm("after", "wrongpassword");
      }
    </script>
  </body>
</html>
```

### Running the example

The example is available by running [middleware.nim](../middleware.nim).
From the project root, run:

```
nimble install
nim c examples/middleware.nim
./examples/middleware
```

### Example output:

```
➜  meira git:(main) ✗ ./examples/middleware
Serving on http://localhost:8080
In a browser, open: http://localhost:8080/public/middleware.html
```

Open the suggested link in a browser, submit the form, and view the responses from the server.


