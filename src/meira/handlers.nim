import cgi
import filetype
import httpcore
import md5
import ./common
import os
import strutils
import webby
import webby/httpheaders

proc staticFileDirectoryHandler*(request: Request): Response =
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
      MeiraError, "Static web path is misconfigured. URI path: " & uriFilePath
    )

  let filePath = normalizedPath(request.server.staticDir / uriFilePath)

  var headers: httpheaders.HttpHeaders
  headers["Content-Type"] = "text/html"

  if not filePath.startsWith(request.server.staticDir):
    return newResponse(int(Http404), headers)

  if not fileExists(filePath):
    return newResponse(int(Http404), headers)

  var file = getFilePermissions(filePath)
  if not file.contains(fpOthersRead):
    return newResponse(int(Http403), headers)

  headers["Content-Type"] = matchFile(filePath).mime.value

  let fileContents = readFile(filePath)
  let fileSize = getFileSize(filePath)

  if fileSize < request.server.staticFileCacheSizeLimitInBytes:
    var hashed = getMD5(fileContents)

    # If the user has a cached version of this file and it matches our
    # version, let them use it
    if request.headers.contains("If-None-Match") and request.headers["If-None-Match"] == hashed:
      return newResponse(int(Http304), headers)
    else:
      headers["ETag"] = hashed
      return newResponse(int(Http200), headers, fileContents)

  return newResponse(int(Http200), headers, fileContents)

