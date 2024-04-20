{ config
, desktop
, hostname
, inputs
, lib
, pkgs
, outputs
, stateVersion
, username
, ...
}:

let
  # Get system kind
  inherit (pkgs.stdenv) isDarwin;

  # Precompute predicates
  isInstall = builtins.substring 0 4 hostname != "iso-";
  isWorkstation = !builtins.isNull desktop;
  p10kPath = ".config/zsh/.p10k.zsh";
in
{
  imports = [
    # Modules
    inputs.sops.homeManagerModules.sops
  ]
  # Load custom user definition if it exists
  ++ lib.optional (builtins.pathExists (./. + "/${username}")) ./${username}
  # Configure desktop if workstation
  ++ lib.optional isWorkstation ./common/desktop;

  # Configure editorconfig (https://editorconfig.org/)
  editorconfig = {
    enable = true;

    settings = {
      "*" = {
        charset = "utf-8";
        indent_style = "space";
        indent_size = 2;
        insert_final_newline = true;
        trim_trailing_whitespace = true;
        end_of_line = "lf";
        max_line_width = 140;
      };
    };
  };

  home = {
    inherit stateVersion;
    inherit username;

    # Disable mismatched home-manager/nixpkgs versions warning message
    enableNixpkgsReleaseCheck = false;

    # Write files
    file.${p10kPath}.source = ./common/configs/.p10k.zsh;

    # Set user home directory
    homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";

    # Modern Unix experience
    # https://github.com/ibraheemdev/modern-unix
    packages = with pkgs; [
      bottom # top replacement
      catppuccin-alacritty # catppuccin theme for alacritty
      catppuccin-delta # catppuccin theme for delta
      fastfetch # system info
      glow # markdown renderer
      magic-wormhole-rs # secure file transfer
      meslo-lgs-nf # Meslo Nerd Font patched for Powerlevel10k
      nixpkgs-review # Nix code review
      nurl # Nix URL fetcher
      onefetch # git project info
      tldr # cheatsheet for console commands
      unzip # ZIP extractor
      yq # YAML processor
      zsh-powerlevel10k # ZSH theme
    ];
  };

  # Workaround home-manager bug with flakes
  # - https://github.com/nix-community/home-manager/issues/2033
  news.display = "silent";

  # These may seem like duplicates of nix options from nixos but it is required for non NixOS hosts
  nix = {
    # Always use latest nix version
    package = pkgs.unstable.nix;

    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # Automatically run nix store garbage collector
    gc = {
      automatic = true;
      frequency = "weekly";
      options = "--delete-older-than 7d";
    };

    settings = {
      # Deduplicate and optimise nix store
      auto-optimise-store = true;

      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";

      # Avoid unwanted garbage collection when using nix-direnv
      keep-outputs = true;
      keep-derivations = true;
    };
  };

  # These may seem like duplicates of nixpkgs options from nixos but it is required for non NixOS hosts
  nixpkgs = {
    # Configure nixpkgs instance
    config = {
      # Allow unfree packages (like vscode, terraform, …)
      allowUnfree = true;

      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      # TODO: check if really needed
      allowUnfreePredicate = _: true;
    };

    overlays = [
      # Add overlays from overlays and pkgs dir
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # Add overlays exported from other flakes
    ];
  };

  programs = {
    # Configure Alacritty (https://github.com/alacritty/alacritty)
    alacritty = {
      enable = true;
      package = pkgs.unstable.alacritty;

      # See https://alacritty.org/config-alacritty.html
      settings = {
        # Apply catppuccin theme
        import = [ "${pkgs.catppuccin-alacritty}/catppuccin-mocha.toml" ];

        # Use same scrolling history as ZSH
        scrolling.history = config.programs.zsh.history.size;

        # Save selected text to primary clipboard
        selection.save_to_clipboard = true;

        # Visual bell animation and color
        bell = {
          animation = "EaseOut";
          duration = 200;
          color = "#f38ba8"; # Catppuccin mocha red
        };

        # Different cursor styles in vi and normal mode
        cursor = {
          style = {
            shape = "Beam";
            blinking = "Always";
          };

          vi_mode_style = {
            shape = "Block";
            blinking = "Never";
          };
        };

        keyboard.bindings = [
          # Super+Alt toggles vi mode on Linux
          # Cmd+Alt toggles vi mode on Mac
          {
            key = "Alt";
            mods = if isDarwin then "Command" else "Super";
            action = "ToggleViMode";
          }
        ];

        window = {
          # Blur content behind window
          blur = true;

          # No borders nor title bar
          decorations = "None";

          # Transparency
          opacity = 0.8;

          padding = {
            x = 8;
            y = 8;
          };
        };
      };
    };

    # Configure bat (https://github.com/sharkdp/bat)
    # Override package to use unstable once https://github.com/nix-community/home-manager/pull/5301 is merged
    bat = {
      enable = true;

      config = {
        color = "always"; # Always show colors
        tabs = "2"; # Set tab width to 2 spaces
        theme = "Catppuccin Mocha"; # Use catppuccin theme
      };

      # Define custom themes
      themes = {
        # https://github.com/catppuccin/bat
        "Catppuccin Mocha" = {
          file = "themes/Catppuccin Mocha.tmTheme";

          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "bat";
            rev = "b8134f01b0ac176f1cf2a7043a5abf5a1a29457b";
            sha256 = "sha256-gzf0/Ltw8mGMsEFBTUuN33MSFtUP4xhdxfoZFntaycQ=";
          };
        };
      };
    };

    # Configure direnv (https://github.com/direnv/direnv)
    direnv = {
      enable = true;
      enableZshIntegration = true;
      package = pkgs.unstable.direnv; # Always use latest direnv

      # Enable nix-direnv (https://github.com/nix-community/nix-direnv)
      nix-direnv = {
        enable = true;
        package = pkgs.unstable.nix-direnv; # Always use latest nix-direnv
      };
    };

    # Configure eza (https://github.com/eza-community/eza)
    eza = {
      enable = true;
      enableZshIntegration = true;
      git = true; # Show git status
      icons = true; # Show icons
      package = pkgs.unstable.eza; # Always use latest eza

      extraOptions = [
        "--color=always" # Always use terminal colors
        "--group" # Show group ownership (long view)
        "--group-directories-first" # List directories before other files
        "--header" # Show header row
        "--time-style=long-iso" # Use long ISO style for date modified
        "--total-size" # Show directories size
      ];
    };

    # Configure git
    git = {
      enable = true;
      package = pkgs.unstable.git; # Always use latest git

      # Custom aliases
      aliases = {
        # Run onefetch (git project info) with "git info"
        info = "!${pkgs.onefetch}/bin/onefetch";
      };

      # Configure delta (https://github.com/dandavison/delta)
      delta = {
        enable = true;
        package = pkgs.unstable.delta; # Always use latest delta

        options = {
          blame-timestamp-format = "%Y-%m-%d %H:%M:%S"; # Remove timezone from timestamp
          features = "catppuccin-mocha"; # Enable catppuccin-mocha theme
          hyperlinks = true; # Render commit hashes, files and line numbers as hyperlinks
          line-numbers = true; # Display line numbers
          navigate = true; # Activate diff navigation
          relative-paths = true; # Output all paths relative to current directory
          side-by-side = true; # Display diffs side-by-side
          tabs = 2; # Set tab width to 2 spaces
          wrap-max-lines = "unlimited"; # Wrap lines as many times as required
        };
      };

      extraConfig = {
        diff.colorMoved = "default";
        log.abbrevCommit = true; # Show short commit SHA in logs
        merge.conflictstyle = "diff3";
        status.showUntrackedFiles = "all"; # Show all untracked files, even if under an untracked directory
      };

      # Include catppuccin delta theme
      includes = [{
        path = "${pkgs.catppuccin-delta}/catppuccin.gitconfig";
      }];
    };

    # Configure jq (https://jqlang.github.io/jq/)
    jq = {
      enable = true;
      package = pkgs.unstable.jq; # Always use latest jq
    };

    # Configure nix-index (https://github.com/nix-community/nix-index)
    nix-index = {
      enable = true;
      enableZshIntegration = true;
      package = pkgs.unstable.nix-index; # Always use latest nix-index
    };

    # Configure ZSH (https://www.zsh.org/)
    zsh = {
      enable = true;
      enableCompletion = true;
      autocd = true; # Change to directory by its name only
      autosuggestion.enable = true; # Suggest matching command from history while typing
      dotDir = ".config/zsh";
      package = pkgs.unstable.zsh; # Always use latest zsh

      # Quickly navigate to directories with ~<hash>
      # Example: ~dl navigates to the downloads directory
      dirHashes = {
        docs = "$HOME/Documents";
        dl = "$HOME/Downloads";
        mynix = "$HOME/nixstrap";
      };

      # Configure clean history
      history = {
        expireDuplicatesFirst = true; # Remove older duplicates from history
        ignoreAllDups = true; # Remove older duplicates from history
        ignoreSpace = true; # Do not save commands starting with a space
        save = 99900; # Ensure long history
        share = true; # Share history between sessions
        size = 100000; # Ensure long history
      };

      initExtra = ''
        # Do not display duplicates of a line previously found in the line editor
        setopt HIST_FIND_NO_DUPS

        # Report the status of background jobs immediately
        setopt NOTIFY

        # Load Powerlevel10k theme
        # https://github.com/romkatv/powerlevel10k
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        [[ ! -f ~/${p10kPath} ]] || source ~/${p10kPath}
      '';

      initExtraBeforeCompInit = ''
        # Enable P10K instant prompt
        # https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#instant-prompt
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '';

      # Configure OMZ (https://github.com/ohmyzsh/ohmyzsh)
      oh-my-zsh = {
        enable = true;
        package = pkgs.unstable.oh-my-zsh; # Always use latest OMZ

        # Enable OMZ plugins
        # https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
        plugins = [
          "aliases" # Aliases cheatsheet https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/aliases
          "common-aliases" # Common aliases https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/common-aliases
          "direnv" # Create direnv hook
          "git" # Git aliases https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git
          "sudo" # Prefix command with sudo by pressing ESC twice
        ]
        # Docker aliases
        ++ lib.optionals isInstall [
          "docker" # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker
          "docker-compose" # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker-compose
        ]
        # Kubernetes aliases
        ++ lib.optionals (lib.elem pkgs.kubectl config.home.packages) [
          "kubectl" # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/kubectl
          "kubectx" # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/kubectx
        ]
        # Helm aliases https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/helm
        ++ lib.optional (lib.elem pkgs.helm config.home.packages) "helm";
      };

      shellAliases = {
        # Use pkgs.unstable once https://github.com/nix-community/home-manager/pull/5301 is merged
        cat = "${pkgs.bat}/bin/bat";
        diff = "${pkgs.unstable.delta}/bin/delta";
        ls = "${pkgs.unstable.eza}/bin/eza";
        uncolor = "sed 's,\x1B\[[0-9;]*[a-zA-Z],,g'";
      };
    };
  };
}
