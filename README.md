[arch-usb-flash]: https://wiki.archlinux.org/title/USB_flash_installation_medium
[gh-age]: https://github.com/FiloSottile/age
[gh-deadnix]: https://github.com/astro/deadnix
[gh-disko]: https://github.com/nix-community/disko
[gh-hm]: https://github.com/nix-community/home-manager
[gh-nh]: https://github.com/viperML/nh
[gh-nixfmt]: https://github.com/NixOS/nixfmt
[gh-nixgl]: https://github.com/nix-community/nixGL
[gh-nixos-hardware]: https://github.com/NixOS/nixos-hardware
[gh-nixpkgs]: https://github.com/NixOS/nixpkgs
[gh-nom]: https://github.com/maralorn/nix-output-monitor
[gh-sops-nix]: https://github.com/Mic92/sops-nix
[gh-statix]: https://github.com/oppiliappan/statix
[home-manager]: https://nix-community.github.io/home-manager/index.xhtml
[hm-gpu]: https://nix-community.github.io/home-manager/index.xhtml#sec-usage-gpu-non-nixos
[hm-modules]: https://nix-community.github.io/home-manager/index.xhtml#ch-writing-modules
[issue-sops-implem]: https://github.com/nicolas-goudry/nix-config/issues/2
[nix-manual-exp-feat-flakes]: https://nix.dev/manual/nix/2.24/development/experimental-features#xp-feature-flakes
[nix-manual-exp-feat-nix-command]: https://nix.dev/manual/nix/2.24/development/experimental-features#xp-feature-nix-command
[nixos]: https://nixos.org/
[nixos-search-bc-pkg]: https://search.nixos.org/packages?channel=unstable&show=bc&from=0&size=1&sort=relevance&type=packages&query=gnu+calculator
[nixos-search-boot-opt]: https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=boot.
[repo-alacritty-hardware-accel-example]: https://github.com/nicolas-goudry/nix-config/blob/a7e22ae61912df084bd09139f8b0c1b2d3b9c91d/home/users/nicolas/g-ns.nix#L11
[repo-flake]: ./flake.nix
[repo-home-default]: ./home/default.nix
[repo-hosts-default]: ./hosts/default.nix
[repo-mkusersec-example]: ./home/users/nicolas/default.nix
[repo-modules-entrypoint]: ./modules/default.nix
[repo-pkgs-default]: ./pkgs/default.nix
[repo-script-build-iso]: ./hosts/common/scripts/build-iso/build-iso.sh
[repo-script-install-system]: ./hosts/common/scripts/install-system/install-system.sh
[repo-script-install-system-deps]: ./hosts/common/scripts/install-system/default.nix#L17-L34
[repo-script-nh-all]: ./hosts/common/scripts/nh-all/nh-all.sh
[repo-script-nh-home]: ./home/common/scripts/nh-home/nh-home.sh
[repo-script-nh-host]: ./hosts/common/scripts/nh-host/nh-host.sh
[repo-sops-config]: ./.sops.yaml
[section-add-host]: #desktop_computer-add-a-host
[section-apply-changes]: #sparkles-applying-changes
[section-apply-changes-hm]: #home-manager
[section-configure-disks]: #2-configure-disks
[section-configure-hardware]: #1-configure-hardware
[section-forallsystems]: #forallsystems
[section-format-check]: #peacock-format-and-check
[section-hm-config]: #house-home-manager-configuration
[section-install-nixos]: #inbox_tray-install-nixos
[section-lib]: #toolbox-library
[section-mkhome]: #mkhome
[section-mkhost]: #mkhost
[section-mkusersecrets]: #mkusersecrets
[section-modules]: #file_cabinet-modules
[section-nixos-config]: #snowflake-nixos-configuration
[section-overlays]: #sewing_needle-overlays
[section-pkgs]: #package-packages
[section-secrets]: #closed_lock_with_key-secrets-management
[section-setup-hm]: #mechanic-setup-home-manager
[section-wrapnixgl]: #wrapnixgl
[sops]: https://getsops.io/
[wiki-flakes]: https://wiki.nixos.org/wiki/Flakes
[wiki-modules]: https://wiki.nixos.org/wiki/NixOS_modules
[wiki-overlays]: https://wiki.nixos.org/wiki/Overlays
[wiki-pgp]: https://en.wikipedia.org/wiki/Pretty_Good_Privacy
[wimpy-config]: https://github.com/wimpysworld/nix-config

