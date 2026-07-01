# DevPod Test Suite

Comprehensive test suite for dotfiles-devpods. Run from inside a devpod for full coverage.

## Quick Start

```bash
# External validation (can run anywhere)
bash -n targets/bin/bin/*

# Internal validation (run from inside devpod)
devpod-status

# Full test suite (run from inside devpod)
# Copy this file to your devpod and run each phase
```

## Phase 1: External Validation (Readonly)

Can be run from outside the pod. No modifications needed.

### 1.1 File Structure

```bash
# Check all target files exist
find /workspaces/test/dotfiles-devpods/targets -type f | wc -l
# Expected: 28

# List all files
find /workspaces/test/dotfiles-devpods/targets -type f | sort
```

**Pass criteria:** 28 files found, all paths correct.

### 1.2 Bin Scripts Exist

```bash
ls -la /workspaces/test/dotfiles-devpods/targets/bin/bin/
# Expected: devpod-setup, devpod-status, graphify-project, project-init
```

**Pass criteria:** 4 scripts present.

### 1.3 Script Permissions

```bash
ls -la /workspaces/test/dotfiles-devpods/targets/bin/bin/
# Expected: All scripts have -rwxrwxr-x (755)
```

**Pass criteria:** All 4 scripts executable.

### 1.4 Syntax Check

```bash
for f in /workspaces/test/dotfiles-devpods/targets/bin/bin/*; do
  bash -n "$f" && echo "✓ $(basename $f)" || echo "✗ $(basename $f)"
done
# Expected: All 4 pass
```

**Pass criteria:** All scripts pass `bash -n`.

### 1.5 OpenCode Config

```bash
ls -la /workspaces/test/dotfiles-devpods/targets/opencode/.config/opencode/
# Expected: AGENTS.md, agents/, commands/, opencode.json, skills/, tui.json
```

**Pass criteria:** 6 items present.

### 1.6 Skills Exist

```bash
ls -la /workspaces/test/dotfiles-devpods/targets/opencode/.config/opencode/skills/
# Expected: git-master/, tdd-workflow/
```

**Pass criteria:** 2 skills present.

### 1.7 Commands Exist

```bash
ls -la /workspaces/test/dotfiles-devpods/targets/opencode/.config/opencode/commands/
# Expected: git-review.md, git-status.md, ulw-loop.md
```

**Pass criteria:** 3 commands present.

### 1.8 Stow Dry-Run

```bash
mkdir -p /tmp/test-stow
cd /workspaces/test/dotfiles-devpods/targets
stow --target=/tmp/test-stow -v --no bin nvim opencode tmux 2>&1 | grep "LINK:"
rm -rf /tmp/test-stow
# Expected: LINK: bin, .config/nvim, .config/opencode, .tmux.conf
```

**Pass criteria:** All targets linked.

---

## Phase 2: Internal Validation (Full)

Run from inside a devpod with all tools installed.

### Prerequisites

```bash
# Check all tools are installed
which nvim tmux opencode graphify stow git
# Expected: All found
```

### 2.1 Docker Socket

```bash
ls -la /var/run/docker.sock
# Expected: Exists and accessible
```

**Pass criteria:** Docker socket exists.

### 2.2 Tools Installed

```bash
echo "=== Tool Check ===" && \
echo -n "nvim: " && nvim --version | head -1 && \
echo -n "tmux: " && tmux -V && \
echo -n "opencode: " && opencode --version && \
echo -n "graphify: " && graphify --version && \
echo -n "stow: " && stow --version | head -1 && \
echo -n "git: " && git --version
```

**Pass criteria:** All tools report versions.

### 2.3 devpod-status

```bash
devpod-status
# Expected: Shows SSH, GPG, Git, Nvim, Tmux, OpenCode, Docker sections
# Expected: Summary with pass/warn/fail counts
```

**Pass criteria:** Exit code 0, all sections present.

### 2.4 devpod-setup

```bash
devpod-setup
# Expected: Runs install.sh, TPM, graphify init
# Expected: All tasks complete without errors
```

**Pass criteria:** Exit code 0, "Setup complete!" message.

### 2.5 graphify-project

```bash
cd /tmp
rm -rf test-graphify
mkdir test-graphify && cd test-graphify
git init
graphify-project
# Expected: Graph built, hooks installed
ls -la graphify-out/
cat .git/hooks/post-commit | head -5
```

**Pass criteria:** graphify-out/ exists, post-commit hook contains graphify.

### 2.6 project-init

```bash
cd /tmp
rm -rf test-project
project-init test-project
# Expected: Directory created with git, .gitignore, AGENTS.md
ls -la /tmp/test-project/
cat /tmp/test-project/.gitignore | head -10
cat /tmp/test-project/AGENTS.md | head -10
cd /tmp/test-project && git log --oneline
```

**Pass criteria:** All files created, git initialized, initial commit exists.

### 2.7 Stow Links

