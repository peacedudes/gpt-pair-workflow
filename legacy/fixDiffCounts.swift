#!/usr/bin/env swift
import Foundation

// fixDiffCounts.swift — Recompute unified-diff hunk lengths and ensure a trailing newline.
// Usage examples:
//   fixDiffCounts.swift < patch.diff > patch.fixed.diff
//   fixDiffCounts.swift -f patch.diff > patch.fixed.diff
//   fixDiffCounts.swift -f patch.diff -o           # overwrite file
//   fixDiffCounts.swift --check -f patch.diff      # verify only, exit 1 if mismatches
//   fixDiffCounts.swift -v < patch.diff > /dev/null

struct Config {
    var filePath: String? = nil      // -f, --file
    var overwrite: Bool = false      // -o, --overwrite (requires --file)
    var checkOnly: Bool = false      // -c, --check
    var verbose: Bool = false        // -v, --verbose
}

func usage(_ code: Int32 = 2) -> Never {
    let prog = (CommandLine.arguments.first as NSString?)?.lastPathComponent ?? "fixDiffCounts.swift"
    let msg = """
    Usage:
      \(prog) [options]              # reads stdin, writes stdout (fixed)
      \(prog) -f <file> [options]    # reads from file

    Options:
      -f, --file <path>    Read from file instead of stdin
      -o, --overwrite      Overwrite the input file (requires --file)
      -c, --check          Verify counts only (pass input through unchanged); exit 1 if mismatches
      -v, --verbose        Print notes to stderr when mismatches are detected/fixed
      -h, --help           Show this help

    Notes:
      - Default mode fixes hunk counts and ensures a trailing newline.
      - In --check mode, content is NOT modified; the tool streams input and exits 0/1.
      - Only unified diff hunk lengths are changed; all other bytes are preserved.
    """
    FileHandle.standardError.write(Data((msg + "\n").utf8))
    exit(code)
}

func parseArgs() -> Config {
    var cfg = Config()
    var it = CommandLine.arguments.dropFirst().makeIterator()
    while let a = it.next() {
        switch a {
        case "-h", "--help":
            usage(0)
        case "-f", "--file":
            guard let p = it.next() else { usage() }
            cfg.filePath = p
        case "-o", "--overwrite":
            cfg.overwrite = true
        case "-c", "--check":
            cfg.checkOnly = true
        case "-v", "--verbose":
            cfg.verbose = true
        default:
            if cfg.filePath == nil && !a.hasPrefix("-") {
                cfg.filePath = a
            } else {
                usage()
            }
        }
    }
    if cfg.overwrite && cfg.filePath == nil { usage() }
    return cfg
}

let cfg = parseArgs()

// Read input as UTF-8 and normalize to LF.
let inputData: Data
do {
    if let path = cfg.filePath {
        inputData = try Data(contentsOf: URL(fileURLWithPath: path))
    } else {
        inputData = FileHandle.standardInput.readDataToEndOfFile()
    }
} catch {
    FileHandle.standardError.write(Data("IO error reading input: \(error)\n".utf8))
    exit(2)
}

guard var input = String(data: inputData, encoding: .utf8) else {
    FileHandle.standardError.write(Data("Input is not valid UTF-8\n".utf8))
    exit(2)
}
input = input.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")

// Regex for hunk headers: @@ -old(,len)? +new(,len)? @@(tail)
let hdrRegex = try! NSRegularExpression(
    pattern: #"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)$"#,
    options: [.anchorsMatchLines]
)

func parseHeader(_ line: String) -> (oldStart: Int, oldLen: Int?, newStart: Int, newLen: Int?, tail: String)? {
    let range = NSRange(line.startIndex..<line.endIndex, in: line)
    guard let m = hdrRegex.firstMatch(in: line, options: [], range: range) else { return nil }
    func group(_ i: Int) -> String? {
        guard let r = Range(m.range(at: i), in: line) else { return nil }
        return String(line[r])
    }
    let oldStart = Int(group(1)!)!
    let oldLen = group(2).flatMap(Int.init)
    let newStart = Int(group(3)!)!
    let newLen = group(4).flatMap(Int.init)
    let tail = group(5) ?? ""
    return (oldStart, oldLen, newStart, newLen, tail)
}

