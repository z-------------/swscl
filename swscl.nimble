# Package

version       = "0.0.0"
author        = "Zack Guard"
description   = "Retrieve changelogs for Steam Workshop items"
license       = "MIT"
srcDir        = "src"
bin           = @["swscl"]



# Dependencies

requires "nim >= 1.2.2, nimquery >= 1.2.2, timezones >= 0.5.3"
