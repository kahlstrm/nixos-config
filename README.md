# NixOS System Configurations

This repository contains my Nix-configurations for my devices. I use Nix as
my main package manager for my development.

This repository is originally based on from Mitchell Hashimoto's
[nixos-config](https://github.com/mitchellh/nixos-config).
After messing around on my own and trying out different configurations,
I deemed it an excellent starting point for my setup, as it both had clear
structure and was quite intuitive to me at least.

> [!CAUTION]
> Don't run the setups without reading the source. If you blindly run this,
> your system may be changed in ways that you don't want. Read the source!

> [!IMPORTANT]
> To make the Neovim configuration work, the repository must be
> cloned to `~/nixos-config`. The configuration relies on a symlink
> to allow direct mutability of the files.

## Using an existing configuration

By using existing configurations you can replicate entire setups across machines,
while with separate configurations you can add device/use-case specific configurations
such as different username, git email, and/or packages. As the system hostname is
set to the configuration name, it is usually recommended to create new configurations
for each system simultaneously in use to avoid overlap.

If you are installing this to a device that previously was using other package management
solutions such as `homebrew`, creating a new configuration is recommended.

Existing configurations can be found in `flake.nix`:

```nix
{
    # ...
 outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      ...
    }@inputs:
let
    # ....
in
    {
      # configuration name
      #                    |                        |
      #                    v                        v
      darwinConfigurations.mac-personal = mkSystem "mac-personal" {
        system = "aarch64-darwin";
        user = "kalski";
        # ...
      };
    # ...
    };
}
```

In the snippet the configuration is named `mac-personal`, it expects the
username for the OS user to be `kalski` and it targets Apple Silicon Macs,
denoted by the `system`-attribute being `aarch64-darwin`.
In this instance, the configuration name needed in the next section would be `mac-personal`.

## Creating a new configuration

Creating a new configuration involves two steps:

1. Adding a new system entry to `flake.nix`
   - This can be done with copy-paste from existing configuration,
     just involves changing the configuration name, and username, email,
     or architecture depending on your system.
   - **Note:** make sure to change the configuration name in both places,
     as there are 2, one for the actual configuration name,
     and one as function argument for `mkSystem`.
2. Creating a machine-specific configuration under `machines`-directory
   with the name `<configuration-name>.nix`
   - Easiest is to copy-paste an existing configuration
     (e.g. `machines/mac-personal.nix`) and editing that to your needs.
   - For NixOS installations, you need to also generate some hardware configuration
     during the installation phase. More on that in

After these two steps, you have a new configuration ready to be switched to.

## Switching to a configuration

Once you have the configuration that matches your machine, you can run the following,
replacing `<configuration-name>` with the correct configuration name:

```shell
NIXNAME=<configuration-name> make
```

This should setup the system for this configuration and switch to it.
For new systems on macOS that aren't logged in to App Store, some errors might come
up that need manual configuration/setup. After configuring these, repeat the previous
command again until it succeeds.

The configuration sets the system hostname to match the configuration name,
so running `make` again works without specifying `NIXNAME` explicitly.

You can verify this by spawning a new shell and running:

```shell
~/nixos-config (main*) » hostname
<configuration-name>
```

If the name of the configuration you specified is returned,
it means that everything worked.

## Setup (macOS/Darwin)

To utilize the Mac setup, first install Nix using the
[nix-installer](https://github.com/DeterminateSystems/nix-installer)
by Determinate Systems.

```shell
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install
```

Once that is installed, clone this repo and run `make`.
You should be met with an error message that looks something like:

```shell
~/nixos-config (main*) » make
error: flake 'git+file:///Users/kahlstrm/nixos-config' does not provide attribute 'packages.aarch64-darwin.darwinConfigurations.foo.system', 'legacyPackages.aarch64-darwin.darwinConfigurations.foo.system' or 'darwinConfigurations.foo.system'
```

This is expected and means everything is going great :).

Depending on the machine you are installing this on, you can either use
an existing configuration or you can create a new configuration for this new machine.

## `nh`

The configuration sets up [`nh`](https://github.com/viperML/nh), a helper
that comes with some niceties over using plain Nix commands.
The main commands that are useful are:

- `nh <darwin|os> switch`: switches to a new with tree of builds, diff and confirmation.
  Can be invoked from anywhere on the system.
- `nh <darwin|os> repl`: Loads the configuration in a Nix REPL, useful for debugging.
- `nh search`: a nixpkgs search tool.

For MacOS systems use the `darwin` subcommand and `os` for NixOS.

> [!IMPORTANT]
> similar to the Neovim configuration, the repository must be
> cloned to `~/nixos-config` for `nh` to work from everywhere on the system.

## Setup (NixOS/VM)

You can download the Minimal NixOS ISO from the
[official NixOS download page](https://nixos.org/download.html#nixos-iso).

### VM configuration preparation

Create a VM with the following settings. My configurations
are tested with `virt-manager` on Linux, `UTM` on MacOS, and `Hyper-V` on Windows
so you might face issues on other virtualization solutions without minor changes.

NOTE: for virt-manager remember to check `Customize configuration before install`,
as that is needed to have UEFI booting working.

#### Installation setup (virt-manager)

- ISO: NixOS 24.11 or later.
- CPU/Memory: I give at least half my cores and at least 8GB RAM.
- Disk: 25 GB+

##### Configuration customization

- Overview: Hypervisor Firmware needs to be set to UEFI (Important! Otherwise the
  installed system won't boot).
- Video QXL: Model Virtio with 3D acceleration enabled (needed for OpenGL).
- Display: Listen type as None, OpenGL checked.

After this, click `Begin installation` and boot into the Nixos Installer.

#### Installation setup (Hyper-V Manager)

The default options with `Quick Create` should work apart from increasing the memory
to at least 8GB.

#### Installation setup (UTM)

Following defaults with increasing memory to at least 8GB is recommended.
Remember to choose virtualize instead of emulate for best performance.
Virtualiziation gives better performance but you are limited to host system
architecture.

### Installation

After booting the minimal ISO, you should be spawned into a tty-shell as user `nixos`.

If you are setting a new machine (i.e. real, physical hardware), a recommended setup is the following:

- Add a password to `nixos` with `passwd` to enable SSH-access
- Get IP address from `ifconfig`
- `ssh` from another machine into the system and run commands from there.

For disk partitioning, follow [NixOS Partitiong and Formatting Guide](https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning).
Note: creating swap for VM is not necessary and not configured in current config.
Follow the installation steps as well until you have mounted `nixos` to `/mnt` and
`boot` to `/mnt/boot`.

#### Creating and installing a new hardware configuration

For new non-VM machine, you need to [add a new configuration](#creating-a-new-configuration)
to `flake.nix` and create a new configuration file to `machines/<host-name-here>.nix`.

##### Generating hardware configuration

- In the new machine, run `nixos-generate-config --root /mnt`
- On another machine on the same network and while in the root of this repo:

```sh
NEW_HOST_IP_ADDRESS=<ip-address-here>
NEW_HOST_NAME=<host-name-here>
scp nixos@$NEW_HOST_IP_ADDRESS:/mnt/etc/nixos/hardware-configuration.nix machines/hardware/$NEW_HOST_NAME.nix
```

Running this should add the following file:

```sh
└── machines
    └── hardware
        └── <host-name-here>.nix
```

Remember to update the machine configuration file to import the hardware configuration you just imported:

```nix
{
  pkgs,
  currentSystemUser,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware/<host-name-here>.nix
  ];
  # ...
}
```

After this you should have a functional configuration for the new hardware.

#### Installing a configuration (real hardware)

What we do now is the following:

On your another machine in the repo root, run `nixos-rebuild build --flake .#<new-host-name-here>`.
With the configuration name as `pannu` The input should look something like this:

```sh
~/nixos-config (main) » nixos-rebuild build --flake .#$NEW_HOST_NAME
building the system configuration...
Done. The new configuration is /nix/store/1csa3s4ql5ry6hhnfpfrk4273hgc230s-nixos-system-pannu-25.11.20250520.2795c50
```

Note the path to the new system configuration. that is going to be needed soon.

Next, we copy the closure to the new machine:

```sh
nix-copy-closure --to nixos@$NEW_HOST_IP_ADDRESS result
```

After this, SSH into the host.

```sh
ssh nixos@$NEW_HOST_IP_ADDRESS
```

This is where we need the path for the new system configuration.

On the new host:

```sh
sudo nixos-install --no-root-passwd --system <new-system-configuration-path>
```

This will install the configuration to `/mnt`, but it will not set a password for
your user. Let's set it with the following command:

```sh
sudo nixos-enter -c 'passwd <username>'
```

With `username` being the user you have set in your configuration.

After this, rebooting the system should boot you into the system.

#### Installing a configuration (VM)

After this you can install the flake directly by running the command:

NOTE: `vm-amd` is the configuration that is intended for systems with AMD CPUs,
for Intel systems you'd need to use a different configuration.

```sh
sudo nixos-install --no-root-passwd --flake github:kahlstrm/nixos-config#vm-amd
```

This will install the configuration to `/mnt`, but it will not set a password for
your user. Let's set it with the following command:

```sh
sudo nixos-enter -c 'passwd <username>'
```

With `username` being the user you have set in your configuration.

After this, rebooting the system should boot you into the system.

## Setup (WSL)

I use Nix to build a WSL root tarball for Windows. I then have my entire
Nix environment on Windows in WSL too, which I use to for example run
Neovim amongst other things. My general workflow is that I only modify
my WSL environment outside of WSL, rebuild my root filesystem, and
recreate the WSL distribution each time there are system changes. My system
changes are rare enough that this is not annoying at all.

To create a WSL root tarball, you must be running on a Linux machine
that is able to build `x86_64` binaries (either directly or cross-compiling).
My `aarch64` VMs are all properly configured to cross-compile to `x86_64`
so if you're using my NixOS configurations you're already good to go.

Run `make wsl`. This will take some time but will ultimately output
a tarball in `./result/tarball`. Copy that to your Windows machine.
Once it is copied over, run the following steps on Windows:

```shell
wsl --import nixos .\nixos .\path\to\tarball.tar.gz

wsl -d nixos

# Optionally, make it the default
wsl -s nixos
```

After the `wsl -d` command, you should be dropped into the Nix environment.
_Voila!_
