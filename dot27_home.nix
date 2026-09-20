{ config, pkgs, inputs, ... }:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  quickshellWithQt5Compat = pkgs.symlinkJoin {
    name = "quickshell-with-qt5compat";
    paths = [ pkgs.quickshell ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/quickshell \
        --suffix QML2_IMPORT_PATH : "${pkgs.qt6.qt5compat}/lib/qt-6/qml" \
        --suffix NIXPKGS_QT6_QML_IMPORT_PATH : "${pkgs.qt6.qt5compat}/lib/qt-6/qml"
    '';
  };
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
    swaybg
    quickshellWithQt5Compat
    rofi
    rofimoji
    libnotify
    wl-clipboard
    cliphist
    grim
    slurp
    hyprpicker
    hyprlock
    wl-screenrec
    ollama
    xdg-utils
    playerctl
    mpv
    imv

    # --- CLI & System Tools ---
    claude-code chafa
    thunar thunar-archive-plugin imagemagick
    kitty gh lazygit psmisc fd ripgrep yazi papirus-icon-theme
    wget fastfetch jq p7zip unrar unzip zip brightnessctl btop pavucontrol glow

    pyright uv

    # --- C/C++ & Java Environment ---
    gcc clang-tools vscode-extensions.vadimcn.vscode-lldb
    jdk25 maven gradle jdt-language-server vscode-extensions.vscjava.vscode-java-debug

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

  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 18;
    gtk.enable = true;
    x11.enable = true;
  };

  # ==========================================
  # DOTFILES SYMLINKS
  # ==========================================
  home.file = {
    ".config/niri".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/niri";
    ".config/quickshell".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/quickshell";
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/nvim";
    ".local/bin".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/scripts";
    ".config/rofi".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/rofi";
    ".config/kitty".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/kitty";
    ".config/zsh".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/zsh";
    ".config/cava".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/cava";
    ".config/hypr/hyprlock.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dot27/dotfiles/hyprlock/hyprlock.conf";
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
    bat = {
      enable = true;
      themes.tokyonight_night.src = ./dotfiles/bat/tokyonight_night.tmTheme;
    };

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

  systemd.user.services.ollama = {
    Unit.Description = "Ollama local LLM server";
    Service = {
      ExecStart = "${pkgs.ollama}/bin/ollama serve";
      Restart = "on-failure";
      Environment = "OLLAMA_KEEP_ALIVE=0";
    };
    Install.WantedBy = [ "default.target" ];
  };

  programs.git.enable = true;

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.home-manager.enable = true;

  xdg.desktopEntries.nvim = {
    name = "Neovim";
    genericName = "Text Editor";
    exec = "kitty --title neovim nvim %F";
    terminal = false;
    icon = "nvim";
    categories = [ "Utility" "TextEditor" ];
    mimeType = [ "text/plain" ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/mpeg" = "mpv.desktop";
      "video/ogg" = "mpv.desktop";
      "text/plain" = "nvim.desktop";
      "image/png" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/bmp" = "imv.desktop";
      "image/tiff" = "imv.desktop";
      "image/svg+xml" = "imv.desktop";
    };
  };
}
