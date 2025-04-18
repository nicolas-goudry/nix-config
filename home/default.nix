{
  config,
  isInstall,
  isWorkstation,
  hostname,
  inputs,
  lib,
  pkgs,
  outputs,
  stateVersion,
  username,
  ...
}:

let
  # Get system kind
  inherit (pkgs.stdenv) isDarwin;

  p10kPath = ".config/zsh/.p10k.zsh";
in
{
  imports =
    [
      # Modules
      inputs.catppuccin.homeManagerModules.catppuccin
      inputs.impermanence.homeManagerModules.impermanence
      inputs.nix-index-database.hmModules.nix-index
      inputs.sops.homeManagerModules.sops
      inputs.stylix.homeManagerModules.stylix

      # Configure user
      ./${username}

      # Add scripts
      ./common/scripts
    ]
    # Configure host-specific settings for user if it exists
    ++ lib.optional (builtins.pathExists (
      ./. + "/${username}/${hostname}.nix"
    )) ./${username}/${hostname}.nix
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

  # Allow font discovery
  fonts.fontconfig.enable = true;

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

      # Allow insecure electron
      permittedInsecurePackages = [
        "electron-25.9.0"
      ];
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
    # Let Home Manager install and manage itself
    home-manager.enable = true;

    # Configure Ghostty (https://github.com/ghostty-org/ghostty)
    ghostty = {
      enable = true;
      enableZshIntegration = true;
      package = pkgs.unstable.ghostty;

      # Add Ghostty configuration syntax
      installBatSyntax = true;
      installVimSyntax = true;

      # See https://ghostty.org/docs/config/reference
      settings = { };
    };

    # Configure bat (https://github.com/sharkdp/bat), a modern cat replacement
    bat = {
      enable = true;
      package = pkgs.unstable.bat; # Always use latest bat

      config = {
        color = "always"; # Always show colors
        tabs = "2"; # Set tab width to 2 spaces
      };
    };

    # Configure bottom (https://github.com/ClementTsang/bottom), a modern top replacement
    bottom = {
      enable = true;
      package = pkgs.unstable.bottom; # Always use latest bottom

      settings = {
        # Catppuccin Mocha colors
        colors = {
          avg_cpu_color = "#f38ba8";
          arc_color = "#94e2d5";
          border_color = "#9399b2";
          graph_color = "#cdd6f4";
          highlighted_border_color = "#89b4fa";
          ram_color = "#f5c2e7";
          rx_color = "#89dceb";
          selected_bg_color = "#cdd6f4";
          selected_text_color = "#1e1e2e";
          swap_color = "#f9e2af";
          table_header_color = "#94e2d5";
          text_color = "#cdd6f4";
          tx_color = "#a6e3a1";
          widget_title_color = "#cdd6f4";

          # Battery widget colors
          high_battery_color = "#a6e3a1";
          medium_battery_color = "#f9e2af";
          low_battery_color = "#f38ba8";

          # Graph colors
          cpu_core_colors = [
            "#f5e0dc"
            "#f5c2e7"
            "#cba6f7"
            "#f38ba8"
            "#fab387"
            "#f9e2af"
            "#a6e3a1"
            "#89dceb"
            "#89b4fa"
            "#b4befe"
          ];
          gpu_core_colors = [
            "#cba6f7"
            "#f38ba8"
            "#fab387"
            "#f9e2af"
            "#a6e3a1"
            "#74c7ec"
            "#b4befe"
          ];
        };

        flags = {
          battery = true; # Show battery widget
          disable_click = true; # Disable mouse
          enable_gpu = true; # Show GPU memory
          expanded = true; # Expand default widget on start
          group = true; # Group processes with same name together
          hide_table_gap = true; # Remove space in tables
          left_legend = true; # Show CPU legend on left side
          mem_as_value = true; # Show processes memory as value
          show_table_scroll_position = true; # Track scroll list position
        };

        # Custom layout:
        # - two equal width columns
        # - all text widgets on left column
        # - all graph widgets on right column
        # - first column:
        #   - processus
        #   - disks
        #   - battery
        #   - temperatures
        # - second column:
        #   - cpu
        #   - memory
        #   - network
        row = [
          {
            ratio = 40;

            child = [
              {
                type = "proc";
                default = true;
              }
              {
                type = "cpu";
              }
            ];
          }
          {
            ratio = 30;

            child = [
              {
                child = [
                  {
                    type = "disk";
                  }
                  {
                    type = "batt";
                  }
                ];
              }
              {
                type = "mem";
              }
            ];
          }
          {
            ratio = 30;

            child = [
              {
                type = "temp";
              }
              {
                type = "net";
              }
            ];
          }
        ];
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

    # Configure eza (https://github.com/eza-community/eza), a modern ls replacement
    eza = {
      enable = true;
      # Disable shell aliases since they are defined by custom OMZ common-aliases plugin
      enableZshIntegration = false;
      git = true; # Show git status
      icons = "auto"; # Show icons
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
        info = "!${pkgs.onefetch}/bin/onefetch --no-title";
      };

      # Configure delta (https://github.com/dandavison/delta), a modern diff replacement
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
      includes = [
        {
          path = "${pkgs.catppuccin-delta}/catppuccin.gitconfig";
        }
      ];
    };

    # Configure GPG
    gpg = {
      enable = true;
      package = pkgs.gnupg;

      # Allow users to manage keyring and trust using gpg command
      mutableKeys = true;
      mutableTrust = true;

      # Load all hosts public keys in keyring
      publicKeys =
        # Only keep attribute set's attributes values
        lib.attrValues (
          # Returns something like '{ "g-xps.pub" = { text = "-----BEGIN PGP PUBLIC KEY BLOCK-----\n..."; }; }'
          lib.mapAttrs
            # For each public key, create an attribute set with a 'text' attribute of the file content
            (file: _type: { text = builtins.readFile ../.keys/${file}; })
            # Build attribute set of all public keys in .keys directory
            (
              lib.filterAttrs
                # Only keep top-level regular files ending in '.pub'
                (file: type: type == "regular" && lib.hasSuffix ".pub" file)
                # Read .keys directory
                # Returns something like '{ "g-xps.pub" = "regular"; }'
                (builtins.readDir ../.keys)
            )
        );
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
    };

    # Configure ZSH (https://www.zsh.org/)
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true; # Suggest matching command from history while typing
      autocd = true; # Change to directory by its name only
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
        custom = "${pkgs.omz-custom-plugins}"; # Custom plugins and overrides

        # Enable OMZ plugins
        # https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
        plugins =
          [
            "aliases" # Aliases cheatsheet https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/aliases
            # Common aliases (OVERRIDDEN!!!)
            "common-aliases"
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
        cat = "${pkgs.unstable.bat}/bin/bat";
        diff = "${pkgs.unstable.delta}/bin/delta";
        # Not using package since eza.extraOptions creates an eza alias
        ls = "eza";
        uncolor = "${pkgs.gnused}/bin/sed 's,\x1B\[[0-9;]*[a-zA-Z],,g'";
        top = "${pkgs.unstable.bottom}/bin/btm --basic";
      };
    };
  };

  # Nicely reload system units when activating config
  systemd.user.startServices = "sd-switch";
}
