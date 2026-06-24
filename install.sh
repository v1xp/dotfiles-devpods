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
  export SSH_AUTH_SOCK=~/.gnupg/socket

  git config --global commit.gpgsign true
  git config --global user.signingkey 3B54C1D66B135A28494341A812CC6254259BFE53
  git config --global user.email "v1xp.ccox@proton.me"
  git config --global user.name "v1XP.CCox"
}
first_inits() {
  command -v nvim >/dev/null 2>&1 && nohup nvim --headless "+Lazy! sync" +qa >$logfile 2>&1
  command -v nvim >/dev/null 2>&1 && nohup nvim --headless "MasonUpdate" +qa >$logfile 2>&1
}

task_main() {
  task_stow &
  task_git &
  wait
  first_inits
}

task_main
