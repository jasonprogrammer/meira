import ./internal, std/atomics, std/base64,
    std/cpuinfo, std/deques, std/hashes, std/nativesockets, std/os,
    std/parseutils, std/selectors, std/sets, std/sha1, std/strutils, std/tables,
    std/times, webby/httpheaders, zippy

when defined(linux):
    import posix

const useLockAndCond* = (not defined(linux)) or defined(meiraUseLockAndCond)

type
  MeiraError* = object of CatchableError

  HttpVersion* = enum
    Http10, Http11

  LogLevel* = enum
    DebugLevel, InfoLevel, ErrorLevel

  LogHandler* = proc(level: LogLevel, args: varargs[string]) {.gcsafe.}

  RequestContext* = object
    urlArgs*: Table[string, string]

  Session* = object
    values*: Table[string, string]
    sessionHasChanged*: bool

  RequestObj* = object
    httpVersion*: HttpVersion
    httpMethod*: string
    uri*: string
    headers*: HttpHeaders
    body*: string
    remoteAddress*: string
    server*: Server
    clientSocket*: SocketHandle
    responded*: bool
    context*: RequestContext
    params*: Table[string, string]
    form*: Table[string, string]
    session*: Session

  Request* = ptr RequestObj

  Response* = object
    statusCode*: int
    headers*: HttpHeaders
    body*: string

  WebSocket* = object
    server*: Server
    clientSocket*: SocketHandle

  Message* = object
    kind*: MessageKind
    data*: string

  WebSocketEvent* = enum
    OpenEvent, MessageEvent, ErrorEvent, CloseEvent

  MessageKind* = enum
    TextMessage, BinaryMessage, Ping, Pong

  ServerRequestHandler* = proc(request: Request) {.gcsafe.}

  WebSocketHandler* = proc(
    websocket: WebSocket,
    event: WebSocketEvent,
    message: Message
  ) {.gcsafe.}

  ServerObj* = object
    handler*: ServerRequestHandler
    websocketHandler*: WebSocketHandler
    logHandler*: LogHandler
    maxHeadersLen*, maxBodyLen*, maxMessageLen*: int
    workerThreads*: seq[Thread[(Server, int)]]
    serving*, destroyCalled*: Atomic[bool]
    socket*: SocketHandle
    selector*: Selector[DataEntry]
    responseQueued*, sendQueued*, shutdown*: SelectEvent
    clientSockets*: HashSet[SocketHandle]
    when useLockAndCond:
      taskQueueLock*: Lock
      taskQueueCond*: Cond
    else:
      taskQueueLock*: Atomic[bool]
      workerEventFds*: seq[cint]
      destroyCalledFd*: cint
      workersAwake*: int
    taskQueue*: Deque[WorkerTask]
    responseQueue*: Deque[OutgoingBuffer]
    responseQueueLock*: Atomic[bool]
    sendQueue*: Deque[OutgoingBuffer]
    sendQueueLock*: Atomic[bool]
    websocketClaimed*: Table[WebSocket, bool]
    websocketQueues*: Table[WebSocket, Deque[WebSocketUpdate]]
    websocketQueuesLock*: Atomic[bool]
    staticDir*: string
    staticWebDir*: string
    staticFileCacheSizeLimitInBytes*: int

  Server* = ptr ServerObj

  WorkerTask* = object
    request*: Request
    websocket*: WebSocket

  DataEntryKind* = enum
    ServerSocketEntry, ClientSocketEntry, EventEntry

  DataEntry* = ref object
    case kind*: DataEntryKind:
    of ServerSocketEntry:
      discard
    of EventEntry:
      event*: SelectEvent
    of ClientSocketEntry:
      remoteAddress*: string
      recvBuf*: string
      bytesReceived*: int
      requestState*: IncomingRequestState
      frameState*: IncomingFrameState
      outgoingBuffers*: Deque[OutgoingBuffer]
      closeFrameQueuedAt*: float64
      upgradedToWebSocket*, closeFrameSent*: bool
      sendsWaitingForUpgrade*: seq[OutgoingBuffer]

  IncomingRequestState* = object
    headersParsed*, chunked*: bool
    contentLength*: int
    httpVersion*: HttpVersion
    httpMethod*, uri*: string
    headers*: HttpHeaders
    body*: string

  IncomingFrameState* = object
    opcode*: uint8
    buffer*: string
    frameLen*: int

  OutgoingBuffer* {.acyclic.} = ref object
    clientSocket*: SocketHandle
    closeConnection*, isWebSocketUpgrade*, isCloseFrame*: bool
    buffer1*, buffer2*: string
    bytesSent*: int

  WebSocketUpdate* {.acyclic.} = ref object
    event*: WebSocketEvent
    message*: Message

proc echoLogger*(level: LogLevel, args: varargs[string]) =
  ## This is a simple echo logger.
  if args.len == 1:
    echo args[0]
  else:
    var lineLen = 0
    for arg in args:
      lineLen += arg.len
    var line = newStringOfCap(lineLen)
    for arg in args:
      line.add(arg)
    echo line

