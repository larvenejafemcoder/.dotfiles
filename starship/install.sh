#!/usr/bin/env bash
set -e

echo "Installing Starship..."
n=5

for ((i = 1; i <= n; i++)); do
  echo " $i"
done

curl -sS https://starship.rs/install.sh | sh -s -- -y

echo "Starship installed. Creating config..."

mkdir -p "$HOME/.config"

cat >"$HOME/.config/starship.toml" <<'EOF'
"$schema" = 'https://starship.rs/config-schema.json'

add_newline = true

[character]
success_symbol = '[➜](bold green)'

[package]
disabled = true
EOF

echo "Detecting shell..."

SHELL_NAME=$(basename "$SHELL")
echo "Detected shell: $SHELL_NAME"

if command -v starship >/dev/null 2>&1; then
  echo "Initializing Starship for current session..."
  eval "$(starship init "$SHELL_NAME")"
else
  echo "Starship not found in PATH."
fi

starship preset catppuccin-powerline -o "$HOME/.config/starship.toml"

echo "Starship is now active in this session."
