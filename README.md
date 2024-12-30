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

## Setup (macOS/Darwin)

To utilize the Mac setup, first install Nix using the
[nix-installer](https://github.com/DeterminateSystems/nix-installer)
by Determinate Systems.

```shell
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install
```

Once that is installed, clone this repo and run `make`.
You should be met with the following error message:

```shell
~/nixos-config (main*) » make
Makefile:13: *** Error, undefined NIXNAME, check README.md for instructions.  Stop.
```

This is expected and means everything is going great :).

Depending on the machine you are installing this on, you can either use
an existing configuration or you can create a new configuration for this new machine.

By using existing configurations you can replicate entire setups across machines,
while with separate configurations you can add device/use-case specific configurations
such as different username, git email, and/or packages. As the system hostname is
set to the configuration name, it is usually recommended to create new configurations
for each system simultaneously in use to avoid overlap.

If you are installing this to a device that previously was using other package management
solutions such as `homebrew`, creating a new configuration is recommended.

### Finding an existing configuration

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
        email = personalEmail;
      };
    # ...
    };
}
```

In the snippet the configuration is named `mac-personal`, it expects the
username for the OS user to be `kalski` and it targets Apple Silicon Macs,
denoted by the `system`-attribute being `aarch64-darwin`.
In this instance, the configuration name needed in the next section would be `mac-personal`.

### Creating a new configuration

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

After these two steps, you have a new configuration ready to be switched to.

### Switching to a configuration

Once you have the configuration that matches your machine, you can run the following,
replacing `<configuration-name>` with the correct configuration name:

```shell
NIXNAME=<configuration-name> make
```

This should setup the system for this configuration and switch to it.
For new systems that aren't logged in to App Store, some errors might come up that
need manual configuration/setup. After configuring these, repeat the previous command
again until it succeeds.

The configuration sets the system hostname to match the configuration name,
so running `make` again works without specifying `NIXNAME` explicitly.

You can verify this by spawning a new shell and running:

```shell
~/nixos-config (main*) » hostname
<configuration-name>
```

If the name of the configuration you specified is returned,
it means that everything worked.

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

## Setup (NixOS/VM) WIP

**Note:** This section is still untested for my configuration
and remains a copy-paste from the original repository.

**Note:** This setup guide will cover VMware Fusion because that is the
hypervisor I use day to day. The configurations in this repository also
work with UTM (see `vm-aarch64-utm`) and Parallels (see `vm-aarch64-prl`) but
I'm not using that full time so they may break from time to time. I've also
successfully set up this environment on Windows with VMware Workstation and
Hyper-V.

You can download the NixOS ISO from the
[official NixOS download page](https://nixos.org/download.html#nixos-iso).
There are ISOs for both `x86_64` and `aarch64` at the time of writing this.

Create a VMware Fusion VM with the following settings. My configurations
are made for VMware Fusion exclusively currently and you will have issues
on other virtualization solutions without minor changes.

- ISO: NixOS 23.05 or later.
- Disk: SATA 150 GB+
- CPU/Memory: I give at least half my cores and half my RAM, as much as you can.
- Graphics: Full acceleration, full resolution, maximum graphics RAM.
- Network: Shared with my Mac.
- Remove sound card, remove video camera, remove printer.
- Profile: Disable almost all keybindings
- Boot Mode: UEFI

Boot the VM, and using the graphical console, change the root password to "root":

```shell
$ sudo su
$ passwd
# change to root
```

At this point, verify `/dev/sda` exists. This is the expected block device
where the Makefile will install the OS. If you setup your VM to use SATA,
this should exist. If `/dev/nvme` or `/dev/vda` exists instead, you didn't
configure the disk properly. Note, these other block device types work fine,
but you'll have to modify the `bootstrap0` Makefile task to use the proper
block device paths.

Also at this point, I recommend making a snapshot in case anything goes wrong.
I usually call this snapshot "prebootstrap0". This is entirely optional,
but it'll make it super easy to go back and retry if things go wrong.

Run `ifconfig` and get the IP address of the first device. It is probably
`192.168.58.XXX`, but it can be anything. In a terminal with this repository
set this to the `NIXADDR` env var:

```shell
export NIXADDR=<VM ip address>
```

The Makefile assumes an Intel processor by default. If you are using an
ARM-based processor (M1, etc.), you must change `NIXNAME` so that the ARM-based
configuration is used:

```shell
 export NIXNAME=vm-aarch64
```

**Other Hypervisors:** If you are using Parallels, use `vm-aarch64-prl`.
If you are using UTM, use `vm-aarch64-utm`. Note that the environments aren't
_exactly_ equivalent between hypervisors but they're very close and they
all work.

Perform the initial bootstrap. This will install NixOS on the VM disk image
but will not setup any other configurations yet. This prepares the VM for
any NixOS customization:

```shell
make vm/bootstrap0
```

After the VM reboots, run the full bootstrap, this will finalize the
NixOS customization using this configuration:

```shell
make vm/bootstrap
```

You should have a graphical functioning dev VM.

At this point, I never use Mac terminals ever again. I clone this repository
in my VM and I use the other Make tasks such as `make test`, `make switch`, etc.
to make changes my VM.

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
