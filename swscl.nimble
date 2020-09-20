# Package

version       = "0.0.0"
author        = "Zack Guard"
description   = "Retrieve changelogs for Steam Workshop items"
license       = "MIT"
srcDir        = "src"
bin           = @["swscl"]



# Dependencies

requires "nim >= 1.2.2"
requires "nimquery >= 1.2.2"
requires "timezones >= 0.5.3"
requires "docopt >= 0.6.8"
