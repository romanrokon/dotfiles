#!/bin/bash

# ==============================================================================
# Dual Claude Code Environment Setup (Work + Personal)
# ==============================================================================

MAIN_DIR="$HOME/.claude"
WORK_DIR="$HOME/.claude-work"
BIN_DIR="$HOME/.local/bin"
WRAPPER_SCRIPT="$BIN_DIR/claude-work.sh"
ZSHRC="$HOME/.zshrc"

echo "🚀 Setting up Dual Claude Code Environment..."

# 0. Sanity Check
if [ ! -d "$MAIN_DIR" ]; then
    echo "❌ Error: $MAIN_DIR not found."
    echo "💡 Tell it like it is: You need to run 'claude' normally at least once to initialize the main setup before running this script."
    exit 1
fi

# 1. Scaffold Directories
mkdir -p "$WORK_DIR"
mkdir -p "$BIN_DIR"
echo "✅ Directories scaffolded."

# 2. Generate VS Code Wrapper Script
cat << 'EOF' > "$WRAPPER_SCRIPT"
#!/bin/bash
export CLAUDE_CONFIG_DIR="$HOME/.claude-work"
exec claude "$@"
EOF

chmod +x "$WRAPPER_SCRIPT"
echo "✅ VS Code wrapper created at: $WRAPPER_SCRIPT"

# 3. Smart Symlinking (Shared Brain, Isolated Identities)
FILES=("settings.json" "CLAUDE.md")
DIRS=("plugins" "rules" "skills" "commands" "agents" "hooks")

echo "🔗 Linking global configs..."
for file in "${FILES[@]}"; do
    if [ -f "$MAIN_DIR/$file" ]; then
        rm -f "$WORK_DIR/$file"
        ln -s "$MAIN_DIR/$file" "$WORK_DIR/$file"
        echo "  -> Symlinked $file"
    fi
done

for dir in "${DIRS[@]}"; do
    if [ -d "$MAIN_DIR/$dir" ]; then
        rm -rf "$WORK_DIR/$dir"
        ln -s "$MAIN_DIR/$dir" "$WORK_DIR/$dir"
        echo "  -> Symlinked $dir/"
    fi
done

# 4. Inject Terminal Alias
ALIAS_STR="alias claude-work=\"CLAUDE_CONFIG_DIR=$WORK_DIR claude\""

# Create .zshrc if it somehow doesn't exist
touch "$ZSHRC"

if ! grep -q "alias claude-work" "$ZSHRC"; then
    echo -e "\n# Claude Dual Setup" >> "$ZSHRC"
    echo "$ALIAS_STR" >> "$ZSHRC"
    echo "✅ Alias 'claude-work' injected into .zshrc"
else
    echo "⚡ Alias already exists in .zshrc. Skipping."
fi

echo ""
echo "�� Setup Complete! Your next moves:"
echo "1. Run: source ~/.zshrc"
echo "2. Run: claude-work /login (to auth your work account in Keychain)"
echo "3. In your Work VS Code, set 'Claude Process Wrapper' to: $WRAPPER_SCRIPT"