func counts(for body: [String]) -> (oldLen: Int, newLen: Int, c: Int, d: Int, a: Int) {
    var c = 0, d = 0, a = 0
    for line in body {
        guard let ch = line.first else {
            // Strict unified diffs shouldn’t have unprefixed blank lines; treat as context to be lenient
            c += 1
            continue
        }
        switch ch {
        case " ": c += 1
        case "-": d += 1
        case "+": a += 1
        case "\\": break // "\ No newline at end of file"
        default: c += 1  // be forgiving
        }
    }
    return (c + d, c + a, c, d, a)
}

// Process input line-by-line
let lines = input.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
var out = String(); out.reserveCapacity(input.count + 128)

var inHunk = false
var headerLineOpt: String? = nil
var header: (oldStart: Int, oldLen: Int?, newStart: Int, newLen: Int?, tail: String)? = nil
var body: [String] = []
var hadMismatch = false
var fixedHunks = 0

func flushHunk(into out: inout String, checkOnly: Bool, verbose: Bool) {
    guard inHunk, let hdrLine = headerLineOpt, let h = header else { return }
    let k = counts(for: body)
    let oldLenNew = k.oldLen
    let newLenNew = k.newLen
    let oldLenOld = h.oldLen
    let newLenOld = h.newLen

    let needsFix = (oldLenOld ?? -1) != oldLenNew || (newLenOld ?? -1) != newLenNew
    if needsFix { hadMismatch = true }

    if checkOnly {
        out += hdrLine + "\n"
    } else {
        if needsFix {
            fixedHunks += 1
            if verbose {
                let msg = "fixDiffCounts: corrected hunk @@ -\(h.oldStart),\(oldLenOld ?? -1) +\(h.newStart),\(newLenOld ?? -1) to @@ -\(h.oldStart),\(oldLenNew) +\(h.newStart),\(newLenNew)\n"
                FileHandle.standardError.write(Data(msg.utf8))
            }
            out += "@@ -\(h.oldStart),\(oldLenNew) +\(h.newStart),\(newLenNew) @@\(h.tail)\n"
        } else {
            out += hdrLine + "\n"
        }
    }
    for line in body { out += line + "\n" }
    // reset
    inHunk = false
    headerLineOpt = nil
    header = nil
    body.removeAll(keepingCapacity: true)
}

for line in lines {
    if let h = parseHeader(line) {
        flushHunk(into: &out, checkOnly: cfg.checkOnly, verbose: cfg.verbose)
        inHunk = true
        headerLineOpt = line
        header = h
        continue
    }
    if inHunk {
        if line.hasPrefix("@@ ") || line.hasPrefix("diff ") || line.hasPrefix("--- ") || line.hasPrefix("+++ ") {
            flushHunk(into: &out, checkOnly: cfg.checkOnly, verbose: cfg.verbose)
            out += line + "\n"
        } else {
            body.append(line)
        }
    } else {
        out += line + "\n"
    }
}
flushHunk(into: &out, checkOnly: cfg.checkOnly, verbose: cfg.verbose)

// Ensure exactly one trailing newline
if !out.hasSuffix("\n") { out += "\n" }

// Write output
do {
    if cfg.overwrite {
        guard let path = cfg.filePath else {
            FileHandle.standardError.write(Data("Error: --overwrite requires --file\n".utf8))
            exit(2)
        }
        try out.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
    } else {
        FileHandle.standardOutput.write(Data(out.utf8))
    }
} catch {
    FileHandle.standardError.write(Data("IO error writing output: \(error)\n".utf8))
    exit(2)
}

// Exit codes
if cfg.checkOnly {
    if hadMismatch {
        if cfg.verbose {
            FileHandle.standardError.write(Data("fixDiffCounts: check failed — hunk length mismatch detected.\n".utf8))
        }
        exit(1)
    } else {
        if cfg.verbose {
            FileHandle.standardError.write(Data("fixDiffCounts: check OK — all hunk lengths consistent.\n".utf8))
        }
        exit(0)
    }
} else {
    if cfg.verbose {
        FileHandle.standardError.write(Data("fixDiffCounts: fixed hunks: \(fixedHunks)\n".utf8))
    }
    exit(0)
}

