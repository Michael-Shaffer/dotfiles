[Unit]
Description=OpenCode agent (web server + local brain)
After=network-online.target ollama.service
Wants=network-online.target

[Service]
Type=simple
# Load the opencode server password set by bin/setup-agent.sh (0600).
EnvironmentFile=ENVFILE
# Run through bash so `opencode` is found on PATH if outside /usr/local/bin.
ExecStart=/bin/bash -lc 'source ENVFILE; exec opencode web --hostname 0.0.0.0 --port PORT'
# Local model provider (Ollama). Unused if OLLAMA_HOST not reachable.
Environment=OLLAMA_HOST=localhost:11434
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target