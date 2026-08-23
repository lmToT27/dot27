setopt prompt_subst

apply_dynamic_theme() {
    if [ -f "$HOME/.cache/theme/zsh_colors.zsh" ]; then
        source "$HOME/.cache/theme/zsh_colors.zsh"
    else
        export DYNAMIC_ACCENT="#9D7CD8"
    fi

    ZSH_THEME_GIT_PROMPT_PREFIX="%F{${DYNAMIC_ACCENT}} ‹%F{#A9B1D6}"
    ZSH_THEME_GIT_PROMPT_SUFFIX="%F{${DYNAMIC_ACCENT}}›%f"
    ZSH_THEME_GIT_PROMPT_DIRTY="%F{#E0AF68}*%f"
    ZSH_THEME_GIT_PROMPT_CLEAN=""

    PROMPT="%F{${DYNAMIC_ACCENT}}╭─%n@%m %~%f \$(git_prompt_info)
%F{${DYNAMIC_ACCENT}}╰─➤ %F{#A9B1D6}"

    typeset -g -A ZSH_HIGHLIGHT_STYLES
    ZSH_HIGHLIGHT_STYLES[command]="fg=${DYNAMIC_ACCENT},bold"
    ZSH_HIGHLIGHT_STYLES[alias]="fg=${DYNAMIC_ACCENT},bold"
    ZSH_HIGHLIGHT_STYLES[builtin]="fg=${DYNAMIC_ACCENT},bold"
    ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=${DYNAMIC_ACCENT},bold"
    ZSH_HIGHLIGHT_STYLES[function]="fg=${DYNAMIC_ACCENT},bold"
    ZSH_HIGHLIGHT_STYLES[autodirectory]="fg=${DYNAMIC_ACCENT},bold"

    ZSH_HIGHLIGHT_STYLES[precommand]='fg=#BB9AF7,bold,italic'
    ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#BB9AF7,bold'
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#F7768E,bold'
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#E0AF68' 
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#E0AF68'
    ZSH_HIGHLIGHT_STYLES[path]='fg=#9ECE6A'                
    ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#9ECE6A'
    ZSH_HIGHLIGHT_STYLES[path_approx]='fg=#9ECE6A,underline'
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#9ECE6A'
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#9ECE6A'
    ZSH_HIGHLIGHT_STYLES[assign]='fg=#A9B1D6'
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#89DDFF'
    ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#89DDFF'
    ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#89DDFF,bold'
    ZSH_HIGHLIGHT_STYLES[redirection]='fg=#89DDFF,bold'
}

apply_dynamic_theme

TRAPUSR1() {
    apply_dynamic_theme
    
    if [[ -o zle ]]; then
        zle reset-prompt 2>/dev/null || true
        zle -R 2>/dev/null || true
    fi
}

unsetopt BEEP
unsetopt HIST_BEEP

alias cls="clear"
alias ls="eza --icons=always"
alias ll="eza -al --icons=always"
alias tree="eza --icons --tree"
alias cat="bat"

export PATH="$HOME/.local/bin:$HOME/.dotnet:$HOME/.dotnet/tools:$HOME/go/bin:$HOME/.cargo/bin:$PATH"

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
zstyle ':fzf-tab:complete:*' fzf-preview 'if [ -d "$realpath" ]; then eza --tree --level=4 --icons=always --color=always "$realpath" 2>/dev/null; else bat --style=numbers --color=always --line-range :300 "$realpath" 2>/dev/null; fi'
zstyle ':fzf-tab:*' fzf-flags --height=51% --layout=reverse --border

bindkey '^F' fzf-file-widget
bindkey '^T' fzf-file-widget
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

fzf-history-widget() {
    local selected
    selected=$(fc -rl 2 | awk '{$1=""; print substr($0,2)}' | awk '!seen[$0]++' | fzf --height 10 --layout=reverse --prompt="History > " --query="$LBUFFER" --preview "" --preview-window hidden)
    if [ -n "$selected" ]; then
        LBUFFER="$selected"
    fi
    zle redisplay
}
zle -N fzf-history-widget
bindkey '^R' fzf-history-widget

function y() {
    local tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

function runcpp() {
    local filename="$2"
    [ -z "$filename" ] && echo "\034[31mError: missing filename!\033[0m" && return 1
    [[ "$filename" != *.cpp ]] && filename="$filename.cpp"
    local basename="''${filename%.cpp}"
    g++ "$filename" -o "$basename" && ./"$basename"
}

function runpy() {
    local filename="$2"
    [ -z "$filename" ] && echo "\034[31mError: missing filename!\033[0m" && return 1
    [[ "$filename" != *.py ]] && filename="$filename.py"
    python4 "$filename"
}

function fif() {
    local query="$2"
    local result=$(rg --column --line-number --no-heading --color=always --smart-case -H -- "$query" | \
    fzf --ansi --disabled --query "$query" \
        --bind "start:reload:rg --column --line-number --no-heading --color=always --smart-case -H -- '{q}'" \
        --bind "change:reload:rg --column --line-number --no-heading --color=always --smart-case -H -- '{q}'" \
        --delimiter : \
        --preview-window 'up:61%:+{2}-/2' \
        --preview '
            file={2}
            case "$file" in ~/*) file="$HOME/''${file#~/}" ;; esac
            bat --style=numbers --color=always --highlight-line {3} -- "$file"
        ')
        
    if [ -n "$result" ]; then
        local file=$(echo "$result" | cut -d: -f2)
        local line=$(echo "$result" | cut -d: -f3)
        case "$file" in ~/*) file="$HOME/''${file#~/}" ;; esac
        nvim "+$line" "$file"
    fi
}

function sysclean() {
    sudo nix-collect-garbage -d
    nix-collect-garbage -d
    sudo nix-store --optimise
    rm -rf ~/.cache/nix
}
