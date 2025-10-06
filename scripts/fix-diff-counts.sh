#!/usr/bin/env bash
# Recompute unified diff hunk counts (oldLen/newLen) and ensure a trailing newline.
# Usage:
#   fix-diff-counts.sh < patch.diff > patch.fixed.diff
#   fix-diff-counts.sh patch.diff > patch.fixed.diff

set -euo pipefail

awk '
function flush_hunk(    oldLen,newLen,i) { if (!in_hunk) return; oldLen = c + d
  newLen = c + a
  # Re-emit corrected header, preserving any tail after @@
  printf("@@ -%d,%d +%d,%d @@%s\n", oldStart, oldLen, newStart, newLen, tail)
  for (i=1; i<=nb; i++) print body[i]
  # reset
  in_hunk=0; nb=0; c=0; d=0; a=0; tail=""
}

BEGIN { in_hunk=0; nb=0; c=0; d=0; a=0; tail="" }

{
  line = $0

  if (substr(line,1,2)=="@@") {
    # Starting a new hunk: flush the previous one first
    flush_hunk()
    # Extract numbers in order: oldStart[,oldLen] newStart[,newLen]
    s = line
    i = 0
    while (match(s, /[0-9]+/)) {
      i++
      nums[i] = substr(s, RSTART, RLENGTH)
      s = substr(s, RSTART + RLENGTH)
    }
    oldStart = (i>=1 ? nums[1]+0 : 0)
    newStart = (i>=3 ? nums[3]+0 : (i>=2 ? nums[2]+0 : 0))
    p1 = index(line, "@@"); s2 = substr(line, p1+2); p2 = index(s2, "@@"); tail = (p2>0 ? substr(s2, p2+2) : "")
    in_hunk=1; nb=0; c=0; d=0; a=0
    next
  }

  # End of current hunk when a new header/file header begins
  if (in_hunk && (substr(line,1,2)=="@@" || substr(line,1,4)=="diff" || substr(line,1,3)=="---" || substr(line,1,3)=="+++")) {
    flush_hunk()
    print line
    next
  }

  if (in_hunk) {
    # Count by prefix; do not count the special backslash line
    first = substr(line,1,1)
    if      (first == " ") c++
    else if (first == "-") d++
    else if (first == "+") a++
    else if (first == "\\") { ; }
    # Buffer body lines verbatim
    body[++nb] = line
    next
  }

  # Pass-through for non-hunk lines
  print line
}

END {
  flush_hunk()
  # Ensure the output ends with a single newline:
  # awk print/printf end lines with LF, so no extra action needed.
  # If the input lacked a final newline inside a hunk, our reprint adds it.
}
' "${1:-/dev/stdin}"

