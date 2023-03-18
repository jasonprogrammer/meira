import jsony
import os
import random
import tables

proc getRandomString(strLen: int, possibleChars: string): string =
  randomize()

  var randomStr = ""
  for i in countup(1, strLen):
    randomStr = randomStr & possibleChars[rand(len(possibleChars)-1)]

  return randomStr

proc getRandomSecretKey(strLen: int): string =
  let lettersAndNumbers = "abcdefghijklmnopqrstuvwxyz0123456789"
  return getRandomString(strLen, lettersAndNumbers)

proc getRandomIV(strLen: int): string =
  let lettersAndNumbers = "ABCDEF0123456789"
  return getRandomString(strLen, lettersAndNumbers)

proc createRandomAESConfigFile*() =
  writeFile(getCurrentDir() / "cookie-secrets.json",
    {
      "aes_secret_key": getRandomSecretKey(8),
      "aes_secret_aad": getRandomSecretKey(8),
      "aes_secret_iv": getRandomIV(16)
    }.toTable().toJson()
  )


