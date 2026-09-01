apply_dynamic_theme() {
    if [ -f "$HOME/.cache/theme/zsh_colors.zsh" ]; then
        source "$HOME/.cache/theme/zsh_colors.zsh"
    else
        export DYNAMIC_ACCENT="#9D7CD8"
    fi

    : "${ZSH_C_PURPLE:=#BB9AF7}" "${ZSH_C_RED:=#F7768E}" "${ZSH_C_YELLOW:=#E0AF68}"
    : "${ZSH_C_GREEN:=#9ECE6A}" "${ZSH_C_MUTED:=#A9B1D6}" "${ZSH_C_CYAN:=#7DCFFF}"

    ZSH_THEME_GIT_PROMPT_PREFIX="%F{${DYNAMIC_ACCENT}} ‹%F{${ZSH_C_MUTED}}"
    ZSH_THEME_GIT_PROMPT_SUFFIX="%F{${DYNAMIC_ACCENT}}›%f"
    ZSH_THEME_GIT_PROMPT_DIRTY="%F{${ZSH_C_YELLOW}}*%f"
    ZSH_THEME_GIT_PROMPT_CLEAN=""

    PROMPT="%F{${DYNAMIC_ACCENT}}╭─%n@%m %~%f \$(git_prompt_info)
%F{${DYNAMIC_ACCENT}}╰─➤ %F{${ZSH_C_MUTED}}"

    typeset -g -A ZSH_HIGHLIGHT_STYLES
    ZSH_HIGHLIGHT_STYLES[command]="fg=${DYNAMIC_ACCENT},bold"
    ZSH_HIGHLIGHT_STYLES[alias]="fg=${DYNAMIC_ACCENT},bold"
    ZSH_HIGHLIGHT_STYLES[builtin]="fg=${DYNAMIC_ACCENT},bold"
    ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=${DYNAMIC_ACCENT},bold"
    ZSH_HIGHLIGHT_STYLES[function]="fg=${DYNAMIC_ACCENT},bold"
    ZSH_HIGHLIGHT_STYLES[autodirectory]="fg=${DYNAMIC_ACCENT},bold"

    ZSH_HIGHLIGHT_STYLES[precommand]="fg=${ZSH_C_PURPLE},bold,italic"
    ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=${ZSH_C_PURPLE},bold"
    ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=${ZSH_C_RED},bold"
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg=${ZSH_C_YELLOW}"
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg=${ZSH_C_YELLOW}"
    ZSH_HIGHLIGHT_STYLES[path]="fg=${ZSH_C_GREEN}"
    ZSH_HIGHLIGHT_STYLES[path_prefix]="fg=${ZSH_C_GREEN}"
    ZSH_HIGHLIGHT_STYLES[path_approx]="fg=${ZSH_C_GREEN},underline"
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=${ZSH_C_GREEN}"
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=${ZSH_C_GREEN}"
    ZSH_HIGHLIGHT_STYLES[assign]="fg=${ZSH_C_MUTED}"
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]="fg=${ZSH_C_CYAN}"
    ZSH_HIGHLIGHT_STYLES[history-expansion]="fg=${ZSH_C_CYAN}"
    ZSH_HIGHLIGHT_STYLES[commandseparator]="fg=${ZSH_C_CYAN},bold"
    ZSH_HIGHLIGHT_STYLES[redirection]="fg=${ZSH_C_CYAN},bold"
}

apply_dynamic_theme

TRAPUSR1() {
    source "$HOME/.config/zsh/theme_reload.zsh"

    if [[ -o zle ]]; then
        zle reset-prompt 2>/dev/null || true
        zle -R 2>/dev/null || true
    fi
}
