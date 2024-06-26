export VISUAL='nvim'
export EDITOR='nvim'

# Add Rust, Go and local bin directories to PATH
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/go/bin"

# Source Cargo environment
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# Source Alacritty completions
if [ -f /opt/alacritty/extra/completions/alacritty.bash ]; then
    source /opt/alacritty/extra/completions/alacritty.bash
fi

# Set up Pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# Source custom bash aliases
if [ -f ~/aliases ]; then
    source ~/aliases
fi

# Source bash-preexec if available
if [ -f ~/.bash-preexec.sh ]; then
    source ~/.bash-preexec.sh
fi

# Initialize atuin
eval "$(atuin init bash)"

# Initialize starship
eval "$(starship init bash)"

# Initialize zoxide
eval "$(zoxide init --cmd cd bash)"

# Initialize Zellij auto-start
eval "$(zellij setup --generate-auto-start bash)"
# --layout $HOME/.config/zellij/layouts/layout.kdl