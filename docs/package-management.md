# Package Management Strategy

## Decision: Homebrew

**Chosen:** Homebrew as the primary package manager for macOS.

**Date:** 2025-12-11

## Alternatives Considered

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Homebrew** | De facto macOS standard, huge community, simple Brewfile | Global installs only, can be slow | **Selected** |
| **Nix** | Reproducible, per-project envs, declarative | Steep learning curve, different mental model | Future consideration |
| **MacPorts** | Mature, stable | Declining popularity, smaller community | Not selected |
| **asdf** | Multi-version runtime management | Not a general package manager | Complement to Homebrew if needed |

## Why Homebrew

1. **Industry standard** - Nearly universal on macOS, assumed by most tutorials and documentation
2. **Simplicity** - `brew install thing` just works
3. **Brewfile support** - Declarative, version-controllable package lists
4. **Large ecosystem** - Most tools available as formulae or casks
5. **Transferable knowledge** - Commonly encountered in professional environments

## Future Considerations

- **Nix** may be worth exploring for infrastructure/homelab reproducibility
- **asdf** can be added alongside Homebrew if multi-version language runtime management is needed

## Usage

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install all packages from Brewfile
brew bundle --file=~/repos/dotfiles/Brewfile

# Check what's missing
brew bundle check --file=~/repos/dotfiles/Brewfile

# Add a new package
brew install <package>
# Then add it to Brewfile to track it
```

## References

- [Homebrew Documentation](https://docs.brew.sh/)
- [Brewfile Documentation](https://github.com/Homebrew/homebrew-bundle)
