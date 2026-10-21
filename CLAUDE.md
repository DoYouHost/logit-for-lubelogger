@AGENTS.md

# Claude Code only

[AGENTS.md](AGENTS.md) above is the shared set of rules every coding agent reads.
This file adds what only holds for Claude Code. Anything that is true for any agent
belongs in AGENTS.md, not here.

## Running as the GitHub Action

The shared workflow in `DoYouHost/app-shared`, called from
[.github/workflows/claude.yml](.github/workflows/claude.yml), checks the LubeLogger
server source out at `/tmp/lubelog-server-ref` before you start; read it with Read
and Grep. Do not clone it yourself (the bash sandbox has no network egress) and do
not delete it. `WebFetch` on `docs.lubelogger.com` is allowed.
