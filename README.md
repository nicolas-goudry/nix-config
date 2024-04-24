# ❄️ [NixOS](https://nixos.org/) & [Home Manager](https://github.com/nix-community/home-manager) Configurations

This repository contains a [Nix Flake](https://nixos.wiki/wiki/flakes) for configuring my computers and home environment. These are the computers this configuration currently manages:

| Hostname |      OEM | Model               | OS  | Kind | Status |
| -------- | -------: | ------------------- | :-: | :--: | :----: |
| `g-xps`  |     Dell | XPS 15 7590         | ❄️  |  💻  |   🔜   |
| `g-aero` | Gigabyte | Aero 15             | ❄️  |  💻  |   🛠️   |
| `g-mac`  |    Apple | Macbook Pro 15 2013 | 🍎  |  💻  |   🔜   |

Not _forked_ but shamelessly and heavily borrowed from [Wimpy’s NixOS & Home Manager Configurations ❄️](https://github.com/wimpysworld/nix-config).

## 🏗️ Structure

```plain
.
├── .keys       👈 hosts public GPG keys
├── home        👈 home-manager configurations
├── hosts       👈 NixOS configurations
├── lib         👈 helpers to make hosts and users home
├── overlays    👈 nixpkgs overlays
└── pkgs        👈 custom packages
```

### 🔑 `.keys`

This directory contains all configured hosts public GPG keys which are derived from their SSH RSA key. It is required for new installations since all secrets are re-encrypted with the new host public GPG key, therefore all other hosts public keys are needed as well.

For further details, read the [secrets handling](#️-secrets-handling) section.

### 🧑‍🤝‍🧑 `home`

This directory contains the home-manager configurations of users.

> [!NOTE]
> There is a weak dependency between hosts users and home-manager users configuration, since home-manager does not create users. Therefore, users should first be created in `hosts/common/users` and then configured here.

<!-- keep mdlint happy -->

> **TODO**: fill when home-manager configurations are up.

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

* [`desktop`](./hosts/common/desktop/): desktop configurations
* [`users`](./hosts/common/users/): user accounts definitions

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

* [`networks`](./hosts/common/networks/): network configurations
* [`printers`](./hosts/common/printers/): printer configurations

<details>
  <summary><b>About networks</b></summary>

  Since this flake takes a fully declarative approach, the [NetworkManager](https://wiki.archlinux.org/title/NetworkManager) service is disabled in order to be able to configure wireless networks declaratively with [wpa_supplicant](https://wiki.archlinux.org/title/wpa_supplicant).

  Multiple networks are available for consumption, they contain the wireless networks authentication details stored as [sops](https://github.com/getsops/sops) secrets as well as their NixOS configuration.

  For hosts to consume networks, they need to add the network configuration to their `imports` list and enable `networking.wireless.enable`.

  ```nix
  imports = [ ../common/networks/<network-name> ];
  networking.wireless.enable = true;
  ```

  --

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

  --

</details>

### 🧰 `lib`

This directory contains some helper functions which are used to craft host and home-manager configurations:

* `mkHome`: generates an attrset for home-manager configuration of users
* `mkHost`: generates an attrset for NixOS configuration of hosts (both installs and ISOs)
* `forAllSystems`: generates a list of all supported systems by this flake

### 🪡 `overlays`

This directory contains [Nix Overlays](https://nixos.wiki/wiki/overlays) which allow to override packages definitions.

A good use case example of an overlay is to update a package if its latest version is not available in [nixpkgs](https://github.com/nixos/nixpkgs).

### 📦 `pkgs`

This directory contains custom packages which are not yet in [nixpkgs](https://github.com/nixos/nixpkgs).

A good use case example of a custom package is to work on packaging an application before contributing it back to [nixpkgs](https://github.com/nixos/nixpkgs).

## 🚀 Provisioning

### 💿 ISO generation

To generate an ISO of this flake, run one of the following commands from a Nix-enabled system:

```shell
# ISO with Gnome desktop
nix build '.#nixosConfigurations.iso-gnome.config.system.build.isoImage'

# ISO with console only
nix build '.#nixosConfigurations.iso-console.config.system.build.isoImage'
```

This ISO can then be used from a USB stick to [install NixOS](#-install-nixos).

### 🏠 Add a host

In order to provision a new host, its configuration must be present in this flake. Follow the steps below to add a new host.

#### 1. Create hardware configuration

Create a new directory under `hosts`, named after the host. For example:

```shell
mkdir hosts/new-host
```

Create a basic hardware configuration in `hosts/new-host/default.nix`:

```nix
{ inputs, ... }:

{
  imports = [ /* ... */ ];
  boot = { /* ... */ };
  # ...
}
```

> [!TIP]
> To generate a configuration for the new host, boot off a NixOS ISO and run:
>
> ```shell
> nixos-generate-config --dir /tmp
> ```
>
> Then copy the bare minimum from the generated `/tmp/hardware-configuration.nix` (usually the `boot` section) into `hosts/new-host/default.nix`.

<!-- keep mdlint happy -->

> [!NOTE]
> As a convention, add info about the machine at the top of the host hardware configuration file :
>
> ```nix
> # Brand: Dell, HP, etc…
> # Model: Model name/number
> # CPU  : Model (Number of physical cores) @ CPU frequency
> # RAM  : Amount
> # GPU  : Brand, model and RAM amount
> # Disk : Brand, model and size
> ```

#### 2. Create disk configuration

For the disks configuration, two paths are available:

* use [disko](https://github.com/nix-community/disko)
* use a Bash script

Depending on the chosen path, a `disks.nix` or a `disks.sh` file must be created under `hosts/new-host`.

It is also possible to have additional `disks-*.nix` files which will be applied after the main `disks.nix` file.

#### 3. Declare the host

Declare the host in [`flake.nix`](./flake.nix):

```nix
{
  # ...

  outputs = {
    # ...

    nixosConfigurations = {
      # ...

      new-host = libx.mkHost { hostname = "new-host"; username = "nicolas"; desktop = "gnome"; };
    }
  }
}
```

The `username` argument must match one of the subdirectories of `hosts/common/users`.\
The `desktop` argument must match one of the subdirectories of `hosts/common/desktop`.

Failing to provide a valid `username` or `desktop` will not prevent the installation to succeed. However, without a `username` only the `root` user will be present on the installed system and without a `desktop` the installed system will not have a graphical interface.

### 👨‍🦱 Add a user

> **TODO**: fill when home-manager configurations are up.

## 👨‍💻 Usage

### 📥 Install NixOS

There are two installation method provided on the desktop ISO:

* Run `install-system` from a terminal (recommended, only install option for the console ISO)
* Use the graphical Calamares installer (basic NixOS installation, not using this flake)

The `install-system` command is a binary wrapping the [`install.sh`](./hosts/common/users/nixos/install.sh) Bash script. Learn how to use it by reading its help message:

```shell
install-system -h
```

In a nutshell, the script will:

* use [disko](https://github.com/nix-community/disko) (or a Bash script) to automatically partition and format the disks
* prepare the host gpg identity
* install NixOS from this flake
* copy this flake to the target user’s home directory in `~/nixstrap`
* apply home-manager configuration if it exists

> [!IMPORTANT]
> In order to proceed with the installation, a GPG private key known to the [sops config](./.sops.yaml) is required to be in the local keyring.
>
> ```shell
> gpg --import <gpg-private-key>
> ```
>
> See the [secrets handling](#️-secrets-handling) section to learn more about why.

### ✨ Applying Changes

If not done already, clone this repo to `~/nixstrap`:

```shell
git clone git@github.com:nicolas-goudry/nix-config.git ~/nixstrap

# Or with curl + tar
curl -sL https://github.com/nicolas-goudry/nix-config/archive/main.tar.gz
tar xzf nix-config-main.tar.gz
mv nix-config-main ~/nixstrap
```

Then the NixOS or home-manager configurations can be rebuilt. Note that this flake takes the approach to split both configurations, therefore changes are applied separately. This is mainly for separation of concern and to avoid rebuilding the whole system every time, but also because some hosts are non-NixOS.

#### NixOS

```shell
sudo nixos-rebuild switch --flake '.#<host>'
```

#### Home Manager

```bash
home-manager switch -b backup --flake '.#<username@host>'
```

### 🕵️ Secrets handling

#### Concept

To handle secrets management, this flake uses [sops-nix](https://github.com/Mic92/sops-nix). To avoid stuffing all secrets in a single secrets file, multiple secrets files are scattered across directories. The goal is to keep secrets that belong together in a single secrets file (ie. all wireless networks authentication details are in `hosts/common/networks/secrets.yaml`, users password and sensitive files are in `hosts/common/users/<user>/secrets.yaml`, …).

#### Opinionated approach

This flake uses GPG keys to handle secrets. There is a main GPG key for physical users and a GPG key derived from SSH for each host. All secrets files are encrypted with the users GPG public keys and hosts GPG public keys. To decrypt the secrets, at least one valid GPG private key is required to be in the host keyring.

#### Handling new hosts

When installing NixOS on a new host, the `install-system` script handles the creation of the new host GPG key, stores it under the [`.keys`](./.keys) directory, adds it to the [sops config file](./.sops.yaml) and re-encrypt all secrets afterward.

If a new host were to be added without the `install-system` script, the following operations should be done manually:

* derive new host GPG public key from its SSH RSA key

  ```shell
  sudo nix run 'nixpkgs#ssh-to-pgp' -- -i /etc/ssh/ssh_host_rsa_key -o ./.keys/<hostname>.pub
  ```

* add the key fingerprint to [`.sops.yaml`](./.sops.yaml)

  ```yaml
  keys:
    hosts:
      - &new-host <fingerprint>
  creation_rules:
    - key_groups:
        - pgp:
            - *new-host
  ```

* import all hosts and users public keys to local keyring

  ```shell
  gpg --import .keys/*.pub
  gpg --import <path-to-users-keys>
  ```

* re-encrypt all secrets

  ```shell
  find . -type f -name 'secrets.y*ml' -exec sops updatekeys -y {} \;
  ```

* commit and push changes to repository

## 📝 TODO

* Work configuration
* Add [impermanence](https://github.com/nix-community/impermanence)
* Hosts
  * Fix ISO image `.gnupg` directory of `nixos` user owned by `root` (see [Discourse post](https://discourse.nixos.org/t/gnupg-user-directory-owned-by-root/43561/1))
  * Fix issue with bépo layout on Gnome login screen which fails to input `_` character
  * Fix NVIDIA GPU not used (see [Discourse post](https://discourse.nixos.org/t/force-using-nvidia-gpu/41729/5))
  * Write a `disks.sh` script to format g-xps disk while keeping Windows dual boot
* Home
  * Finish adding and configuring programs
    * ❓ [aria2](https://github.com/aria2/aria2) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.aria2.enable)</sup></sub>
    * ❓ [atuin](https://github.com/atuinsh/atuin) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.atuin.enable)</sup></sub>
    * [awscli](https://github.com/aws/aws-cli) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.awscli.enable)</sup></sub>
    * [borgmatic](https://torsion.org/borgmatic/) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.borgmatic.enable)</sup></sub>
    * [broot](https://github.com/Canop/broot) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.broot.enable)</sup></sub> / [fd](https://github.com/sharkdp/fd) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.fd.enable)</sup></sub> / [fzf](https://github.com/junegunn/fzf) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.fzf.enable)</sup></sub> / [yazi](https://github.com/sxyazi/yazi) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.yazi.enable)</sup></sub>
    * chromium <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.chromium.enable)</sup></sub>
    * git <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.git.enable)</sup></sub>
      * work-specific configuration
      * auto-providing of SSH key pairs
    * ❓ gpg <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.gpg.enable)</sup></sub>
    * [k9s](https://github.com/derailed/k9s) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.k9s.enable)</sup></sub>
    * [lazygit](https://github.com/jesseduffield/lazygit) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.lazygit.enable)</sup></sub>
    * [mpv](https://github.com/mpv-player/mpv) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.mpv.enable)</sup></sub>
    * [mr](https://myrepos.branchable.com/) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.mr.enable)</sup></sub>
    * ❓ [ncspot](https://github.com/hrkfdn/ncspot) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ncspot.enable)</sup></sub>
    * [neovim](https://github.com/neovim/neovim) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.neovim.enable)</sup></sub>
    * [nix-index](https://github.com/nix-community/nix-index) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.nix-index.enable)</sup></sub>
    * [rbw](https://github.com/doy/rbw) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.rbw.enable)</sup></sub>
    * [ripgrep](https://github.com/BurntSushi/ripgrep) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ripgrep.enable)</sup></sub>
    * ❓ ssh <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ssh.enable)</sup></sub>
    * [tealdeer](https://github.com/dbrgn/tealdeer) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.tealdeer.enable)</sup></sub> - <sub><sup>replaces tldr</sup></sub>
    * [thefuck](https://github.com/nvbn/thefuck) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.thefuck.enable)</sup></sub>
    * ❓ thunderbird <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.thunderbird.enable)</sup></sub>
    * [tmux](https://github.com/tmux/tmux) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.tmux.enable)</sup></sub> / [zellij](https://github.com/zellij-org/zellij) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zellij.enable)</sup></sub>
    * ❓ [vscode](https://github.com/microsoft/vscode) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.vscode.enable)</sup></sub>
    * ❓ [yt-dlp](https://github.com/yt-dlp/yt-dlp) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.yt-dlp.enable)</sup></sub>
    * [zoxide](https://github.com/ajeetdsouza/zoxide) <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zoxide.enable)</sup></sub>
    * zsh <sub><sup>[HM](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zsh.enable)</sup></sub>
      * user `dirHashes`
