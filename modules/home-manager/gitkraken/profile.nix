{
  gitSubmodule,
  gpgSubmodule,
  graphSubmodule,
  lib,
  sshSubmodule,
  toolsSubmodule,
  uiSubmodule,
  userSubmodule,
}:

with lib;

let
  profileIcons = [
    "gravatar"
    "Keif.png" # Keif, the Kraken
    "Developer-Keif1.png" # Developer Keif
    "Developer-Keif2.png" # Developer Keif
    "Keif-the-Riveter.png" # Kefie the Riveter
    "Space-Rocket-Keif.png" # Space Rocket Keif
    "Architect-Keif.png" # Architect Keif
    "Brainy-Keif.png" # Brainy Keif
    "Sir-Keif.png" # Sir Keif
    "Pro-Keif.png" # Pro Keif
    "Git-Mage-Keif.png" # Git Mage
    "Gitty-up.png" # Gitty Up
    "Power-Gitter.png" # Power Gitter
    "Butler-Keif.png" # Butler Keif
    "Headphones-Keif.png" # Headphones Keif
    "Lumber-Keif.png" # LumberKeif
    "OG-Keif.png" # OG
    "Vanilla-Keif.png" # Vanilla Keif
    "Keifa-Lovelace.png" # Keifa Lovelace
    "Professor-Keif.png" # Albert Keifstein
    "Flash-Keif.png" # Flash Keif
    "Wonder-Kraken.png" # Wonder Kraken
    "Aqua-Keif.png" # AquaKeif
    "Capt-FalKeif.png" # Captain FalKeif
    "Thunder-Kraken.png" # Thunder Kraken
    "Kraknos.png" # Kraknos
    "Princess-Keifia.png" # Princess Keifia
    "Yoda-Keif.png" # Yoda Keif
    "Keiflo-Ren.png" # Keiflo Ren
    "Rise-of-SkyKraken.png" # Rise of SkyKraken
    "Top-Git.png" # Top Git
    "Gourmet-Keif.png" # Gourmet Sh*t
    "The-Bride-Keif.png" # Uma Kraken
    "Neo-Keif.png" # Neo Keif
    "Keif-Stanz.png" # Dr. Keif Stanz
    "Martian-Keif.png" # Martian Kraken
    "Kraken-who-lived.png" # The Kraken Who Lived
    "Keiflock-Holmes.png" # Keiflock Holmes
    "Kraken-Hook.png" # Kraken Hook
    "Keiferella.png" # Keiferella
    "Mother-of-Krakens.png" # Mother of Krakens
    "Keif-Snow.png" # Keif Snow
    "Krakener-Things.png" # Stranger Krakens
    "Velma-Keif.png" # Velma Keif
    "Keifuto.png" # Keifuto
    "Keifer-Simpson.png" # Keifer Simpson
    "Link-Keif.png" # LinKeif
    "Keifachu.png" # Detective Keifachu
    "Santa-Keif.png" # Kaken Claus
    "Snow-Kraken.png" # Snowkraken
    "Rasta-Keif.png" # Rasta Keif
    "Leprekraken.png" # Leprekraken
    "Dia-de-los-Muertos-Keif.png" # Dia de los Muertos
  ];
in
types.submodule {
  options = {
    commitGraph = mkOption {
      type = graphSubmodule "profile";
      default = { };
      description = ''
        Commit graph settings for this profile.
      '';
    };

    isDefault = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Set profile as default. Only one profile can be the default
        one. Only pro accounts can set multiple profiles.
      '';
    };

    git = mkOption {
      type = gitSubmodule "profile";
      default = { };
      description = ''
        Git settings for this profile.
      '';
    };

    gpg = mkOption {
      type = gpgSubmodule;
      default = { };
      description = ''
        GPG settings for this profile.
      '';
    };

    icon = mkOption {
      type = types.enum profileIcons;
      default = "gravatar";
      description = ''
        Icon avatar displayed in GitKraken.
      '';
    };

    name = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Name of the profile displayed in GitKraken.
      '';
    };

    ssh = mkOption {
      type = sshSubmodule;
      default = { };
      description = ''
        SSH settings for this profile.
      '';
    };

    tools = mkOption {
      type = toolsSubmodule;
      default = { };
      description = ''
        External tools settings for this profile.
      '';
    };

    ui = mkOption {
      type = uiSubmodule "profile";
      default = { };
      description = ''
        UI settings for this profile.
      '';
    };

    user = mkOption {
      type = userSubmodule;
      default = { };
      description = ''
        User settings for this profile.
      '';
    };
  };
}
