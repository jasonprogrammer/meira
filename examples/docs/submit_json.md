## Submitting JSON data from a form

### Example code

You can parse JSON from the `request.body` using any JSON parser available.

### Nim code that parses JSON data

```nim
import meira
import jsony

var router: Router
router.get("/public/**", staticFileDirectoryHandler)

type User = object
  first_name: string
  last_name: string

proc createUserHandler*(request: Request) =
  let user = request.body.fromJson(User)

  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  request.respond(200, headers, body=user.toJson())

router.post("/users", createUserHandler)

let server = newServer(router, staticDir="./examples/public")
echo "Serving on http://localhost:8080"
echo "In a browser, open: http://localhost:8080/public/submit-json.html"
server.serve(Port(8080))
```

### HTML form that submits JSON

```html
<!DOCTYPE html>
<html lang="en-US">
  <head>
    <meta charset="utf-8" />
    <title>Test</title>
  </head>
  <body>
    <h1>Submit JSON with a JavaScript POST Request</h1>

    <input type="submit" value="Submit" onclick="submitForm()"/>
    <script>
      function submitForm() {
        // this code is a modified version of this code:
        //   https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch
        const data = {
          first_name: "Jane",
          last_name: "Doe"
        };

        fetch("http://localhost:8080/users", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(data),
        })
          .then((response) => response.json())
          .then((data) => {
            alert("Success");
          })
          .catch((error) => {
            alert("Error: " + error);
          });
      }
    </script>
  </body>
</html>
```

### Running the example

The example is available by running [submit_json.nim](../submit_json.nim).
From the project root, run:

```
nimble install
nim c examples/submit_json.nim
./examples/submit_json
```

### Example output:

```
➜  meira git:(main) ✗ ./examples/submit_json
Serving on http://localhost:8080
In a browser, open: http://localhost:8080/public/submit-json.html
```

Open the suggested link in a browser, submit the form, and view the JSON response from the server.


