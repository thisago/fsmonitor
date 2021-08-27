# Package

version       = "0.1.0"
author        = "Thiago Navarro"
description   = "Files changes monitor and logger"
license       = "MIT"
srcDir        = "src"
binDir = "build"

bin = @["fsmonitor"]

# Dependencies

requires "nim >= 1.4.6"
requires "cligen"
