/*
  This file contains configuration options common to all users. It is responsible
  for loading the requested user configuration through the 'username' parameter,
  as well as loading the root user configuration which is common to all hosts.
*/

{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  imports =
    [
      ./root
    ]
    # Load custom user definition if it exists
    ++ lib.optional (builtins.pathExists (./. + "/${username}")) ./${username};

  users = {
    # Only handle users via configuration (this is also needed for impermanence)
    # See https://nixos.org/manual/nixos/stable/#sec-state-users
    mutableUsers = false;

    # Common user configuration
    users.${username} = {
      isNormalUser = true;

      # Provide home-manager for users
      packages = [ pkgs.home-manager ];

      # Default user shell
      shell = pkgs.zsh;

      extraGroups =
        [
          # Add user to sudoers
          "wheel"
        ]
        # Add user to docker group if docker is enabled
        ++ lib.optionals config.virtualisation.docker.enable [
          "docker"
        ]
        # Add user to vboxusers group if virtualbox is enabled
        ++ lib.optionals config.virtualisation.virtualbox.host.enable [
          "vboxusers"
        ];
    };
  };

  # Enable sudo if there is at least one non-system user
  security.sudo = {
    enable = lib.mkDefault (lib.filterAttrs (_: user: user.isNormalUser) config.users.users != { });
  };
}
