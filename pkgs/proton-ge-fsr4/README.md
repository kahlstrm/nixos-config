# Proton GE FSR 4 Package

Custom Nix package that patches Proton GE with AMD FSR 4 DLL for enhanced upscaling in games.

## Overview

This package takes the standard `proton-ge-bin` and injects AMD's FSR 4 DLL (`amdxcffx64.dll`) to enable FidelityFX Super Resolution 4.0 support in Steam games.

## Files

- `default.nix` - Main package definition
- `update.sh` - Script to check for new FSR versions and get SHA256 hashes

## Usage

### Installing the Package

Add to your NixOS configuration:

```nix
programs.steam.extraCompatPackages = [
  (pkgs.callPackage ./pkgs/proton-ge-fsr4 { })
];
```

### Updating to New FSR Version

1. **Check all available versions:**
   ```bash
   ./update.sh
   ```

2. **Test specific version:**
   ```bash
   ./update.sh 67D435F7d97000
   ```

3. **Update default.nix:**
   - Copy the version ID and SHA256 hash from the script output
   - Update `fsrVersion` and `sha256` in `default.nix`

### Update Script Options

```bash
./update.sh [OPTIONS] [VERSION]

Options:
  --debug, -d    Enable debug output
  --help, -h     Show help message

Arguments:
  VERSION        Test specific FSR version (e.g., 67D435F7d97000)
```

## How It Works

1. Downloads the specified FSR DLL from AMD's servers
2. Injects it into Proton GE's wine directory at `files/lib/wine/amdprop/`
3. Patches the proton script to skip version validation
4. Makes FSR 4 available to games running through this Proton version

## Requirements

- `curl` - for downloading DLLs
- `strings` (binutils) - for extracting version info
- `file` - for validating DLL files
- `sha256sum` - for hash calculation
- `nix` - for hash format conversion