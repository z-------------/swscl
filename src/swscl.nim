from times import `$`
import asyncdispatch
import sequtils
import sugar

import ./changelog

# let cls = waitFor [getChangelog("312294075")].all
let cls = waitFor all(@["312294075", "472532729"].map((id) => getChangelog(id)))
for cl in cls:
  echo cl.name
