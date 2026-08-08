# dotfiles

A portable, cross-OS terminal + editor setup: WezTerm, bash (with fish-style
autosuggestions), Starship, atuin, and Neovim. One git repo syncs the same
experience across home, work, and laptop — Linux, macOS, or Windows (WSL).

## Components

| Thing            | Config             | What it gives you                       |
|------------------|--------------------|-----------------------------------------|
| Terminal         | `wezterm.lua`      | Window: fonts, truecolor, tabs, OSC-52  |
| Shell            | `shell/.bashrc`    | ble.sh autosuggestions, aliases, completion |
| Prompt           | `starship.toml`    | Same pretty prompt on every shell/OS    |
| History          | (`atuin`, via .bashrc) | fuzzy ctrl-r, replaces bash history |
| Editor          | `nvim/`              | Neovim: Catppuccin, Treesitter, explorer |
| Multiplexer     | `tmux.conf`         | Persistent, reattachable agent sessions |

## Layout

```
├── bin/install.sh      WSL/macOS/Linux-aware installer
├── wezterm.lua
├── shell/.bashrc
├── starship.toml
├── tmux.conf
└── nvim/               entire nvim config (symlinked)
```

## Quick start

```sh
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./bin/install.sh          # symlink configs (safe)
./bin/install.sh --all    # also installs tools
```

It never overwrites existing files — existing paths are skipped with a notice.

## Long-running agent sessions (tmux)

Run your orchestrator in its own tmux window so it persists and can be
reattached from any machine:

```sh
tmux new -s cmd -n agent 'opencode'   # dedicated agent window
tmux attach                           # reattach later (from anywhere)
```

Prefix is `Ctrl-a` (see `tmux.conf`).

## Windows / WSL

Recommend installing the Windows Side of things:

1. **WSL2** — `wsl --install -d Ubuntu` (or ArchWSL for Arch).
2. **WezTerm on Windows** — install from https://wezfurlong.org/wezterm
   (config still lives at `%USERPROFILE%\.config\wezterm\wezterm.lua`).
3. Run `bin/install.sh` **inside** the WSL distro. Symlinks point at nvim,
   `.bashrc`, and Starship from the Linux side, so they work identically.

## Manual install: bash autosuggestions (ble.sh)

```sh
curl -fsSL https://raw.githubusercontent.com/akinomyoga/ble.sh/master/install.sh | bash
```

## Fonts

Install a Nerd Font (e.g. **JetBrainsMono Nerd Font**) on each OS so icons in
the prompt and nvim render instead of showing as boxes.

## Always-on agent (opencode + Ollama + Tailscale)

Turn this machine into an always-on coding agent you can reach from a laptop or
phone. The agent runs here (where the code lives); other devices just connect.

```sh
./bin/setup-agent.sh            # installs opencode + Ollama, writes config + password
./bin/agent.sh start            # build + run the opencode web server in the background
ollama pull qwen3:14b           # local model = works offline (no internet needed)
./bin/agent.sh status           # logs
```

- **Offline**: run opencode against a local Ollama model so the agent works with
  zero internet.
- **Remote (Tailscale)**: run setup with `--serve-http`, install Tailscale on
  laptop/phone, then open `http://<this-machine-tailscale-ip>:4096` (user
  `opencode`, password in `~/.config/opencode/agent.env`, chmod 600).
- **Headless jobs / cron**: `./bin/agent-job.sh "<task>" --dir <project>` runs a
  one-shot opencode task non-interactively (see its header for cron examples).
- **systemd**: on non-WSL Linux, setup can install an `opencode-agent` service
  so it auto-starts. Under WSL, use `bin/agent.sh start` (nohup) or enable
  systemd in `/etc/wsl.conf`.

Keep the server password secret and never open opencode/Ollama ports to the
public internet; only expose them via your Tailscale tailnet.