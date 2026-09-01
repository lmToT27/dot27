setopt prompt_subst

source "$HOME/.config/zsh/theme_reload.zsh"

_update_dynamic_opts() {
    export FZF_DEFAULT_OPTS="--preview 'if [ -d \"{}\" ]; then eza --tree --level=4 --icons=always --color=always \"{}\" 2>/dev/null; else case \"{}\" in *.[jJ][pP][gG]|*.[jJ][pP][eE][gG]|*.[pP][nN][gG]|*.[gG][iI][fF]|*.[wW][eE][bB][pP]) chafa -f symbols -s 40x30 \"{}\" 2>/dev/null ;; *) bat --theme=\"\$BAT_THEME\" --style=numbers --color=always --line-range :300 \"{}\" 2>/dev/null ;; esac; fi' ${FZF_COLORS}"
    export FZF_CTRL_T_OPTS="$FZF_DEFAULT_OPTS"

    zstyle ':fzf-tab:complete:*' fzf-preview 'if [ -d "$realpath" ]; then eza --tree --level=4 --icons=always --color=always "$realpath" 2>/dev/null; else case "$realpath" in *.[jJ][pP][gG]|*.[jJ][pP][eE][gG]|*.[pP][nN][gG]|*.[gG][iI][fF]|*.[wW][eE][bB][pP]) chafa -f symbols -s 40x30 "$realpath" 2>/dev/null ;; *) bat --theme="$BAT_THEME" --style=numbers --color=always --line-range :300 "$realpath" 2>/dev/null ;; esac; fi'
    
    zstyle ':fzf-tab:*' fzf-flags $=FZF_COLORS --height=51% --layout=reverse --border
}

_update_dynamic_opts

TRAPUSR1() {
    apply_dynamic_theme
    _update_dynamic_opts
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
alias cat="bat --theme=\$BAT_THEME"

export PATH="$HOME/.local/bin:$HOME/.dotnet:$HOME/.dotnet/tools:$HOME/go/bin:$HOME/.cargo/bin:$PATH"

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

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
    local filename="$1"
    [ -z "$filename" ] && echo "\033[31mError: missing filename!\033[0m" && return 1
    [[ "$filename" != *.cpp ]] && filename="$filename.cpp"
    local basename="${filename%.cpp}"
    g++ "$filename" -o "$basename" && ./"$basename"
}

function runpy() {
    local filename="$1"
    [ -z "$filename" ] && echo "\033[31mError: missing filename!\033[0m" && return 1
    [[ "$filename" != *.py ]] && filename="$filename.py"
    python3 "$filename"
}

function fif() {
    local query="$1"
    local result=$(rg --column --line-number --no-heading --color=always --smart-case -H -- "$query" | \
    fzf --ansi --disabled --query "$query" \
        --bind "start:reload:rg --column --line-number --no-heading --color=always --smart-case -H -- '{q}'" \
        --bind "change:reload:rg --column --line-number --no-heading --color=always --smart-case -H -- '{q}'" \
        --delimiter : \
        --preview-window 'up:61%:+{2}-/2' \
        --preview '
            file={1}
            case "$file" in ~/*) file="$HOME/${file#~/}" ;; esac
            bat --theme="$BAT_THEME" --style=numbers --color=always --highlight-line {2} -- "$file"
        ')

    if [ -n "$result" ]; then
        local file=$(echo "$result" | cut -d: -f1)
        local line=$(echo "$result" | cut -d: -f2)
        case "$file" in ~/*) file="$HOME/${file#~/}" ;; esac
        nvim "+$line" "$file"
    fi
}

function sysclean() {
    sudo nix-collect-garbage -d
    nix-collect-garbage -d
    sudo nix-store --optimise
    rm -rf ~/.cache/nix
}
