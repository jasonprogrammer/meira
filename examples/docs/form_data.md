## Accessing form data

### Example code

You can access form data using `request.form`:

## Nim code to process the form data

```nim
import meira
import strformat
import tables

var router: Router
router.get("/public/**", staticFileDirectoryHandler)

proc createUserHandler*(request: Request) =
  let firstName = request.form["first_name"]
  let lastName = request.form["last_name"]
  let foodsStr = request.form["food"]

  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, body=fmt"first: {firstName}, author: {lastName}, foods: {foodsStr}")

router.post("/users", createUserHandler)

let server = newServer(router, staticDir="./examples/public")
echo "Serving on http://localhost:8080"
echo "In a browser, open: http://localhost:8080/public/forms.html"
server.serve(Port(8080))
```

## HTML form to send the form data

```html
<!DOCTYPE html>
<html lang="en-US">
  <head>
    <meta charset="utf-8" />
    <title>Test</title>
  </head>
  <body>
    <h1>Submit a POST form</h1>
    <form action="/users" method="post">
      <label for="fname">First name:</label>
      <input type="text" id="first_name" name="first_name"><br><br>
      <label for="lname">Last name:</label>
      <input type="text" id="last_name" name="last_name"><br><br>

      <fieldset>
        <legend>What kinds of food do you like?</legend>

        <div>
          <input type="checkbox" id="pizza" name="food" value="pizza" checked>
          <label for="pizza">Pizza</label>
        </div>

        <div>
          <input type="checkbox" id="burger" name="food" value="burger" checked>
          <label for="burger">burger</label>
        </div>

        <div>
          <input type="checkbox" id="taco" name="food" value="taco" checked>
          <label for="taco">Taco</label>
        </div>
      </fieldset>

      <input type="submit" value="Submit">
    </form>
  </body>
</html>
```

### Running the example

The example is available by running [submit_forms.nim](../submit_forms.nim).
From the project root, run:

```
nimble install
nim c examples/submit_forms.nim
./examples/submit_forms
```

### Example output:

```
➜  meira git:(main) ✗ ./examples/submit_forms
Serving on http://localhost:8080
In a browser, open: http://localhost:8080/public/forms.html
```

Open the suggested link in a browser, submit the form, and see the output on the page.



