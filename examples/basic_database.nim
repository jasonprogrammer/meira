import meira, std/strutils, waterpark/sqlite

## This example demonstrates using a pool of SQLite connections to safely reuse
## connections in Meira HTTP request handlers.
##
## See the Waterpark repo https://github.com/guzba/waterpark for more info about
## connection pools.

let db = newSqlitePool(10, "example.sqlite3")

# For example purposes, set up a dummy table
db.withConnnection conn:
  conn.exec(sql"create table if not exists table1(id primary key, count int)")
  conn.exec(sql"insert or replace into table1 values (0, 0)")

# A request to /get will return the count
proc getHandler(request: Request, response: var Response): Response =
  var count: int
  db.withConnnection conn:
    count = parseInt(conn.getValue(sql"select count from table1 limit 1"))

  response.headers["Content-Type"] = "text/plain"
  response.statusCode = 200
  response.body = "Count: " & $count & "\n"
  return response

# A request to /inc will increase the count by 1
proc incHandler(request: Request, response: var Response): Response =
  db.withConnnection conn:
    conn.exec(sql"update table1 set count = count + 1")

  response.headers["Content-Type"] = "text/plain"
  response.statusCode = 200
  response.body = "Done"
  return response

var router: Router
router.get("/get", getHandler)
router.get("/inc", incHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