# NixOS & Home Manager Configurations

This repository contains a [Nix Flake][wiki-flakes] for configuring my computers and home environments. It is not forked but is heavily inspired by [Wimpy’s NixOS & Home Manager Configurations][wimpy-config], with some modifications to better suit my use cases and experience with [Nix, NixOS][nixos], and [Home Manager][home-manager].

The primary goal of this configuration is to be modular while providing sensible defaults for all hosts and home configurations. This is achieved through a few custom functions, namely [`mkHost`][section-mkhost] and [`mkHome`][section-mkhome], which pass down the correct attributes, enabling efficient composition features.

## :round_pushpin: Current state

_Legend:_

- Operating systems
  - :snowflake: : NixOS
  - :penguin: : Linux
  - :apple: : MacOS
- Machines kind
  - :desktop_computer: : Server or personal computer
  - :computer: : Laptop
- Statuses
  - :construction: : Work in progress
  - :soon: : Planned (todo)
  - :no_entry_sign: : Abandoned
  - :white_check_mark: : Done

### :computer_mouse: Hosts

| Hostname |      OEM | Model               |     OS      |    Kind    |     Status     |
| -------- | -------: | ------------------- | :---------: | :--------: | :------------: |
| `g-aero` | Gigabyte | Aero 15             | :snowflake: | :computer: | :construction: |
| `g-mac`  |    Apple | MacBook Pro 15 2013 |   :apple:   | :computer: |     :soon:     |
| `g-xps`  |     Dell | XPS 15 7590         | :snowflake: | :computer: |     :soon:     |

### :busts_in_silhouette: Users

| Username  |     Status     |
| --------- | :------------: |
| `nicolas` | :construction: |

## :technologist: Usage

> [!WARNING]
> Unless stated otherwise, **all commands must be run from the root of the repository.**
>
> Additionally, most Nix commands in this document require the [`flakes`][nix-manual-exp-feat-flakes] and [`nix-command`][nix-manual-exp-feat-nix-command] experimental features.
>
> Enable them with:
>
> ```shell
> nix --option experimental-features "flakes nix-command" <nix-command>
> ```

### :peacock: Format and check

This flake, along with all Nix files it contains, follows the official Nix formatting standard: [nixfmt][gh-nixfmt]. Files can be formatted using:

```shell
nix fmt
```

Additionally, the flake includes several checks to verify Nix code without building or switching configurations. Currently, two checks are implemented:

- dead code detection with [deadnix][gh-deadnix]
- linting with [statix][gh-statix]

To run the checks, use the following command:

```shell
nix flake check
```

> [!WARNING]
> Running this check after modifying the configuration is **highly recommended**, but be aware that it will not catch all possible issues.

### :cd: Generate ISO

To generate an ISO of this flake, run one of the following commands from a Nix-enabled system:

```shell
# ISO with GNOME desktop
nix build '.#nixosConfigurations.iso-gnome.config.system.build.isoImage'

# ISO with console only
nix build '.#nixosConfigurations.iso-console.config.system.build.isoImage'
```

Alternatively, on a system built using this flake, use:

```shell
# ISO with GNOME desktop
build-iso gnome

# ISO with console only
build-iso console
```

> [!TIP]
> The [`build-iso` script][repo-script-build-iso] can be run from Bash as long as [`bc`][nixos-search-bc-pkg] and [nix-output-monitor][gh-nom] are available.
>
> Example:
>
> ```shell
> nix shell 'nixpkgs#bc' 'nixpkgs#nix-output-monitor' -c ./hosts/common/scripts/build-iso/build-iso.sh -h
> ```
>
> ```plain
> Build ISO from NixOS configuration.
>
> Usage:
>     $ build-iso.sh <console|gnome> [options]
>
> Options:
>     -h, --help  Show this help message
> ```

### :inbox_tray: Install NixOS

After building the ISO and [creating a bootable USB stick][arch-usb-flash], install NixOS using the instructions below.

This flake provides the [`install-system`][repo-script-install-system] command to simplify the installation process:

```shell
❯ install-system -h
```

```plain
NixOS installation helper script.

Usage:
    $ install-system [options]

Options:
    -H, --host    Host to install NixOS to
    -u, --user    Username to install NixOS with
    -b, --branch  Branch to use for configuration   default: main
    -K, --gpg     GnuPG key to use
    --fetch-only  Clone source repository and exit
    -h, --help    Show this help message
```

