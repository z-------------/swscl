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
  swscl dir [<dir>] [--since=<tp>] [--write-time]
  swscl (-h | --help)

Arguments:
  <ids>         Comma-separated list of Workshop IDs.

Options:
  --since=<tp>  Show changelogs from a period of time.
                Time periods are denoted {x}{u}, where {x} is an integer and {u}
                is one of the following:
                  u - Since {x} as Unix time in seconds. If in 'dir' mode and
                    {x} is 'f', read value from file '_swscl_time' in
                    target directory.
                  w - Since {x} weeks ago.
  --write-time  Write current Unix timestamp in seconds to file '_swscl_time' in
                target directory.
  -h --help     Show this help and exit.
"""

const TimestampFilename = "_swscl_time"

let workshopFilenamePat = re"^(\d+)(.*)?\.vpk$"

proc die(msg: string; code = 1) {.noreturn.} =
  stdout.writeLine(msg)
  quit(code)

proc isWorkshopAddonFilename(filename: string): bool =
  filename.match(workshopFilenamePat)

proc getWorkshopId(filename: string): string =
  var matches: array[2, string]
  if match(filename, workshopFilenamePat, matches):
    result = matches[0]

#
# main
#

let args = docopt(doc)

var
  sinceTime = 0.fromUnix
  readSinceTimeFromFile = false

if args["--since"]:
  let
    sinceStr = $args["--since"]
    numberStr = sinceStr[0..<sinceStr.high]
    unit = sinceStr[sinceStr.high]

  if unit == 'u':
    if numberStr == "f":
      readSinceTimeFromFile = true
    else:
      sinceTime = numberStr.parseInt.fromUnix
  else:
    let
      number = numberStr.parseInt
      interval =
        if unit == 'w':
          some(number.weeks)
        else:
          none(TimeInterval)
    if interval.isSome:
      sinceTime = (now() - interval.get).toTime
    else:
      die("Invalid interval '" & sinceStr & "'.")
  
  # echo "sinceTime = ", sinceTime

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
    if readSinceTimeFromFile and filename == TimestampFilename:
      let sinceTimestamp = readFile(joinPath(dirPath, filename)).strip.parseInt
      sinceTime = sinceTimestamp.fromUnix
      continue
    if not filename.isWorkshopAddonFilename:
      continue
    let workshopId = getWorkshopId(filename)
    workshopIds.add(workshopId)

  if args["--write-time"]:
    writeFile(joinPath(dirPath, TimestampFilename), $getTime().toUnix)

elif args["id"]:
  for id in ($args["<ids>"]).split(","):
    workshopIds.add(id)

# fetch #

let changelogs = waitFor all(workshopIds.map((id) => getChangelog(id, sinceTime)))
for changelog in changelogs:
  if changelog.updates.len == 0:
    continue
  echo changelog.name, "\t", changelog.updates.len, "\t", changelog.id, "\t", "https://steamcommunity.com/sharedfiles/filedetails/?id=" & $changelog.id
