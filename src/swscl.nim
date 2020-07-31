from times import `$`

import ./changelog

let cl = getChangelog("312294075")
echo cl.name
echo "=========="
for update in cl.updates:
  echo "[", update.date, "]"
  echo update.text
  echo "=========="
