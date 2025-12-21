# GitHub Configuration

Git and GitHub CLI configuration for development workflow.

## Git Global Config

Git identity is configured automatically by the setup scripts using values from `config/identity.json`:

```bash
# These are set automatically from config/identity.json
git config --global user.name "<name>"
git config --global user.email "<email>"

# Default branch name
git config --global init.defaultBranch main

# Line endings
# macOS/Linux: input = convert CRLF to LF on commit, leave LF alone
git config --global core.autocrlf input

# Windows: true = convert LF to CRLF on checkout, CRLF to LF on commit
git config --global core.autocrlf true
```

## GitHub CLI (gh)

Installed via Homebrew/winget (see setup scripts). Configured with:
- **Protocol**: SSH (uses 1Password SSH agent - see ssh-strategy.md)

### Setup

```bash
# Install (macOS)
brew install gh

# Install (Windows)
winget install GitHub.cli

# Authenticate (opens browser, select SSH protocol)
gh auth login --web --git-protocol ssh

# Verify
gh auth status
```

### Common Commands

```bash
# Clone a repo
gh repo clone owner/repo

# Create a repo (use gh-create script for standard settings)
gh repo create my-repo --private

# Create PR
gh pr create --title "Title" --body "Description"

# View PR
gh pr view 123
```

## Repository Settings

Standard settings for personal repos (applied by `gh-create` script):

- **Default branch**: main
- **Visibility**: Private
- **Wiki**: Disabled
- **Projects**: Disabled
- **Discussions**: Disabled
- **Issues**: Enabled

## Creating New Repos

Use the `gh-create` script from dotfiles:

```bash
# From the new repo root after initial commit:
gh-create <repo-name> "Description"
```

This will:
1. Create private GitHub repo with standard settings
2. Push the current directory
3. Add entry to `config/repos.json`
4. Commit and push the manifest update

## References

- [GitHub CLI Manual](https://cli.github.com/manual/)
- [Git Config Documentation](https://git-scm.com/docs/git-config)
- [ssh-strategy.md](./ssh-strategy.md) - SSH key management with 1Password