template withLock*(lock: var Atomic[bool], body: untyped): untyped =
  # TAS
  while lock.exchange(true, moAcquire): # Until we get the lock
    discard
  try:
    body
  finally:
    lock.store(false, moRelease)

proc headerContainsToken*(headers: var HttpHeaders, key, token: string): bool =
  for (k, v) in headers:
    if cmpIgnoreCase(k, key) == 0:
      var first = 0
      while first < v.len:
        var comma = v.find(',', start = first)
        if comma == -1:
          comma = v.len
        var len = comma - first
        while len > 0 and v[first] in Whitespace:
          inc first
          dec len
        while len > 0 and v[first + len - 1] in Whitespace:
          dec len
        if len > 0 and len == token.len:
          var matches = true
          for i in 0 ..< len:
            if ord(toLowerAscii(v[first + i])) != ord(toLowerAscii(token[i])):
              matches = false
              break
          if matches:
            return true
        first = comma + 1

proc log*(server: Server, level: LogLevel, args: varargs[string]) =
  if server.logHandler == nil:
    return
  try:
    server.logHandler(level, args)
  except:
    discard # ???

proc trigger*(
  server: Server,
  event: SelectEvent
) {.raises: [].} =
  try:
    event.trigger()
  except:
    let err = osLastError()
    server.log(
      ErrorLevel,
      "Error triggering event ", $err, " ", osErrorMsg(err)
    )

proc setSessionValue*(
  request: Request,
  key: string,
  value: string,
) =
  request.session.values[key] = value
  request.session.sessionHasChanged = true

proc getSessionValue*(
  request: Request,
  key: string,
): string =
  return request.session.values.getOrDefault(key)

proc hasSessionValue*(
  request: Request,
  key: string,
): bool =
  return request.session.values.hasKey(key)

proc deleteSessionValue*(
  request: Request,
  key: string,
) =
  request.session.values.del(key)
  request.session.sessionHasChanged = true

proc respond*(
  request: Request,
  statusCode: int,
  headers: sink HttpHeaders = emptyHttpHeaders(),
  body: sink string = ""
) {.raises: [], gcsafe.} =
  ## Sends the response for the request.
  ## This should usually only be called once per request.

  var encodedResponse = OutgoingBuffer()
  encodedResponse.clientSocket = request.clientSocket
  encodedResponse.closeConnection =
    request.httpVersion == Http10 # Default behavior

  # Override default behavior based on request Connection header
  if request.headers.headerContainsToken("Connection", "close"):
    encodedResponse.closeConnection = true
  elif request.headers.headerContainsToken("Connection", "keep-alive"):
    encodedResponse.closeConnection = false

  # If we are not already going to close the connection based on the request
  # headers, check if we should based on the response headers
  if not encodedResponse.closeConnection:
    encodedResponse.closeConnection = headers.headerContainsToken(
      "Connection", "close"
    )

  if encodedResponse.closeConnection:
    headers["Connection"] = "close"
  elif request.httpVersion == Http10:
    headers["Connection"] = "keep-alive"

  # If the body is big enough to justify compressing and not already compressed
  if body.len > 128 and "Content-Encoding" notin headers:
    if request.headers.headerContainsToken("Accept-Encoding", "gzip"):
      try:
        body = compress(body.cstring, body.len, BestSpeed, dfGzip)
        headers["Content-Encoding"] = "gzip"
      except:
        # This should never happen since exceptions are only thrown if
        # the data format is invalid or the level is invalid
        discard
    elif request.headers.headerContainsToken("Accept-Encoding", "deflate"):
      try:
        body = compress(body.cstring, body.len, BestSpeed, dfDeflate)
        headers["Content-Encoding"] = "deflate"
      except:
        # See gzip
        discard
    else:
      discard

  if "Content-Length" notin headers:
    headers["Content-Length"] = $body.len

  encodedResponse.buffer1 = encodeHeaders(statusCode, headers)
  if encodedResponse.buffer1.len + body.len < 32 * 1024:
    # There seems to be a harsh penalty on multiple send() calls on Linux
    # so just use 1 buffer if the body is small enough
    encodedResponse.buffer1 &= body
  else:
    encodedResponse.buffer2 = move body
  encodedResponse.isWebSocketUpgrade = headers.headerContainsToken(
    "Upgrade",
    "websocket"
  )

  request.responded = true

  var queueWasEmpty: bool
  withLock request.server.responseQueueLock:
    queueWasEmpty = request.server.responseQueue.len == 0
    request.server.responseQueue.addLast(move encodedResponse)

  if queueWasEmpty:
    request.server.trigger(request.server.responseQueued)

proc newResponse*(statusCode: int, headers: HttpHeaders = emptyHttpHeaders(), body: string = ""): Response =
  return Response(
    statusCode: statusCode,
    headers: headers,
    body: body
  )