> [!CAUTION]
> The `install-system` command is only available within the ISO.
>
> However, since it is a Bash script, it could technically be executed from any system with Bash and the [necessary dependencies][repo-script-install-system-deps]. **Use it carefully, as it could result in data loss.**

**Prerequisites:**

- at least one [PGP][wiki-pgp] private key known to [SOPS][sops] must be loaded in the local keyring — see [secrets management][section-secrets] for further details
- internet connectivity is required

In a nutshell, the command will:

- use [disko][gh-disko] or a Bash script to partition and format the disks — see [adding a host][section-add-host] for further details
- add the host to the authorized hosts list — see [secrets management][section-secrets] for further details
- install NixOS
- setup Home Manager

<details>

<summary>:detective: <b>Expand to view the detailed installation workflow</b></summary>

![Detailed installation workflow](./.github/assets/img/install-process.png "Detailed installation workflow")

</details>

Once the installation is complete, reboot into the installed system.

> [!IMPORTANT]
> The installation process will update the secrets with the new host encryption key.
>
> Repository files will be modified, so commit the changes.

### :mechanic: Setup Home Manager

> [!WARNING]
> This section is only relevant for non-NixOS systems or those not installed using this flake.

**Prerequisites:**

- [Nix][nixos]
- [Home Manager][home-manager]
- a local copy of this repository at `~/nixstrap`

Run the following command to set up Home Manager:

```shell
home-manager switch --flake '.#<user>@<host>'
```

> [!WARNING]
> Replace `<user>@<host>` with a valid `homeConfigurations` key from the flake outputs.

After setting up Home Manager, refer to [applying changes][section-apply-changes] for updating configurations.

### :sparkles: Applying Changes

> [!NOTE]
> This flake separates NixOS and Home Manager configurations, so changes must be applied independently.
>
> This prevents unnecessary system rebuilds and supports non-NixOS hosts.

After [installing NixOS][section-install-nixos] or [setting up Home Manager][section-setup-hm], convenience scripts are provided to build or switch configurations after making changes. These scripts use the [`nh`][gh-nh] CLI helper.

> [!TIP]
> Run [flake checks][section-format-check] after modifying the configuration. They will help catch errors and save time.

#### NixOS

On NixOS systems installed using this flake, the [`nh-host`][repo-script-nh-host] command is available:

```shell
❯ nh-host -h
```

```plain
Build or switch NixOS configuration using 'nh'.

Usage:
    $ nh-host <build|switch> [options]

Options:
    -h, --help  Show this help message

Note: unknown options will be passed down to 'nh'.
```

> [!NOTE]
> `nh` automatically selects the NixOS configuration based on the hostname, so running `nh-host build` or `nh-host switch` is sufficient.

> [!TIP]
> For convenience, `nh-host build` is also available as **`build-host`** while `nh-host switch` is available as **`switch-host`**.

#### Home Manager

On systems where Home Manager was set up using this flake, the [`nh-home`][repo-script-nh-home] command is available:

```shell
❯ nh-home -h
```

```plain
Build or switch Home Manager configuration using 'nh'.

Usage:
    $ nh-home <build|switch> [options]

Options:
    -h, --help  Show this help message

Note: unknown options will be passed down to 'nh'.
```

> [!NOTE]
> Since `nh` uses the username to select the Home Manager configuration, running `nh-home build` or `nh-home switch` is sufficient to apply changes.

> [!TIP]
> For convenience, `nh-home build` is also available as **`build-home`** while `nh-home switch` is available as **`switch-home`**.

#### All at once

On NixOS systems installed using this flake, the [`nh-all`][repo-script-nh-all] command is also available:

```shell
❯ nh-all -h
```

```plain
Build or switch NixOS and Home Manager configurations using 'nh'.

Usage:
    $ nh-all <build|switch> [options]

Options:
    -h, --help  Show this help message
```

This command will run `nh-host` and then, if available, `nh-home`.

> [!TIP]
> For convenience, `nh-all build` is also available as **`build-all`** while `nh-all switch` is available as **`switch-all`**.

### :desktop_computer: Add a host

To provision a new host, its configuration must be present in this flake and follow these rules:

- the host configuration must be located in a subdirectory of the `hosts` directory
- the directory name must match the hostname
- the directory must contain a `default.nix` file
- the directory must contain either a `disks.nix` or `disks.sh` file

The steps below will add a host compliant with these rules.

