# Global Agent Rules

## Context-First Approach

Before making any changes to a codebase, ALWAYS:

1. Check if `graphify-out/GRAPH_REPORT.md` exists in the project root
   - If yes: read it first to understand the codebase structure
   - If no: run `graphify .` to generate the knowledge graph, then read the report
2. Use `graphify query` to explore specific parts of the codebase before editing
3. Read relevant files directly only after graphify has oriented you

## Graph Query Patterns

When exploring a codebase, use these graphify queries in order:

```
graphify query "show the main entry points" --graph graphify-out/graph.json
graphify query "show the architecture and module relationships" --graph graphify-out/graph.json
graphify query "show the data flow for [feature]" --graph graphify-out/graph.json
```

## Code Quality Standards

- Write tests BEFORE implementation (TDD)
- Keep functions small and focused (< 50 lines)
- Use meaningful variable and function names
- Never leave commented-out code in commits
- Run tests before considering any task complete

## Security

- Never commit secrets, API keys, or credentials
- Never log sensitive data
- Use environment variables for configuration
- Validate all user inputs

## Communication

- Be concise in responses
- Explain WHY you made changes, not just WHAT
- When uncertain, ask before proceeding
- Report errors clearly with context

## Git Conventions

- Use conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`
- Keep commits atomic and focused
- Write meaningful commit messages

## DevPod Environment

### Identity
- User: `vscode` (uid=1000, gid=1000)
- Home: `/home/vscode` (overlay filesystem, part of container root)
- Workspace: `/workspaces/test` (host mount at `/dev/nvme0n1p3`)

### Available Tools
- nvim (LazyVim), tmux, graphify, docker, uv, pip, lazygit, stow
- OpenCode with ralph-loop and graphify plugins
- Git with GPG signing (key: `3B54C1D66B135A28494341A812CC6254259BFE53`)

### Mounts
- Docker socket: available if devcontainer.json mounts it (check `docker info`)
- GPG keys: `/home/vscode/.gnupg` (read-only from host)
- SSH keys: `/home/vscode/.ssh-host` (read-only from host)
- Dotfiles: stowed via symlinks to `~/.local/share/dotfiles/targets/`

### Paths
- Config: `~/.config/opencode/`
- Scripts: `~/bin/` (symlinked from dotfiles)
- Graphs: `graphify-out/` in project root

### Permissions
- Read access: full system (external_directory: allow)
- Write access: prompts user
- Bash: safe commands auto-allowed (git, docker, ls, cat, grep, etc.)
- Destructive commands: prompts (rm, rm -rf, sudo)
