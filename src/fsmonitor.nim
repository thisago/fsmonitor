#[
  Created at: 08/27/2021 20:23:54 Friday
  Modified at: 08/27/2021 09:52:38 PM Friday
]#

from std/os import commandLineParams, walkDirRec, fileExists, expandFilename
from std/sha1 import secureHashFile, `$`
from std/tables import `[]=`, Table, pairs, hasKey, `[]`
from std/json import parseJson, `{}`, to, `%*`, `%`, `[]=`, `$`
from std/strformat import fmt
from std/strutils import join

# from std/tables import `$`, pairs

{.experimental: "codeReordering".}

type
  Hashes* = Table[string, string]
  ChangeKind* = enum
    CkCreated, CkDeleted, CkEdited
  ChangedHashes* = Table[string, ChangeKind]

proc getLastHashes(dbPath: string): Hashes =
  try:
    let json = dbPath.readFile.parseJson
    result = json.to Hashes
  except:
    quit "Error on parse DB"

proc compare(newHashes, oldHashes: Hashes): ChangedHashes =
  for (key, hash) in newHashes.pairs:
    if oldHashes.hasKey key:
      if hash != oldHashes[key]:
        result[key] = CkEdited
    else:
      result[key] = CkCreated
  for (key, hash) in oldHashes.pairs:
    if not newHashes.hasKey key:
      result[key] = CkDeleted

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

proc main*(dirPath: seq[string]; dbPath: string; genDb = false) =
  if dirPath.len == 1:
    var hashes: Hashes
    for dir in dirPath[0].walkDirRec(relative = false):
      hashes[expandFilename dir] = $secureHashFile dir
    if genDb:
      writeFile dbPath, $ %* hashes
    else:
      if dbPath.fileExists:
        let lastHashes = dbPath.getLastHashes
        echo hashes.compare(lastHashes)
  else:
    quit "Please provide just 1 parameter"

when isMainModule:
  import cligen
  dispatch(main, help = {
    "dirPath": "The path of directory to scan",
    "dbPath": "The path of database",
    "genDb": "Regenerate the database?",
  })
