/*

  This file should contain all configuration options which are common to all
  hosts, be they workstations or servers.

  Configuration options relative to workstations (hosts with a desktop) should
  live in the 'common/desktop' subdirectory. See the 'common/desktop/default.nix'
  file for the common desktop configuration options.

  Host configurations are declared in '<hostname>/default.nix' and should mainly
  contain options relative to boot, disks and hardware-specific options.

  User configurations are declared in 'common/users/<username>/default.nix' and
  should only contain the user specification (description, groups, password, etc…).

  See the 'common/users/default.nix' file for the common configuration options
  applied to all users. User-specific options should be handled by home-manager
  in the top-level 'users' directory.

*/

{ config
, desktop
, hostname
, inputs
, lib
, modulesPath
, outputs
, pkgs
, platform
, stateVersion
, username
, ...
}:

let
  # Precompute predicates
  isInstall = (builtins.substring 0 4 hostname) != "iso-";
  isWorkstation = !builtins.isNull desktop;
  hasNvidia = builtins.elem "nvidia" config.services.xserver.videoDrivers;

  # Conditional DNS settings
  # default: OpenDNS
  defaultDns = [ "208.67.222.222" "208.67.220.220" ];
  # peruser: CleanBrowsing (https://cleanbrowsing.org/filters/)
  userDnsSettings = {
    # Security Filter:
    # - Blocks access to phishing, spam, malware and malicious domains.
    nicolas = [ "185.228.168.9" "185.228.169.9" ];

    # Adult Filter:
    # - Blocks access to all adult, pornographic and explicit sites.
    # - It does not block proxy or VPNs, nor mixed-content sites.
    # - Sites like Reddit are allowed.
    # - Google and Bing are set to the Safe Mode.
    # - Malicious and Phishing domains are blocked.
    #user = [ "185.228.168.10" "185.228.169.11" ];

    # Family Filter:
    # - Blocks access to all adult, pornographic and explicit sites.
    # - It also blocks proxy and VPN domains that are used to bypass the filters.
    # - Mixed content sites (like Reddit) are also blocked.
    # - Google, Bing and Youtube are set to the Safe Mode.
    # - Malicious and Phishing domains are blocked.
    #user = [ "185.228.168.168" "185.228.169.168" ];
  };
