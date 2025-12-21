# Global Claude Code Settings

## Git Commits

Do not attribute commits to AI. Omit the following from commit messages:
- "Generated with Claude Code" or similar AI attribution
- "Co-Authored-By: Claude" or any AI co-author lines

## Windows-Specific

On Windows, the Edit tool may fail with "unexpectedly modified" errors due to CRLF line endings. Workarounds:
- Use `sed -i '<line>s/.../.../' <file>` for single-line changes
- Use bash heredoc (`cat > file << 'EOF'`) to rewrite entire files
- Use PowerShell scripts for complex .ps1 edits when escaping is difficult
