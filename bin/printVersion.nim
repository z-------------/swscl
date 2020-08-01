import strutils

for line in lines("swscl.nimble"):
  if line.startsWith("version"):
    let
      openQuoteIdx = line.find('"')
      closeQuoteIdx = line.rfind('"')
    let versionStr = line.substr(openQuoteIdx + 1, closeQuoteIdx - 1)
    writeFile("version", versionStr)
    break