```bash
# Check bin scripts are linked
ls -la ~/bin/devpod-status
ls -la ~/bin/devpod-setup
ls -la ~/bin/graphify-project
ls -la ~/bin/project-init
# Expected: All are symlinks to targets/bin/bin/
```

**Pass criteria:** All 4 scripts are symlinks.

### 2.8 Git Config

```bash
git config --global user.name
git config --global user.email
git config --global commit.gpgsign
# Expected: Values set
```

**Pass criteria:** user.name, user.email, commit.gpgsign all set.

### 2.9 SSH Keys

```bash
ls -la ~/.ssh/
cat ~/.ssh/config
# Expected: Keys present, config file exists
```

**Pass criteria:** SSH keys and config present.

### 2.10 GPG Keys

```bash
gpg --list-keys
# Expected: Keys listed
```

**Pass criteria:** GPG keys present.

### 2.11 Nvim Version

```bash
nvim --version | head -1
# Expected: NVIM v0.12+ or stable
```

**Pass criteria:** Nvim installed and version reported.

### 2.12 Tmux Version

```bash
tmux -V
# Expected: tmux 3.x
```

**Pass criteria:** Tmux installed and version reported.

---

## Phase 3: Interactive Validation (Manual)

Require opencode/tmux running. Test interactively.

### 3.1 /git-status Command

1. Open opencode in a git repo
2. Type: `/git-status`
3. Expected: Shows branches, dirty state, recent commits

**Pass criteria:** Git state summary displayed.

### 3.2 /git-review Command

1. Make some changes to files
2. Open opencode
3. Type: `/git-review`
4. Expected: Reviews uncommitted changes, provides suggestions

**Pass criteria:** Code review output shown.

### 3.3 git-master Skill

1. Open opencode
2. Type: "commit these changes"
3. Expected: Git-master skill loads, detects commit style

**Pass criteria:** Skill activates, provides commit guidance.

### 3.4 tdd-workflow Skill

1. Open opencode
2. Type: "write tests first for this feature"
3. Expected: TDD workflow skill loads, guides red-green-refactor

**Pass criteria:** Skill activates, provides TDD guidance.

### 3.5 explorer Agent

1. Open opencode
2. Type: "show me the codebase structure"
3. Expected: Explorer agent uses graphify to show structure

**Pass criteria:** Agent responds with codebase overview.

### 3.6 ulw-loop Command

1. Open opencode
2. Type: `/ulw-loop fix the failing tests`
3. Expected: Autonomous loop starts, works until done

**Pass criteria:** Loop executes, shows progress.

### 3.7 Tmux Session

```bash
tmux new -s test-session
# Expected: New session created
tmux list-sessions
# Expected: test-session listed
tmux kill-session -t test-session
```

**Pass criteria:** Session created and listed.

### 3.8 Tmux Resurrect

```bash
# In tmux:
# Press prefix + Ctrl-s to save
# Kill session
# Press prefix + Ctrl-r to restore
# Expected: Session restored
```

**Pass criteria:** Session state preserved and restored.

---

## Test Results Template

Copy this and fill in after running tests:

```markdown
## Test Results

| Phase | Date | Pass | Fail | Warn | Notes |
|-------|------|------|------|------|-------|
| External | YYYY-MM-DD | /8 | /8 | /8 | |
| Internal | YYYY-MM-DD | /12 | /12 | /12 | |
| Interactive | YYYY-MM-DD | /8 | /8 | /8 | |

### Issues Found
- [ ] Issue 1: Description
- [ ] Issue 2: Description

### Fixes Applied
- [ ] Fix 1: Description
- [ ] Fix 2: Description
```

---

## Troubleshooting

### GPG Signing Fails

```bash
# Error: gpg: failed to create temporary file
# Fix: Check gnupg directory mount
ls -la /home/vscode/.gnupg/
# If read-only, remount or disable gpgsign
git config --global commit.gpgsign false
```

### Docker Socket Not Found

```bash
# Error: Docker socket not found
# Fix: Check devcontainer.json mounts
cat .devcontainer.json | grep mounts
# Should include: "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
```

### Graphify Not Installed

```bash
# Error: graphify not installed
# Fix: Install via uv
uv tool install graphifyy
```

### Stow Fails

```bash
# Error: stow: target directory not found
# Fix: Ensure ~/bin exists and is in PATH
mkdir -p ~/bin
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Tmux TPM Missing

```bash
# Error: TPM not installed
# Fix: Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins
```

### Scripts Not Found

```bash
# Error: command not found: devpod-status
# Fix: Ensure ~/bin is in PATH and scripts are linked
echo $PATH | grep -q "$HOME/bin" || echo "Add ~/bin to PATH"
ls -la ~/bin/ | grep devpod
```

---

## Integration with WORKSPACE

This test suite complements:
- `/workspaces/test/TESTS.md` - Original test instructions
- `devpods-builds/` - Image build verification
- `dotfiles-devpods/` - Scripts and config testing

For CI/CD integration, run Phase 1 tests in GitHub Actions.