1. **Create the host directory:**

   ```shell
   mkdir -p hosts/<new-host>
   ```

> [!IMPORTANT]
> Replace `<new-host>` with the actual hostname. Ensure consistency across configuration files.

2. **Configure the hardware** by creating a `default.nix` file inside `hosts/<new-host>`:

   ```nix
   # Brand: Dell, HP, etc…
   # Model: Model name/number
   # CPU  : Model (Number of physical cores) @ CPU frequency
   # RAM  : Amount
   # GPU  : Brand, model and RAM amount
   # Disk : Brand, model and size

   { inputs, ... }:

   {
     imports = [
       # Uncomment the relevant hardware modules
       # inputs.hardware.nixosModules.common-cpu-intel
       # inputs.hardware.nixosModules.common-gpu-intel
       # inputs.hardware.nixosModules.common-cpu-amd
       # inputs.hardware.nixosModules.common-gpu-amd
       # inputs.hardware.nixosModules.common-gpu-nvidia
       # inputs.hardware.nixosModules.common-hidpi
       # inputs.hardware.nixosModules.common-pc
       # inputs.hardware.nixosModules.common-pc-hdd
       # inputs.hardware.nixosModules.common-pc-ssd
       # inputs.hardware.nixosModules.common-pc-laptop
       # inputs.hardware.nixosModules.common-pc-laptop-hdd
       # inputs.hardware.nixosModules.common-pc-laptop-ssd

       # Disko configuration
       # ./disks.nix

       # Erase your darlings
       # ../common/impermanence

       # Configure services
       # ../common/services/networks
       # ../common/services/printers
     ];

     # Enable wireless networks if needed
     # networking.wireless.enable = true;

     # Setup boot loader
     boot = { /* … */ };
   }
   ```

> [!TIP]
> Use [nixos-hardware modules][gh-nixos-hardware] to configure the host hardware from a curated list of options from the community.
>
> Alternatively, you can generate a hardware configuration by booting a NixOS ISO on the host and running:
>
> ```shell
> nixos-generate-config --dir /tmp
> ```
>
> Then, copy relevant parts from `/tmp/hardware-configuration.nix` into `default.nix` (usually the [`boot`][nixos-search-boot-opt] attribute set).

3. **Configure the disks:**

   Two options here:

   - use a **declarative** approach with [disko][gh-disko] (create `disks.nix`)
   - use an **imperative** approach with a Bash script (`disks.sh`)

> [!WARNING]
> If using a Bash script, ensure the primary disk is mounted at `/mnt` after completing disk preparation. Failing to do so will error the [installation][section-install-nixos].

4. **Declare the host in `flake.nix`:**

   ```nix
   {
     outputs = {
       nixosConfigurations = {
         new-host = libx.mkHost { hostname = "new-host"; username = "someUser"; desktop = "gnome"; };
       };
     };
   }
   ```

Refer to [this][section-mkhost] for further details on the `mkHost` function.

> [!IMPORTANT]
> The `username` argument must match one of the subdirectories of `hosts/common/users`.\
> The `desktop` argument must match one of the subdirectories of `hosts/common/desktop`.
>
> Failing to provide a valid `username` or `desktop` **will not prevent the installation to succeed**. However, without a `username` only the `root` user will be present on the installed system and without a `desktop` the installed system will not have a graphical interface.

### :bust_in_silhouette: Add a user

TODO

## :gear: Inner workings

### :building_construction: Repository structure

This repository is organized into multiple directories, each serving a specific purpose:

| Directory  | Purpose                                  | Details                                         |
| ---------- | ---------------------------------------- | ----------------------------------------------- |
| `.keys`    | PGP public keys for secrets management   | [Secrets management][section-secrets]           |
| `home`     | Home Manager configurations              | [Home Manager configuration][section-hm-config] |
| `hosts`    | NixOS system configurations              | [NixOS configuration][section-nixos-config]     |
| `lib`      | Helper functions                         | [Library][section-lib]                          |
| `modules`  | NixOS and Home Manager custom modules    | [Modules][section-modules]                      |
| `overlays` | Custom [Nixpkgs overlays][wiki-overlays] | [Overlays][section-overlays]                    |
| `pkgs`     | Custom packages definitions              | [Packages][section-pkgs]                        |

Each directory contains files and subdirectories that define configurations, functions, and additional resources necessary to maintain a structured and modular setup.

### :snowflake: NixOS configuration

TODO

