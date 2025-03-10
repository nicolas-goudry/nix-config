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
  isImpermanent = lib.hasAttr "persistence" config.environment;

  # Conditional DNS settings
  # default: OpenDNS
  defaultDns = [ "208.67.222.222" "208.67.220.220" ];

  # Per user DNS settings
  userDnsSettings =
    let
      # CleanBrowsing filters (https://cleanbrowsing.org/filters/)
      filters = {
        # Security Filter:
        # - Blocks access to phishing, spam, malware and malicious domains.
        security = [ "185.228.168.9" "185.228.169.9" ];

        # Adult Filter:
        # - Blocks access to all adult, pornographic and explicit sites.
        # - It does not block proxy or VPNs, nor mixed-content sites.
        # - Sites like Reddit are allowed.
        # - Google and Bing are set to the Safe Mode.
        # - Malicious and Phishing domains are blocked.
        adult = [ "185.228.168.10" "185.228.169.11" ];

        # Family Filter:
        # - Blocks access to all adult, pornographic and explicit sites.
        # - It also blocks proxy and VPN domains that are used to bypass the filters.
        # - Mixed content sites (like Reddit) are also blocked.
        # - Google, Bing and Youtube are set to the Safe Mode.
        # - Malicious and Phishing domains are blocked.
        family = [ "185.228.168.168" "185.228.169.168" ];
      };
    in
    {
      nicolas = filters.security;
    };
in
{
  imports = [
    # Modules
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    inputs.nix-index-database.nixosModules.nix-index
    inputs.sops.nixosModules.sops

    # Configure host
    ./${hostname}

    # Configure users
    ./common/users
  ]
  # Configure desktop if workstation
  ++ lib.optional isWorkstation ./common/desktop
  # Common utilities custom scripts on installs
  ++ lib.optional isInstall ./common/utils;

  # Virtual console keymap
  console.keyMap = "fr";

  # Enable NVIDIA Docker support if host has NVIDIA driver
  hardware.nvidia-container-toolkit.enable = (isInstall && hasNvidia);

  # Set CPU frequency on performance mode
  powerManagement.cpuFreqGovernor = "performance";

  # Default timezone
  time.timeZone = "Europe/Paris";

  # Enable Docker on installs
  virtualisation.docker.enable = isInstall;

  boot = {
    # Allow communication between VMs and host OS
    kernelModules = [ "vhost_vsock" ];

    # Ensure latest available kernel
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

    # Add support for NTFS filesystems
    supportedFilesystems = {
      ntfs = true;
      zfs = lib.mkForce false;
    };

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

  environment =
    let
      nixvim = if isInstall then pkgs.nixvim else pkgs.nixvim-lite;
    in
    {
      # Generate predictable machine ID from hostname and system MD5 hash
      etc.machine-id.text = builtins.hashString "md5" "${hostname}@${platform}";

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
        nixvim
        sops
      ];

      # Default editor
      variables = {
        EDITOR = nixvim;
        SYSTEMD_EDITOR = nixvim;
        VISUAL = nixvim;
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

    extraHosts = lib.mkIf (isWorkstation && isInstall) ''
      192.168.1.1   livebox
      192.168.1.100 nas.casa
    '';

    # Common wireless configuration if host-enabled
    wireless = lib.mkIf config.networking.wireless.enable {
      # Load wifi secrets
      secretsFile = config.sops.secrets.wifi.path;

      # Allow normal users to control wpa_supplicant (useful for oneshot AP connection)
      userControlled.enable = true;
    };
  };

  nix = {
    # Always use latest nix version on installs
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

      # Avoid unwanted garbage collection when using nix-direnv
      keep-outputs = true;
      keep-derivations = true;
    };
  };

  nixpkgs = {
    config = {
      # Allow unfree packages (like vscode, terraform, …)
      allowUnfree = true;

      # Allow insecure electron
      permittedInsecurePackages = [
        "electron-25.9.0"
      ];
    };

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

    # Enable GnuPG agent
    gnupg.agent.enable = true;

    # Enable unstable git
    git = {
      enable = true;
      package = pkgs.unstable.git;
    };

    # Enable nix-index with ZSH integration
    nix-index = {
      enable = true;
      enableZshIntegration = true;
      package = pkgs.unstable.nix-index; # Always use latest nix-index
    };

    # Basic ssh configuration
    ssh = {
      # Quickly timeout on SSH connections
      extraConfig = ''
        Host *
          ConnectTimeout 10
      '';

      # Start OpenSSH agent on login
      startAgent = true;
    };

    # Basic ZSH configuration (overridden by users via home-manager)
    zsh = {
      enable = true;
      autosuggestions.enable = true;
    };
  };

  services = {
    # Allow applications to update firmware
    fwupd.enable = isInstall;

    # Disable journal persistence
    journald.storage = "volatile";

    # Enable service discovery on installs
    avahi = lib.mkIf isInstall {
      enable = true;
      nssmdns4 = true;
      openFirewall = isWorkstation;
    };

    # Enable OpenSSH server
    # This is required for sops to be able to read host SSH keys
    openssh = {
      enable = true;

      # Custom host keys
      hostKeys = [
        {
          type = "rsa";
          bits = 4096;
          comment = hostname;
          path = "${if isImpermanent then "/persist" else ""}/etc/ssh/ssh_host_rsa_key";
        }
        {
          type = "ed25519";
          comment = hostname;
          path = "${if isImpermanent then "/persist" else ""}/etc/ssh/ssh_host_ed25519_key";
        }
      ];

      # Basic security on installs
      settings = lib.mkIf isInstall {
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
      # Available layouts, models and variants: https://man.archlinux.org/man/xkeyboard-config.7
      layout = "fr,fr";
      model = "tm2030USB-102";
      variant = "bepo,oss";
    };
  };

  sops = {
    # Load wifi credentials in sops secrets if wifi is enabled
    secrets = lib.mkIf config.networking.wireless.enable {
      wifi.sopsFile = ./common/networks/secrets.yaml;
    };
  };

  system = {
    inherit stateVersion;

    # Set NixOS version name on installs
    nixos.label = lib.mkIf isInstall "-";
  };
}
