import times
import strformat
import httpclient
import strutils
import htmlparser
import xmltree
import nimquery
import re
import timezones  # i know, right?
import asyncdispatch

const NimblePkgVersion {.strdefine.} = "Unknown"

let headers = newHttpHeaders({ "User-Agent": "swscl/" & NimblePkgVersion })

# types #

type Update* = ref object
  id*: string  # update id
  date*: DateTime
  text*: string

type Changelog* = ref object
  name*: string  # workshop item name
  id*: string  # workshop item id
  updates*: seq[Update]

type ChangelogPage = ref object
  name: string  # workshop item name
  updates: seq[Update]
  hasNextPage: bool
  nextPage: int

# private #

let losAngelesTZ = tz"America/Los_Angeles"

let patDateWithYear = re"\d+ \w+, \d{4} @ .+"

proc buildChangelogPageUrl(id: string; page: int): string =
  &"https://steamcommunity.com/sharedfiles/filedetails/changelog/{id}?p={page}"

proc getUpdateText(node: XmlNode): string =
  for child in node.items:
    if child.kind == xnText:
      result.add(child.text)
    elif child.kind == xnElement and child.tag == "br":
      result.add("\n")
  result.stripLineEnd()

proc getUpdateDate(formattedDateStr: string): DateTime =
  # input examples:
  # 22 Jul @ 1:42am
  # 23 Aug, 2016 @ 5:57pm
  let tz = losAngelesTZ
  if formattedDateStr.match(patDateWithYear):
    times.parse(formattedDateStr, "d MMM, YYYY '@' h:mmtt", tz)
  else:
    let dt = times.parse(formattedDateStr, "d MMM '@' h:mmtt", tz)
    dt + now().year.years  # set the year

proc getChangelogPage(id: string; page = 1): Future[ChangelogPage] {.async.} =
  var http = newAsyncHttpClient()
  http.headers = headers

  let url = buildChangelogPageUrl(id, page)

  var resp = await http.get(url)
  var body = await resp.body
  var doc = parseHtml(body)  # ignores parsing errors

  # get workshop item name #

  let itemName = doc.querySelector(".workshopItemTitle").innerText

  # get update entries #

  var updates = newSeq[Update]()

  for elem in doc.querySelectorAll(".workshopAnnouncement"):
    let textElem = elem.querySelector("p")
    let text = getUpdateText(textElem)
    let updateId = textElem.attr("id")

    let headlineElem = elem.querySelector(".headline")
    let formattedDateStr = headlineElem.innerText.strip().substr(8)
    let date = getUpdateDate(formattedDateStr)

    let update = Update(date: date, id: updateId, text: text)
    updates.add(update)

  # get page info #

  let pagingControlsElem = doc.querySelector(".workshopBrowsePagingControls")
  var
    hasNextPage = false
    nextPage = -1
  if pagingControlsElem.len > 0:  # has page buttons
    let
      expectedNextPage = page + 1
      expectedNextPageStr = $expectedNextPage
    for node in pagingControlsElem.items:
      if node.innertext == expectedNextPageStr:
        hasNextPage = true
        nextPage = expectedNextPage
        break

  return ChangelogPage(name: itemName, updates: updates, hasNextPage: hasNextPage, nextPage: nextPage)

# public #

proc getChangelog*(id: string; since: Time): Future[Changelog] {.async.} =
  echo "starting on ", id

  var done = false
  var pageNum = 1
  var clPage: ChangelogPage

  var updates = newSeq[Update]()

  while not done:
    clPage = await getChangelogPage(id, pageNum)

    for update in clPage.updates:
      if update.date.toTime() < since:
        done = true
        break
      updates.add(update)

    if not clPage.hasNextPage:
      done = true
    else:
      pageNum = clPage.nextPage
  
  echo "done with ", id

  return Changelog(name: clPage.name, id: id, updates: updates)

proc getChangelog*(id: string; since: DateTime): Future[Changelog] {.async.} =
  return await getChangelog(id, since.toTime())

proc getChangelog*(id: string; since = 0): Future[Changelog] {.async.} =
  return await getChangelog(id, times.fromUnix(since))
