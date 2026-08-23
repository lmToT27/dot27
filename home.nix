{ config, pkgs, inputs, ... }:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.stateVersion = "26.05";
  home.enableNixpkgsReleaseCheck = false;

  imports = [ 
    inputs.spicetify-nix.homeManagerModules.default
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = (_: true);
  };

  # ==========================================
  # PACKAGES
  # ==========================================
  home.packages = with pkgs; [
    # --- Wayland & UI Core (Niri Focus) ---
    niri
    awww
    waybar
    rofi
    rofi-emoji
    swaynotificationcenter
    wlr-randr
    wl-clipboard
    cliphist
    grim
    slurp
    nwg-look
    xdg-utils
    wayland-pipewire-idle-inhibit

    # --- CLI & System Tools ---
    thunar thunar-archive-plugin
    kitty gh lazygit psmisc fd ripgrep yazi papirus-icon-theme
    wget fastfetch jq p7zip unrar unzip zip brightnessctl btop pavucontrol

    # --- Data Science & AI ---
    kaggle
    visidata
    ruff
    pyright
    (python3.withPackages (ps: with ps; [
      debugpy colorthief pygobject3 pip requests numpy pandas
      scikit-learn opencv jupyter torch torchvision ortools matplotlib seaborn
    ]))

    # --- C/C++ & Java Environment ---
    gcc clang-tools vscode-extensions.vadimcn.vscode-lldb
    jdk21 maven gradle jdt-language-server vscode-extensions.vscjava.vscode-java-debug

    # --- Apps & Browser ---
    (brave.override {
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--disable-gpu-memory-buffer-video-frames"
        "--process-per-site"
        "--gtk-version=4"
      ];
    })
    obsidian
    godot_4
    pinta
    blender
    cava
  ];

  # ==========================================
  # DOTFILES SYMLINKS
  # ==========================================
  home.file = {
    ".config/niri".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/niri";
    ".config/waybar".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/waybar";
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/nvim";
    ".local/bin".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/scripts";
    ".config/kitty".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/kitty";
  };

  # ==========================================
  # ENVIRONMENT VARIABLES
  # ==========================================
  home.sessionVariables = {
    GTK_USE_PORTAL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    DOTNET_ROOT = "${config.home.homeDirectory}/.dotnet";
  };

  # ==========================================
  # SHELL & TERMINAL TOOLS
  # ==========================================
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = false;
      defaultCommand = "fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude .vscode --color=always";
      defaultOptions = [
        "--ansi" "--layout=reverse" "--border"
        "--preview 'if [ -d {} ]; then eza --tree --level=3 --icons=always --color=always {} 2>/dev/null; else bat --style=numbers --color=always --line-range :300 {} 2>/dev/null; fi'"
        "--preview-window 'right:55%:wrap:border-left'"
      ];
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };

    eza = { enable = true; enableZshIntegration = true; icons = "auto"; };
    bat.enable = true;

    # --- ZSH MODULE ---
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      oh-my-zsh = {
        enable = true;
        theme = "lukerandall";
        plugins = [ "git" ];
      };

      plugins = [
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.plugin.zsh";
        }
      ];

      history = {
        size = 100000;
        save = 100000;
        path = "$HOME/.zsh_history";
        ignoreDups = true;
        share = true;
      };

      historySubstringSearch.enable = true;
      shellAliases = {
        cls = "clear";
        ls = "eza --icons=always";
        ll = "eza -al --icons=always";
        tree = "eza --icons --tree";
        cat = "bat";
      };

      initContent = ''
        export PATH="$HOME/.local/bin:$HOME/.dotnet:$HOME/.dotnet/tools:$HOME/go/bin:$HOME/.cargo/bin:$PATH"
        
        export AGNOSTER_DIR_BG="blue"
        export AGNOSTER_GIT_DIRTY_BG="black"
        export AGNOSTER_GIT_DIRTY_FG="white"
        export AGNOSTER_CONTEXT_BG="#010101"
        export AGNOSTER_CONTEXT_FG="blue"
        export AGNOSTER_DIR_FG="#010101"

        # Fzf-Tab Config
        zstyle ':completion:*' menu select
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':fzf-tab:complete:*' fzf-preview 'if [ -d "$realpath" ]; then eza --tree --level=3 --icons=always --color=always "$realpath" 2>/dev/null; else bat --style=numbers --color=always --line-range :300 "$realpath" 2>/dev/null; fi'
        zstyle ':fzf-tab:*' fzf-flags --height=50% --layout=reverse --border

        # Keybindings
        bindkey '^F' fzf-file-widget
        bindkey '^T' fzf-file-widget
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down

        # Fzf History Search
        fzf-history-widget() {
            local selected
            selected=$(fc -rl 1 | awk '{$1=""; print substr($0,2)}' | awk '!seen[$0]++' | fzf --height 10 --layout=reverse --prompt="History > " --query="$LBUFFER")
            if [ -n "$selected" ]; then
                LBUFFER="$selected"
            fi
            zle redisplay
        }
        zle -N fzf-history-widget
        bindkey '^R' fzf-history-widget

        # Custom Workflow Functions
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
            local basename="''${filename%.cpp}"
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
            local result=$(rg --column --line-number --no-heading --color=always --smart-case "$query" | \
            fzf --ansi --disabled --query "$query" \
                --bind "start:reload:rg --column --line-number --no-heading --color=always --smart-case {q}" \
                --bind "change:reload:rg --column --line-number --no-heading --color=always --smart-case {q}" \
                --delimiter : \
                --preview 'bat --style=numbers --color=always --highlight-line {2} {1}')
            if [ -n "$result" ]; then
                local file=$(echo "$result" | cut -d: -f1)
                local line=$(echo "$result" | cut -d: -f2)
                nvim "+$line" "$file"
            fi
        }

        function sysclean() {
            sudo nix-collect-garbage -d
            nix-collect-garbage -d
            sudo nix-store --optimise
            rm -rf ~/.cache/nix
        }
      '';
    };
  };

  # ==========================================
  # APPS & SPICETIFY
  # ==========================================
  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.sleek;
    colorScheme = "UltraBlack"; 
    
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      shuffle
      hidePodcasts
    ];

    enabledCustomApps = with spicePkgs.apps; [
      newReleases
      lyricsPlus
      ncsVisualizer
    ];
  };

  programs.git = {
    enable = true;
    settings = {
        user.name = "lmToT27";
        user.email = "168084827+lmToT27@users.noreply.github.com";
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.home-manager.enable = true;
}
