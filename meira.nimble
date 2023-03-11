version     = "0.0.1"
author      = "Jason Jason"
description = "Web framework built on the Mummy HTTP server"
license     = "MIT"

srcDir = "src"

requires "nim >= 1.6.8"
requires "zippy == 0.10.4"
requires "webby == 0.1.3"
requires "filetype == 0.9.0"

# for tests/test_http_json_with_requester_threads.nim
requires "jsony == 1.1.5"

# for tests/test_websockets.nim
requires "ws == 0.5.0"
