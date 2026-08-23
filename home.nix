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
    thunar thunar-archive-plugin imagemagick
    kitty gh lazygit psmisc fd ripgrep yazi papirus-icon-theme
    wget fastfetch jq p7zip unrar unzip zip brightnessctl btop pavucontrol

    # --- Data Science & AI ---
    kaggle
    visidata
    ruff
    pyright
    (python3.withPackages (ps: with ps; [
      debugpy pygobject3 pip requests numpy pandas
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
    ".config/zsh".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/zsh";
  };

  # ==========================================
  # ENVIRONMENT VARIABLES
  # ==========================================
  home.sessionVariables = {
    GTK_USE_PORTAL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    DOTNET_ROOT = "${config.home.homeDirectory}/.dotnet";
    FZF_CTRL_R_OPTS = "--preview '' --preview-window hidden";
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
      historyWidget.options = [
        "--preview ''"
        "--preview-window hidden"
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

      initContent = ''
        source ~/.config/zsh/zshrc_custom.zsh
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
