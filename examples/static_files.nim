import meira

var router: Router
router.get("/public/**", staticFileDirectoryHandler)

let server = newServer(router, staticDir="./examples/public")
echo "Serving on http://localhost:8080"
echo "In a browser, open: http://localhost:8080/public/index.html"
server.serve(Port(8080))
