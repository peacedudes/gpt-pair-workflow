#!/usr/bin/env bash
# Recompute unified diff hunk counts (oldLen/newLen) and ensure a trailing newline.
# Usage:
#   fix-diff-counts.sh < patch.diff > patch.fixed.diff
#   fix-diff-counts.sh patch.diff > patch.fixed.diff

set -euo pipefail

awk '
function flush_hunk(    oldLen,newLen,i) {
  if (!in_hunk) return
  oldLen = c + d
  newLen = c + a
  # Re-emit corrected header, preserving any tail after @@
  printf("@@ -%d,%d +%d,%d @@%s\n", oldStart, oldLen, newStart, newLen, tail)
  for (i=1; i<=nb; i++) print body[i]
  # reset
  in_hunk=0; nb=0; c=0; d=0; a=0; tail=""
}

# Detect hunk header: keep optional lengths and any trailing text after @@
# Examples:
#   @@ -1,7 +1,7 @@
#   @@ -10 +10 @@ func something
function is_hunk_header(s,   m) {
  return match(s, /^@@ -([0-9]+)(,([0-9]+))? \+([0-9]+)(,([0-9]+))? @@(.*)$/, m)
}

BEGIN {
  in_hunk=0; nb=0; c=0; d=0; a=0; tail=""
}

{
  line = $0

  if (is_hunk_header(line)) {
    # Starting a new hunk: flush the previous one first
    flush_hunk()
    oldStart = 0 + substr(line, RSTART+4, RLENGTH) # placeholder; we parse from match() array below
    # match() already filled m[]
    # Extract start numbers from the last match() in is_hunk_header via the builtin arrays
    # Re-run match here to get m[] in this scope
    match(line, /^@@ -([0-9]+)(,([0-9]+))? \+([0-9]+)(,([0-9]+))? @@(.*)$/, m)
    oldStart = m[1]+0
    newStart = m[4]+0
    tail     = m[7]
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
    else if (first == "\\") { /* do not count */ }
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

