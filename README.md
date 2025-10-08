# GPT Pair programming

[![ShellCheck](https://github.com/peacedudes/gpt-pair-workflow/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/peacedudes/gpt-pair-workflow/actions/workflows/shellcheck.yml)

Clipboard-first workflow for collaborating with GPT on real codebases.

Requirements
- git, bash; macOS or Linux or Windows terminal. Reasonable literacy.
- Clipboard access is assumed (toClip/fromClip are provided).

How it works (at a glance)
- Run "sharefiles" in this repo and paste clipboard to the assistant to share workflow mechanics.
- Move to the local repo you'll be working with, run sharefiles and paste its snapshot to the assistant.
- Set a concrete goal or change to make.
- Iterate: the assistant requests targeted read-only “peeks” to specific code it will change, then creates a unified diff (patch); the operator applies it and runs checks.
- Repeat until the goal is complete.

Running commands safely
- In this workflow, the assistant prepares commands that you will paste directly into a terminal and run.  
- Read commands first; if anything looks unclear or risky, don’t run it.
- Commands are short and explain their purpose upfront.
- No remote code execution, nothing runs without your consent.
- You review diffs and apply them locally (applyPatch); nothing runs automatically.

What this is
- A recipe for successful GPT-assisted development using a git repo.
- Works with any plain text git repo and the system clipboard.
- Some command line skills and the ability to run scripts are required.

Problems it solves
- GPT can’t clone or push; zip file uploads don’t persist. A pasted repo snapshot does.
- Long chats develop long lag and can become unstable. Efficiently moving to a fresh AI instance is mandatory.
- GPT often makes patch files that fail with line counts off by one. Easily auto-corrected.

What this is not
- Not for private or unshareable code.
- Not tied to any specific language, framework, or toolchain.

## Privacy Warning

- Contents pasted into GPT chat become visible to the model and platform. Use only where sharing code or other text is permitted. Do not share private data like keys or passwords.  Intellectual Property should not be used without due consideration and approval.

## Disclaimer
- Provided as-is, without warranty or liability. You are responsible for what you run and what you share.
- Review and understand commands before running them. Refuse anything unclear or risky.
- Not affiliated with OpenAI or any model/provider.

Learn more
- Start with docs/00-overview.md (concepts, privacy, cadence), then docs/01-quick-start.md (scripts and step-by-step).
- See docs/02-troubleshooting.md for common issues and fixes.
- See docs/03-scripts.md for a quick reference to the helper scripts.

## License
0BSD. See LICENSE.

