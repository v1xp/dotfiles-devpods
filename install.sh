#!/usr/bin/env bash

set -euo pipefail

logfile=~/.dotfiles.log

install_targets() {
  local dotfiles_dir
  dotfiles_dir="$(cd "$(dirname "$0")" && pwd)"
  echo "Using dotfiles from: $dotfiles_dir"

  # Copy dotfiles to a persistent location so symlinks survive container restarts
  local persist_dir="$HOME/.local/share/dotfiles"
  mkdir -p "$persist_dir"
  cp -a "$dotfiles_dir/." "$persist_dir/"
  echo "Dotfiles persisted to $persist_dir"

  local targets_dir="$persist_dir/targets"
  for target_dir in "$targets_dir"/*/; do
    local cmd
    cmd="$(basename "$target_dir")"
    if [[ "$cmd" != "bin" ]] && ! command -v "$cmd" &>/dev/null; then
      echo "Skipping $cmd as it is not a command."
      continue
    fi
    echo "Stowing $cmd configuration..."

    while IFS= read -r -d '' f; do
      local rel="${f#"$target_dir"}"
      local dest="$HOME/$rel"
      if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        echo "  BACKUP: $dest -> $dest.stow-bak"
        mv "$dest" "$dest.stow-bak"
      fi
    done < <(find "$target_dir" -type f -print0)

    (cd "$targets_dir" && stow --target="$HOME" -v "$cmd")
  done
}

task_stow() {
  if ! command -v stow &>/dev/null; then
    echo "stow not found, installing..."
    sudo apt-get update -qq && sudo apt-get install -y -qq stow
  fi
  install_targets
}

task_git() {
  git config --global commit.gpgsign true
  git config --global user.signingkey 3B54C1D66B135A28494341A812CC6254259BFE53
  git config --global user.email "v1xp.ccox@proton.me"
  git config --global user.name "v1XP.CCox"
}

task_ssh() {
  # In devpod containers, keys live in /home/vscode/.ssh-host (bind-mounted from host)
  # $HOME may be /home/victor due to host user, so check the hardcoded path too
  local ssh_host=""
  for p in /home/vscode/.ssh-host "$HOME/.ssh-host"; do
    if [ -d "$p" ] && ls "$p"/id_* &>/dev/null; then
      ssh_host="$p"
      break
    fi
  done

  if [ -n "$ssh_host" ]; then
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    cp "$ssh_host"/id_* "$HOME/.ssh/" 2>/dev/null || true
    cp "$ssh_host"/known_hosts "$HOME/.ssh/" 2>/dev/null || true
    chmod 600 "$HOME"/.ssh/id_* 2>/dev/null || true

    # Detect the first private key (skip *.pub files) for the SSH config
    local first_key
    first_key=$(ls "$ssh_host"/id_* 2>/dev/null | grep -v '\.pub$' | head -1)
    local key_name
    key_name=$(basename "$first_key")

    cat >"$HOME/.ssh/config" <<SSHEOF
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/${key_name}
  IdentitiesOnly yes
SSHEOF
    chmod 600 "$HOME/.ssh/config"
    echo "SSH keys copied from $ssh_host (using $key_name)"
  elif [ -n "${SSH_AUTH_SOCK:-}" ]; then
    echo "Using SSH agent forwarding (SSH_AUTH_SOCK=$SSH_AUTH_SOCK)"
    cat >"$HOME/.ssh/config" <<SSHEOF
Host github.com
  HostName github.com
  User git
  IdentityAgent $SSH_AUTH_SOCK
SSHEOF
    chmod 600 "$HOME/.ssh/config"
  else
    echo "No SSH keys found. Configure SSH agent forwarding or mount .ssh-host."
  fi
}
task_gpg() {
  local gnupg_dir=""
  for p in /home/vscode/.gnupg "$HOME/.gnupg"; do
    if [ -d "$p" ] && [ -d "$p/private-keys-v1.d" ]; then
      gnupg_dir="$p"
      break
    fi
  done

  if [ -n "$gnupg_dir" ]; then
    if ! grep -q "^default-key" "$gnupg_dir/gpg.conf" 2>/dev/null; then
      echo "default-key 3B54C1D66B135A28494341A812CC6254259BFE53" >>"$gnupg_dir/gpg.conf"
      echo "GPG default key set in $gnupg_dir/gpg.conf"
    fi
    if ! grep -q "^pinentry-mode" "$gnupg_dir/gpg.conf" 2>/dev/null; then
      echo "pinentry-mode loopback" >>"$gnupg_dir/gpg.conf"
      echo "GPG pinentry-mode set to loopback"
    fi
    if ! grep -q "allow-loopback-pinentry" "$gnupg_dir/gpg-agent.conf" 2>/dev/null; then
      echo "allow-loopback-pinentry" >>"$gnupg_dir/gpg-agent.conf"
      echo "GPG agent configured for loopback pinentry"
    fi
    gpg-connect-agent reloadagent /bye 2>/dev/null || true
  fi
}

task_opencode_plugins() {
  # Install graphify (knowledge graph for codebases)
  if command -v uv &>/dev/null; then
    if ! uv tool list 2>/dev/null | grep -q graphifyy; then
      echo "Installing graphify..."
      uv tool install graphifyy 2>/dev/null || echo "WARNING: graphify install failed"
    fi
  elif command -v pip &>/dev/null; then
    if ! pip show graphifyy &>/dev/null; then
      echo "Installing graphify via pip..."
      pip install graphifyy 2>/dev/null || echo "WARNING: graphify install failed"
    fi
  fi

  # Install graphify skill for opencode
  if command -v graphify &>/dev/null; then
    echo "Installing graphify skill for opencode..."
    graphify install opencode 2>/dev/null || echo "WARNING: graphify skill install failed"
  fi

  # Install opencode-ralph-loop plugin
  if command -v opencode &>/dev/null; then
    echo "ralph-loop plugin will be auto-installed by opencode on first run"
  fi
}

first_inits() {
  sudo ln -sf /usr/share/zoneinfo/America/Campo_Grande /etc/localtime
  nvim --headless +"set spelllang=en_us,pt_br" +qa 2>/dev/null || true
}

task_main() {
  local pids=()
  local errors=0

  task_stow &  pids+=($!)
  task_git &   pids+=($!)
  task_ssh &   pids+=($!)
  task_gpg &   pids+=($!)
  task_opencode_plugins & pids+=($!)

  for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
      echo "ERROR: Task with PID $pid failed" >&2
      errors=$((errors + 1))
    fi
  done

  if [ "$errors" -gt 0 ]; then
    echo "WARNING: $errors task(s) failed. Check log: $logfile" >&2
    return 1
  fi

  echo "All dotfiles tasks completed successfully."
  first_inits
}

task_main
