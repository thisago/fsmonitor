#[
  Created at: 08/27/2021 20:23:54 Friday
  Modified at: 08/28/2021 12:08:01 AM Saturday
]#

from std/os import commandLineParams, walkDirRec, fileExists, expandFilename,
                   getHomeDir, `/`, dirExists, createDir
from std/sha1 import secureHashFile, `$`
from std/tables import `[]=`, Table, pairs, hasKey, `[]`
from std/json import parseJson, `{}`, to, `%*`, `%`, `[]=`, `$`
from std/strformat import fmt
from std/strutils import join, contains

const dbFolder = getHomeDir() / ".fsmonitor"

type
  Hashes* = Table[string, string]
  ChangeKind* = enum
    CkCreated, CkDeleted, CkEdited
  ChangedHashes* = Table[string, ChangeKind]

proc getLastHashes(dir: string; dbPath: string): Hashes =
  try:
    let
      json = dbPath.readFile.parseJson
      hashes = json.to Hashes
    for (path, hash) in hashes.pairs:
      if dir in path:
        result[path] = hash
  except:
    quit "Error on parse DB"

proc compare(newHashes, oldHashes: Hashes): ChangedHashes =
  for (path, hash) in newHashes.pairs:
    if oldHashes.hasKey path:
      if hash != oldHashes[path]:
        result[path] = CkEdited
    else:
      result[path] = CkCreated
  for (path, hash) in oldHashes.pairs:
    if not newHashes.hasKey path:
      result[path] = CkDeleted

proc `$`(self: Changekind): string =
  case self:
  of CkCreated: "created"
  of CkEdited: "edited"
  of CkDeleted: "deleted"

proc `$`(self: ChangedHashes): string =
  var res: seq[string]
  for (file, change) in self.pairs:
    res.add fmt"{file}: {change}"
  result = res.join "\n"

proc main*(dirPath: seq[string]; dbName = "db.json"; genDb = false) =
  if not dirExists dbFolder:
    createDir dbFolder
  let
    dbPath = dbFolder / dbName
    dir = expandFilename dirPath[0]
  if dirPath.len == 1:
    var hashes: Hashes
    for dir in dir.walkDirRec:
      hashes[expandFilename dir] = $secureHashFile dir
    if genDb:
      writeFile dbPath, $ %* hashes
    else:
      if dbPath.fileExists:
        let lastHashes = dir.getLastHashes dbPath
        echo hashes.compare(lastHashes)
        # echo $lastHashes
  else:
    quit "Please provide just 1 parameter"

when isMainModule:
  import cligen
  dispatch(main, help = {
    "dirPath": "The path of directory to scan",
    "dbName": "The name of database (will be stored in ~/.fsmonitor/)",
    "genDb": "Regenerate the database?",
  })