in
{
  imports = [
    # Modules
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.disko.nixosModules.disko
    inputs.sops.nixosModules.sops

    # Configure host
    ./${hostname}

    # Configure users
    ./common/users
  ]
  # Configure desktop if workstation
  ++ lib.optional isWorkstation ./common/desktop;

  # Virtual console keymap
  console.keyMap = "fr";

  # Set CPU frequency on performance mode
  powerManagement.cpuFreqGovernor = "performance";

  # Default timezone
  time.timeZone = "Europe/Paris";

  boot = {
    # Allow communication between VMs and host OS
    kernelModules = [ "vhost_vsock" ];

    # Ensure latest available kernel
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

    # Add support for NTFS filesystems
    supportedFilesystems = [ "ntfs" ];

    # Custom kernel parameters
    kernelParams = [
      # Drop in root shell on boot failure
      "boot.shell_on_fail"
      # Set kernel log level to ERROR
      "loglevel=3"
    ];

    # Kernel runtime parameters
    kernel.sysctl = {
      # Enable IPv4 forwarding
      "net.ipv4.ip_forward" = 1;

      # Disable IPv6
      "net.ipv6.conf.all.disable_ipv6" = 1;
      "net.ipv6.conf.default.disable_ipv6" = 1;
    };

    # Only enable EFI boot manager (systemd-boot) on installs, not live media (.ISO images)
    loader = lib.mkIf isInstall {
      # Allow EFI boot variables modifications
      efi.canTouchEfiVariables = true;

      # Timeout until default item is booted
      timeout = 3;

      systemd-boot = {
        enable = true;

        # Maximum generations to store in boot partition
        configurationLimit = 10;

        # Console resolution
        consoleMode = "max";

        # Enable Memtest86+ boot entry
        memtest86.enable = true;
      };
    };
  };

  environment = {
    # Enable ZSH completion for system packages
    pathsToLink = [ "/share/zsh" ];

    # Replace default packages
    # https://search.nixos.org/options?channel=unstable&show=environment.defaultPackages
    defaultPackages = with pkgs; lib.mkForce [
      coreutils-full
      strace
    ];

    systemPackages = with pkgs; [
      curl
      git
      neovim
    ] ++ lib.optional isInstall sops;

    # Default editor
    variables = {
      EDITOR = "nvim";
      SYSTEMD_EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  # Locale settings
  i18n = {
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "fr_FR.UTF-8";
      LC_IDENTIFICATION = "fr_FR.UTF-8";
      LC_MEASUREMENT = "fr_FR.UTF-8";
      LC_MONETARY = "fr_FR.UTF-8";
      LC_NAME = "fr_FR.UTF-8";
      LC_NUMERIC = "fr_FR.UTF-8";
      LC_PAPER = "fr_FR.UTF-8";
      LC_TELEPHONE = "fr_FR.UTF-8";
      LC_TIME = "fr_FR.UTF-8";
    };
  };

  networking = {
    # Use passed hostname to configure basic networking
    hostName = hostname;

    # DNS settings
    nameservers = if builtins.hasAttr username userDnsSettings then userDnsSettings.${username} else defaultDns;

    # Disable NetworkManager
    networkmanager.enable = lib.mkForce false;

    # Enable DHCP for all interfaces
    useDHCP = lib.mkDefault true;

    extraHosts = ''
      192.168.1.1   livebox
      192.168.1.100 nas.casa
    '';

    # Common wireless configuration if host-enabled
    wireless = lib.mkIf config.networking.wireless.enable {
      # Load wifi configurations
      environmentFile = config.sops.secrets.wifi.path;

      # Allow normal users to control wpa_supplicant (useful for oneshot AP connection)
      userControlled.enable = true;
    };
  };

  nix = {
    package = lib.mkIf isInstall pkgs.unstable.nix;

    # Add each flake input as a registry
    # To make nix3 commands consistent with this flake
    registry = (lib.mapAttrs (_: flake: { inherit flake; })) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

    # Automatically run nix store garbage collector
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # Automatically run nix store optimiser
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };

    settings = {
      # Deduplicate and optimise nix store
      auto-optimise-store = true;

      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
    };
  };

  nixpkgs = {
    # Allow unfree packages (like vscode, terraform, …)
    config.allowUnfree = true;

    # Define nixpkgs platform
    hostPlatform = lib.mkDefault "${platform}";

    overlays = [
      # Add overlays from overlays and pkgs dir
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # Add overlays exported from other flakes
      # neovim-nightly-overlay.overlays.default
    ];
  };

  programs = {
    # Disable default command not found message (handled by nix-index)
    command-not-found.enable = false;

    # Enable dconf
    dconf.enable = true;

    # Disable nano
    nano.enable = false;

    # Start OpenSSH agent on login
    ssh.startAgent = true;

    # Enable GnuPG agent
    gnupg.agent.enable = true;

    # Enable nix-index with ZSH integration
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    # Basic ZSH configuration (overridden by users via home-manager)
    zsh = {
      enable = true;

      autosuggestions = {
        enable = true;
      };
    };
  };

  services = {
    # Allow applications to update firmware
    fwupd.enable = isInstall;

    # Enable service discovery on installs
    avahi = lib.mkIf isInstall {
      enable = true;
      nssmdns = true;
      openFirewall = isWorkstation;
    };

    # Enable OpenSSH server on servers
    openssh = {
      enable = !isWorkstation && isInstall;

      # Custom host keys
      hostKeys = [
        {
          type = "rsa";
          bits = 4096;
          comment = hostname;
          path = "/etc/ssh/ssh_host_rsa_key";
        }
        {
          type = "ed25519";
          comment = hostname;
          path = "/etc/ssh/ssh_host_ed25519_key";
        }
      ];

      # Basic securisation
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Allow SSH only from home network
    sshguard = lib.mkIf (!isWorkstation) {
      enable = true;
      whitelist = [ "192.168.1.0/24" ];
    };

    # Keyboard layout
    xserver.xkb = {
      layout = "fr,fr";
      model = "tm2030USB-102";
      options = "grp:win_space_toggle";
      variant = "bepo,oss";
    };
  };

  sops = {
    gnupg = {
      # Set GnuPG home for sops to load keys from
      home = "/home/${username}/.gnupg";

      # Unset SSH key paths since GnuPG home is set
      sshKeyPaths = [ ];
    };

    # Load wifi credentials in sops secrets if wifi is enabled
    secrets = lib.mkIf config.networking.wireless.enable {
      wifi.sopsFile = ./common/shelf/networks/secrets.yaml;
    };
  };

  system = {
    inherit stateVersion;

    # Set NixOS version name on installs
    nixos.label = lib.mkIf isInstall "-";
  };

  # Enable Docker on installs
  virtualisation = lib.mkIf isInstall {
    docker = {
      enable = true;

      # Enable NVIDIA Docker support if host has NVIDIA driver
      enableNvidia = hasNvidia;
    };
  };
}
