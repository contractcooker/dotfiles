
## Windows-Specific

On Windows, the Edit tool may fail with "unexpectedly modified" errors due to CRLF line endings. Workarounds:
- Use `sed -i '<line>s/.../.../' <file>` for single-line changes
- Use bash heredoc (`cat > file << 'EOF'`) to rewrite entire files
- Use PowerShell scripts for complex .ps1 edits when escaping is difficult