### :house: Home Manager configuration

TODO

> [!WARNING]
> There is a weak dependency between hosts users and Home Manager users configuration, since Home Manager does not create users.
>
> - on NixOS systems installed by this flake, users referenced by a Home Manager configuration should first be created in `hosts/common/users`
> - on non-NixOS systems or NixOS systems not created by this flake, users must exist prior to [applying Home Manager configuration][section-apply-changes-hm]

### :toolbox: Library

The `lib` directory contains reusable helper functions designed to streamline NixOS and Home Manager configurations. These functions are imported as `libx` and are accessible in most Nix expressions through the `outputs` attribute.

Available functions:

- [`mkHome`][section-mkhome]
- [`mkHost`][section-mkhost]
- [`mkUserSecrets`][section-mkusersecrets]
- [`forAllSystems`][section-forallsystems]
- [`wrapNixGL`][section-wrapnixgl]

Each function simplifies complex tasks, ensuring consistency across configurations.

#### `mkHome`

**Description:** generate a Home Manager configuration

**Input:** AttrSet

- `username` (string): name of the user
- `hostname` (string): name of the host (useful for loading host-specific user configurations) — this can be omitted
- `desktop` (string): name of the user’s desktop environment (useful for loading desktop-specific user configurations) — this can be omitted
- `platform` (string): name of the target platform (useful for loading platform-specific user configurations; defaults to `x86_64-linux`)

**Output:** attribute set declaring a Home Manager configuration

**Details:**

The generated Home Manager configuration imports the [common configuration][repo-home-default], which in turn loads the user-specific configuration and other relevant settings. It also loads platform-specific packages and sets the following `extraSpecialArgs`:

- `username`, `hostname`, `desktop` and `platform`: function input attribute set
- `inputs`: flake inputs (useful for consuming other modules)
- `outputs`: flake outputs (useful for consuming [custom modules][section-modules])
- predicates: is it an ISO, a workstation, …

> [!NOTE]
> The `extraSpecialArgs` option allows to pass the given attribute set as an additional argument to Home Manager configuration files.

#### `mkHost`

**Description:** generate a NixOS configuration

**Input:** AttrSet

- `hostname` (string): name of the host
- `username` (string): name of the user (useful for loading user-specific host configurations) — this can be omitted
- `desktop` (string): name of the host's desktop environment (useful for loading desktop-specific host configurations) — this can be omitted
- `platform` (string): name of the target platform (useful for loading platform-specific host configurations; defaults to `x86_64-linux`)

**Output:** attribute set declaring a NixOS configuration

**Details:**

The generated NixOS configuration imports the [common configuration][repo-hosts-default], which subsequently loads the host-specific configuration and the NixOS CD/DVD installer module, used to build ISOs when the host is identified as an ISO (ie. name starting by `iso-`). It also sets the following `specialArgs`:

- `hostname`, `username`, `desktop` and `platform`: function input attribute set
- `inputs`: flake inputs (useful for consuming other modules)
- `outputs`: flake outputs (useful for consuming [custom modules][section-modules])
- predicates: is it an ISO, a workstation, …

> [!NOTE]
> The `specialArgs` option allows to pass the given attribute set as an additional argument to NixOS configuration files.

#### `mkUserSecrets`

**Description:** configure secrets for a user

**Input:** AttrSet

