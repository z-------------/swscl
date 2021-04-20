import asyncdispatch
import docopt
import options
import os
import re
import sequtils
import strutils
import sugar
import times
import userconfig

import ./changelog

const doc = """
Usage:
  swscl id <ids> [--since=<tp>]
  swscl dir [<dir>] [--since=<tp>]
  swscl (-h | --help)

Arguments:
  <ids>         Comma-separated list of Workshop IDs.

Options:
  --since=<tp>  Show changelogs from a period of time.
                Time periods are denoted {x}{u}, where {x} is an integer and {u}
                is one of the following:
                  u - since {x} as Unix time in seconds
                  w - since {x} weeks ago
  -h --help     Show this help and exit.
"""

proc die(msg: string; code = 1) {.noreturn.} =
  stdout.writeLine(msg)
  quit(code)

proc isWorkshopAddonFilename(filename: string): bool =
  filename.match(re"\d+\.vpk")

proc getWorkshopId(filename: string): string =
  let extIdx = filename.find(".vpk")
  return filename[0..extIdx]

#
# main
#

let args = docopt(doc)

var sinceTime = 0.fromUnix
if args["--since"]:
  let
    sinceStr = $args["--since"]
    number = sinceStr[0..<sinceStr.high].parseInt
    unit = sinceStr[sinceStr.high]

  if unit == 'u':
    sinceTime = number.fromUnix
  else:
    let interval =
      if unit == 'w':
        some(number.weeks)
      else:
        none(TimeInterval)
    if interval.isSome:
      sinceTime = (now() - interval.get).toTime
    else:
      die("Invalid interval '" & sinceStr & "'.")
  
  echo "sinceTime = ", sinceTime

# get workshop IDs #

var workshopIds: seq[string]

if args["dir"]:
  var dirPath: string
  if args["<dir>"]:
    dirPath = $args["<dir>"]
  else:
    let config = initConfigDir("com.zackguard.swscl")
    const DirPathFilename = "addonsDir"
    try:
      let lst = config.loadList(DirPathFilename)
      dirPath = lst[0]
    except IOError:
      die("Error reading " & config.getPath(DirPathFilename) & ". (Does it exist?)")
  
  for kind, filename in walkDir(dirPath, relative = true):
    if kind != pcFile:
      continue
    if not filename.isWorkshopAddonFilename:
      continue
    let workshopId = getWorkshopId(filename)
    workshopIds.add(workshopId)

elif args["id"]:
  for id in ($args["<ids>"]).split(","):
    workshopIds.add(id)

# fetch #

let changelogs = waitFor all(workshopIds.map((id) => getChangelog(id, sinceTime)))
for changelog in changelogs:
  if changelog.updates.len == 0:
    continue
  echo changelog.name, " (", changelog.updates.len, " updates)"
