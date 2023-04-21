import meira

proc indexHandler(request: Request, response: var Response): Response =
  response.headers["Content-Type"] = "text/html"
  response.statusCode = 200
  response.body = """
  <script>
    var ws = new WebSocket("ws://localhost:8080/ws");
    ws.onmessage = function (event) {
      document.body.innerHTML = event.data;
    };
  </script>
  """
  return response

proc upgradeHandler(request: Request, response: var Response): Response =
  let websocket = request.upgradeToWebSocket()
  websocket.send("Hello world from WebSocket!")
  response.statusCode = 200
  return response

proc websocketHandler(
  websocket: WebSocket,
  event: WebSocketEvent,
  message: Message
) =
  case event:
  of OpenEvent:
    discard
  of MessageEvent:
    echo message.kind, ": ", message.data
  of ErrorEvent:
    discard
  of CloseEvent:
    discard

var router: Router
router.get("/", indexHandler)
router.get("/ws", upgradeHandler)

let server = newServer(router, websocketHandler)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