- `sopsFile` (path): path to the file encrypted by [SOPS][sops] — see [secrets management][section-secrets] for further details
- `username` (string): name of the user owning the secret
- `secrets` (map<attrset>): map of attribute sets, where each attribute represents a secret
  - `name` (string): name of the secret (will be used as the secret file name)
  - `dir` (string): directory where the secret should be written (relative to the user's home directory)
  - `file` (string): alternate file name (defaults to `name`) — this can be omitted
  - `path` (string): full path to the secret file (if provided, `file` and `dir` are ignored) — this can be omitted
  - `mode` (string): file permissions for the secret in octal mode (defaults to `0400`)
  - `neededForUsers` (boolean): mark the secret as needed for users (activated during boot) (defaults to `false`)

**Output:** attribute set declaring a [sops-nix][gh-sops-nix] secrets configuration

**Details:**

A usage example is available in [this file][repo-mkusersec-example].

#### `forAllSystems`

**Description:** configure all supported systems

**Input:** Function -> String (system) -> AttrSet

**Output:** attribute set with attributes for all platforms supported by this flake

**Details:**

Only used in [`flake.nix`][repo-flake] right now.

#### `wrapNixGL`

**Description:** wrap a package with [NixGL][gh-nixgl]

**Input:** AttrSet

- `pkg` (derivation): package to wrap
- `platform` (string): name of the target platform (defaults to `x86_64-linux`)

**Output:** given package wrapped by NixGL

**Details:**

This is used on non-NixOS systems to provide access to drivers, effectively enabling hardware acceleration.

For example, this could be used to enable hardware acceleration in Alacritty (and it was, at [one point][repo-alacritty-hardware-accel-example]).

> [!NOTE]
> It appears that this feature is already provided by [Home Manager][hm-gpu]. Since there are no current usages of this function in the codebase, it may be removed in favor of the Home Manager implementation.

### :file_cabinet: Modules

> [!NOTE]
> When possible, it is preferred to upstream modules to [nixpkgs][gh-nixpkgs] or move them to their own repositories.

To extend NixOS features in a composable and reusable way, this flake allows to define custom [NixOS modules][wiki-modules] as well as [Home Manager modules][hm-modules] in the `modules` directory. This directory contains the following files:

```plain
modules
├── home-manager       # Add Home Manager modules here
│   └── default.nix
└── nixos
    └── default.nix    # Add NixOS modules here
```

Modules can be defined as individual Nix files or as directories containing a `default.nix` file that imports all required components and must be explicitly referenced in the [NixOS modules entrypoint][repo-modules-nixos-entrypoint] or [Home Manager modules entrypoint][repo-modules-nixos-entrypoint], as demonstrated below:

```nix
{
  # From a single Nix file
  my-module = import ./my-module.nix;

  # From a directory containing a 'default.nix' file
  my-module-bis = import ./my-module-bis;
}
```

Once defined in an entrypoint, these modules are automatically loaded and become available under `outputs.nixosModules.<module-name>` for NixOS modules and `outputs.homeManagerModules.<module-name>` for Home Manager modules.

### :sewing_needle: Overlays

To extend or modify [nixpkgs][gh-nixpkgs], [Nix Overlays][wiki-overlays] can be defined in the `overlays` directory.

A common use case for an overlay is to update a package when its latest version has not yet been made available in nixpkgs.

### :package: Packages

> [!NOTE]
> When possible, it is preferred to upstream packages to [nixpkgs][gh-nixpkgs] or move them to their own repositories.

To add packages not yet available in nixpkgs, packages derivations can be defined in the `pkgs` directory.

The convention is to create a subdirectory for each added package and reference it in the [main file][repo-pkgs-default], which exports all custom packages. When relevant, multiple packages directories can be grouped in a single directory.

### :closed_lock_with_key: Secrets management

#### Concept

For maximum reproducibility, it is desirable to store secrets and automatically make them available to both the system and its users. This allows configuration of user passwords, network credentials, and similar sensitive information only once and then reusing it across multiple systems. This is where [SOPS][sops] becomes invaluable. SOPS enables you to store encrypted secrets in files using various encryption methods. In this flake, we use [PGP][wiki-pgp] and [age][gh-age] for encrypting secrets.

To avoid maintaining one large file containing all secrets, they are instead distributed across multiple files, each grouping related secrets. For instance, all wireless network credentials can reside in one file, while passwords and sensitive values for a given user are stored in another.

This setup defines two distinct actors with corresponding key formats:

- **trusted users**: use PGP keys
- **authorized hosts**: use age keys

With this arrangement, only authorized hosts and trusted users can decrypt the secrets. The only caveat is that trusted users must provide their public PGP key for secrets encryption key updates.

#### Implementation

This flake leverages [sops-nix][gh-sops-nix] to enable automatic secrets decryption during NixOS or Home Manager activation.

Trusted users and authorized hosts are defined in the [SOPS configuration file][repo-sops-config] as `users` and `hosts`, respectively. All secrets are encrypted and decrypted using a single key group that includes all user and host keys.

> [!CAUTION]
> This design may not be optimal or secure in multi-user setups, as it allows all users to read each other’s secrets.
>
> A [tracking issue][issue-sops-implem] is in place to investigate and resolve this concern.

To avoid redundancy, YAML anchors are used to define keys once in `keys` and reference them later in `creation_rules`:

```yaml
keys:
  user:
    - &someuser ...
creation_rules:
  - path_regex: *.yaml
    key_groups:
      - pgp:
          - *someuser
```

As mentioned earlier, to prevent all secrets from being consolidated into a single file, multiple secrets files are distributed across the repository. By convention — and due to the current configuration — secrets file names must end with either `secrets.yaml` or `secrets.yml` for SOPS to recognize them.

Trusted users must place their public PGP keys in the `.keys` directory; otherwise, secrets encryption will fail. This requirement arises because, during encryption, the PGP public key identifier in the configuration isn’t sufficient — it merely references the key material. SOPS requires the actual public key (the raw material) to encrypt secrets, so it must be available in the local keyring.

Authorized hosts’ age keys are derived from their ed25519 public SSH keys. By default, sops-nix attempts to load the host’s ed25519 private SSH key as an age key to decrypt secrets. The following steps outline how to add a host to the list of authorized hosts.

#### Add a host to authorized hosts

1. **Derive the host’s age key from its ed25519 public SSH key:**

   ```shell
   sudo nix run 'nixpkgs#ssh-to-age' -- -i /etc/ssh/ssh_host_ed25519_key.pub
   ```

> [!NOTE]
> The output of this command is a public age key, hereafter referred to as `<public-age>`.

2. **Add the public age key to the SOPS configuration file:**

   ```yaml
   keys:
     hosts:
       - &new-host <public-age>
   creation_rules:
     - key_groups:
         - age:
             - *new-host
   ```

3. **Import all trusted users’ public PGP keys into the local keyring:**

   ```shell
   gpg --import .keys/*.pub
   ```

4. **Re-encrypt all secrets:**

   ```shell
   find . -type f -name 'secrets.y*ml' -exec sops updatekeys -y {} \;
   ```

5. **Commit and push changes to the repository**

<!--

### 🏘️ `hosts`

```plain
.
├── common                      👈 Common on-the-shelf host configuration
├── iso-console                 👈 ISO configuration for console installations
├── iso-gnome -> iso-console    👈 Symlink to console configuration for desktops ISOs
└── default.nix                 👈 Common base host configuration
```

This directory contains the hosts configurations as well as composited configurations based on the arguments defined in [`flake.nix`](./flake.nix).

All hosts share a [base configuration](./hosts/default.nix) which defines common boot loader parameters, default system packages, networking setup, keyboard layout, locale settings, programs, services and more… In short: stuff that should be configured whatever the host is.

Each host is defined in its own directory and mainly contains hardware specific configuration (with or without [nixos-hardware](https://github.com/nixos/nixos-hardware)), disks configuration (using Bash script or [disko](https://github.com/nix-community/disko)) and [on-the-shelf configuration settings](#on-the-shelf).

Additionally, ISO configurations can be found in this directory.

#### On-the-shelf

These configurations, located in the [`hosts/common`](./hosts/common/) directory, are shared across multiple hosts but are entirely optional. Some on-the-shelf configurations are consumed automatically, given the arguments defined in [`flake.nix`](./flake.nix). Others must be explicitly consumed by hosts which needs them.

These are consumed automatically:

- [`desktop`](./hosts/common/desktop/): desktop configurations
- [`users`](./hosts/common/users/): user accounts definitions

<details>
  <summary><b>About desktops</b></summary>

All desktops share a common [base configuration](./hosts/common/desktop/default.nix) which configures usual desktop stuff like pretty boot (splashscreen), fonts, browser, audio, bluetooth, graphics and more…

Each desktop is defined in its own directory and only contains configuration specific to this desktop.

Desktop configuration is automatically consumed by hosts which define a `desktop` argument.

--

</details>

<details>
  <summary><b>About users</b></summary>

These configurations must not configure the users home directory, packages and so on. They are only here to create the users, assign their groups, define their password… With the exception of `nixos` user (read further).

User configuration is automatically consumed by hosts which define a `username` argument.

There are two special users in this directory: [`root`](./hosts/common/users/root/) and [`nixos`](./hosts/common/users/nixos/).

The `root` user is the superuser definition for all hosts and is always consumed by configurations.

The `nixos` user is the user used by ISO configurations. It is the only user which configures more than its basic definition. It comes with a Bash script to [install NixOS](#-install-nixos) on a given host.

--

</details>

These are explicitly consumed by hosts:

- [`networks`](./hosts/common/networks/): network configurations
- [`printers`](./hosts/common/printers/): printer configurations

<details>
  <summary><b>About networks</b></summary>

Since this flake takes a fully declarative approach, the [NetworkManager](https://wiki.archlinux.org/title/NetworkManager) service is disabled in order to be able to configure wireless networks declaratively with [wpa_supplicant](https://wiki.archlinux.org/title/wpa_supplicant).

Multiple networks are available for consumption, they contain the wireless networks authentication details stored as [sops](https://github.com/getsops/sops) secrets as well as their NixOS configuration.

For hosts to consume networks, they need to add the network configuration to their `imports` list and enable `networking.wireless.enable`.

```nix
imports = [ ../common/networks/<network-name> ];
networking.wireless.enable = true;
```

---

</details>

<details>
  <summary><b>About printers</b></summary>

Similarly to wireless networks, printers configuration can be consumed by hosts which needs these printers.

Each printer definition should install the printer drivers and define the printer configuration.

For hosts to consume printers, they need to add the printer configuration to their `imports` list and enable `services.printing.enable` (automatically enabled on desktops).

```nix
imports = [ ../common/printers/<printer-name> ];
services.printing.enable = true; # Only required on servers
```

---

</details>
-->

## 📝 TODO

- Work configuration
- ❓ Impermanence on `/home`
- Configure nixvim ➡️ [typecraft course](https://www.youtube.com/playlist?list=PLsz00TDipIffreIaUNk64KxTIkQaGguqn) | [understanding neovim](https://www.youtube.com/playlist?list=PLx2ksyallYzW4WNYHD9xOFrPRYGlntAft)
- Hosts
  - Write a `disks.sh` script to format g-xps disk while keeping Windows dual boot
- Home
  - Finish adding and configuring programs
    - ❓ [aria2](https://github.com/aria2/aria2) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.aria2.enable)</sup></sub>
    - ❓ [atuin](https://github.com/atuinsh/atuin) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.atuin.enable)</sup></sub>
    - [awscli](https://github.com/aws/aws-cli) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.awscli.enable)</sup></sub>
    - [borgmatic](https://torsion.org/borgmatic/) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.borgmatic.enable)</sup></sub>
    - [broot](https://github.com/Canop/broot) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.broot.enable)</sup></sub> / [fd](https://github.com/sharkdp/fd) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.fd.enable)</sup></sub> / [fzf](https://github.com/junegunn/fzf) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.fzf.enable)</sup></sub> / [yazi](https://github.com/sxyazi/yazi) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.yazi.enable)</sup></sub>
    - chromium <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.chromium.enable)</sup></sub>
    - git <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.git.enable)</sup></sub>
      - work-specific configuration
    - ❓ gpg <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.gpg.enable)</sup></sub>
    - [k9s](https://github.com/derailed/k9s) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.k9s.enable)</sup></sub>
    - [lazygit](https://github.com/jesseduffield/lazygit) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.lazygit.enable)</sup></sub>
    - [mpv](https://github.com/mpv-player/mpv) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.mpv.enable)</sup></sub>
    - [mr](https://myrepos.branchable.com/) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.mr.enable)</sup></sub>
    - ❓ [ncspot](https://github.com/hrkfdn/ncspot) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ncspot.enable)</sup></sub>
    - [nix-index](https://github.com/nix-community/nix-index) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.nix-index.enable)</sup></sub>
    - [rbw](https://github.com/doy/rbw) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.rbw.enable)</sup></sub>
    - [ripgrep](https://github.com/BurntSushi/ripgrep) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ripgrep.enable)</sup></sub>
    - ❓ ssh <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ssh.enable)</sup></sub>
    - [tealdeer](https://github.com/dbrgn/tealdeer) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.tealdeer.enable)</sup></sub> - <sub><sup>replaces tldr</sup></sub>
    - [thefuck](https://github.com/nvbn/thefuck) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.thefuck.enable)</sup></sub>
    - ❓ thunderbird <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.thunderbird.enable)</sup></sub>
    - [tmux](https://github.com/tmux/tmux) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.tmux.enable)</sup></sub> / [zellij](https://github.com/zellij-org/zellij) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zellij.enable)</sup></sub>
    - ❓ [vscode](https://github.com/microsoft/vscode) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.vscode.enable)</sup></sub>
    - ❓ [yt-dlp](https://github.com/yt-dlp/yt-dlp) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.yt-dlp.enable)</sup></sub>
    - [zoxide](https://github.com/ajeetdsouza/zoxide) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zoxide.enable)</sup></sub>
    - zsh <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zsh.enable)</sup></sub>
      - user `dirHashes`
