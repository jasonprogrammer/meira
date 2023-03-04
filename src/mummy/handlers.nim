import cgi
import filetype
import httpcore
import md5
import mummy
import mummy/common
import os
import strutils
import webby

proc staticFileDirectoryHandler*(request: Request) =
  ## This handler helps serve static files from a directory.
  ##
  ## The code in this handler was copied and adapted from the static file
  ## handling in Jester:
  ##   https://github.com/dom96/jester
  var uriFilePath = cgi.decodeUrl(request.uri)

  # if the file URI is "/public/images/test.png", strip the "/public" from the
  # beginning of the string so we can concatenate the the rest of the path to
  # our server's static directory
  let webPathPrefix = request.server.staticWebDir & "/"
  if uriFilePath.startsWith(webPathPrefix):
    uriFilePath = uriFilePath[len(webPathPrefix) - 1 .. ^1]
  else:
    raise newException(
      MummyError, "Static web path is misconfigured. URI path: " & uriFilePath
    )

  let filePath = normalizedPath(request.server.staticDir / uriFilePath)

  var headers: mummy.HttpHeaders
  headers["Content-Type"] = "text/html"

  if not filePath.startsWith(request.server.staticDir):
    request.respond(int(Http404), headers)
    return

  if not fileExists(filePath):
    request.respond(int(Http404), headers)
    return

  var file = getFilePermissions(filePath)
  if not file.contains(fpOthersRead):
    request.respond(int(Http403), headers)
    return

  headers["Content-Type"] = matchFile(filePath).mime.value

  let fileContents = readFile(filePath)
  let fileSize = getFileSize(filePath)

  if fileSize < request.server.staticFileCacheSizeLimitInBytes:
    var hashed = getMD5(fileContents)

    # If the user has a cached version of this file and it matches our
    # version, let them use it
    if request.headers.contains("If-None-Match") and request.headers["If-None-Match"] == hashed:
      request.respond(int(Http304), headers)
    else:
      headers["ETag"] = hashed
      request.respond(int(Http200), headers, fileContents)

  request.respond(int(Http200), headers, fileContents)

