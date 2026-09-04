# ai/ — agent configuration

Portable config for Claude Code and Claude Desktop, on the same footing as the
shell and editor configs in the rest of this repo.

```
ai/
├── mcp/servers.json       source of truth for MCP servers (${VAR} placeholders)
├── mcp/mcp.env.example    template for the untracked, machine-local values
├── render.sh              merge servers.json into each client's config
├── lib/render_mcp.py      the substitution + merge itself
└── claude/
    ├── settings.json      → ~/.claude/settings.json   (symlinked)
    ├── commands/          → ~/.claude/commands/       (symlinked)
    └── CLAUDE.md          → ~/.claude/CLAUDE.md       (symlinked)
```

## Why MCP servers are rendered, not symlinked

The other configs in this repo are symlinked. MCP configs can't be, for two
reasons:

**The client config files are shared with machine state.** Claude Desktop keeps
`preferences` — account ids, trusted folders, window layout — in the same JSON
file as `mcpServers`. `~/.claude.json` is mostly session history across a
hundred projects. Replacing either file wholesale would throw that away, so
`render.sh` merges into the `mcpServers` key and leaves every other key alone.

**Server definitions contain absolute machine paths.** The `uv` binary is under
`AppData\Local\Microsoft\WinGet` here and `~/.local/bin` on a Linux box. The
tracked template holds `${UV_BIN}`; the real value lives in an untracked file.

## Setup on a new machine

```sh
cp ai/mcp/mcp.env.example ~/.config/dotfiles/mcp.env
chmod 600 ~/.config/dotfiles/mcp.env
$EDITOR ~/.config/dotfiles/mcp.env     # set OBSIDIAN_VAULT_PATH at minimum
./ai/render.sh --list                  # check detected paths
./ai/render.sh --dry-run               # read the diff
./ai/render.sh
```

`bin/install.sh` offers to run the last step for you.

Quit the client app first — a running Claude Desktop can hold the config in
memory and write it back out, undoing the render. Restart it afterwards.

## Adding a server

Add it to `ai/mcp/servers.json`, using `${PLACEHOLDERS}` for anything
machine-specific, then re-run `./ai/render.sh`.

Secrets are the reason this indirection exists. A server needing a token gets:

```json
"github": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}" }
}
```

with the real token only in `~/.config/dotfiles/mcp.env`. An unset placeholder
is a hard error — the renderer will not write an empty string and hand you a
config that fails silently at launch.

## Notes

- `render.sh` never deletes servers it doesn't know about. Pass `--prune` to
  make the repo authoritative and drop anything added ad hoc.
- Every write is backed up to `<config>.json.bak.<timestamp>` first.
- Under WSL, POSIX paths in `mcp.env` are converted to `C:\...` for the
  Windows-side Claude Desktop config automatically. Write `/mnt/c/...` and let
  it translate.
- MCP server *source* is not vendored here. `obsidian-mcp` and `anki-mcp` come
  from the separate `mcp-local-readonly` repo, located via `${MCP_SRC_DIR}`.
