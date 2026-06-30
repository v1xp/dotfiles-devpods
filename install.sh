#!/usr/bin/env bash

set -euo pipefail

logfile=~/.dotfiles.log

task_install_stow() {
  echo "Installing stow..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq stow
}

install_targets() {
  echo "Using dotfiles from: $(pwd)"
  cd "targets" || exit 1

  for dir in */; do
    cmd=${dir%/}
    if ! command -v "$cmd" &>/dev/null; then
      echo "Skipping $dir as it is not a command."
      continue
    fi
    echo "Stowing $cmd configuration..."

    # Remove any existing files that would conflict with stow symlinks
    while IFS= read -r -d '' f; do
      rel="${f#$dir}"
      target="$HOME/$rel"
      if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "  BACKUP: $target -> $target.stow-bak"
        mv "$target" "$target.stow-bak"
      fi
    done < <(find "$dir" -type f -print0)

    stow --target="$HOME" -v "$dir"
  done
  wait
}

task_stow() {
  echo "Checking for stow..."
  if ! command -v stow &>/dev/null; then
    task_install_stow
  else
    echo "stow is already installed."
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
    if [ -d "$p" ] && [ -f "$p/id_ed25519" ]; then
      ssh_host="$p"
      break
    fi
  done

  if [ -n "$ssh_host" ]; then
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    cp "$ssh_host"/id_* "$HOME/.ssh/" 2>/dev/null || true
    cp "$ssh_host"/known_hosts "$HOME/.ssh/" 2>/dev/null || true
    chmod 600 "$HOME"/.ssh/id_* 2>/dev/null || true
    cat >"$HOME/.ssh/config" <<'SSHEOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
SSHEOF
    chmod 600 "$HOME/.ssh/config"
    echo "SSH keys copied from $ssh_host"
  else
    echo "No ssh-host mount found, skipping SSH setup"
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
    if ! grep -q "default-key" "$gnupg_dir/gpg.conf" 2>/dev/null; then
      echo "default-key 3B54C1D66B135A28494341A812CC6254259BFE53" >>"$gnupg_dir/gpg.conf"
      echo "GPG default key set in $gnupg_dir/gpg.conf"
    fi
    # Allow loopback pinentry for headless environments (devcontainer)
    if ! grep -q "allow-loopback-pinentry" "$gnupg_dir/gpg-agent.conf" 2>/dev/null; then
      echo "allow-loopback-pinentry" >>"$gnupg_dir/gpg-agent.conf"
      gpg-connect-agent reloadagent /bye 2>/dev/null || true
      echo "GPG agent configured for loopback pinentry"
    fi
  fi
}

first_inits() {
  sudo ln -sf /usr/share/zoneinfo/America/Campo_Grande /etc/localtime
  command -v nvim >/dev/null 2>&1 && nohup nvim --headless "+Lazy! sync" +TSUpdateSync +qa >$logfile 2>&1
}

task_main() {
  task_stow &
  task_git &
  task_ssh &
  task_gpg &
  wait
  first_inits
}

task_main
