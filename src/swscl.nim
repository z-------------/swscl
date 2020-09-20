import asyncdispatch
import docopt
import options
import os
import re
import sequtils
import strutils
import sugar
import times

import ./changelog

const doc = """
Usage:
  swscl (id <id>... | dir <dir>) [--since=<tp>]
  swscl (-h | --help)

Options:
  --since=<tp>  Show changelogs from a period of time.
                Time periods are denoted {x}{u}, where {x} is an integer and {u}
                is one of the following:
                  w - weeks
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

# handle opts #

let args = docopt(doc)

var sinceTime = 0.fromUnix
if args["--since"]:
  let
    sinceStr = $args["--since"]
    number = sinceStr[0..<sinceStr.high].parseInt
    unit = sinceStr[sinceStr.high]
    interval =
      if unit == 'w':
        some(number.weeks)
      else:
        none(TimeInterval)
  if interval.isSome:
    sinceTime = (now() - interval.get).toTime
  else:
    die("Invalid interval '" & sinceStr & "'.")

# fetch #

if args["dir"]:
  var workshopIds: seq[string]

  let dirPath = $args["<dir>"]
  for kind, filename in walkDir(dirPath, relative = true):
    if kind != pcFile:
      continue
    if not filename.isWorkshopAddonFilename:
      continue
    let workshopId = getWorkshopId(filename)
    workshopIds.add(workshopId)
  
  let changelogs = waitFor all(workshopIds.map((id) => getChangelog(id, sinceTime)))
  for changelog in changelogs:
    if changelog.updates.len == 0:
      continue
    echo changelog.name
