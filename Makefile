# Function to check if a variable is set, Make is love, Make is life
# https://gist.github.com/bbl/bf4bf5875d0c705c4cd78d264f98a8b1
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
    $(error Error, undefined $1$(if $2, ($2)), check README.md for instructions))
# We need to do some OS switching below.
UNAME := $(shell uname)

switch:
	$(call check_defined,NIXNAME)
ifeq ($(UNAME), Darwin)
	nix build --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${NIXNAME}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${NIXNAME}"
else
	sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --flake ".#${NIXNAME}"
endif

build:
	$(call check_defined,NIXNAME)
ifeq ($(UNAME), Darwin)
	nix build --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${NIXNAME}.system"
else
	sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild build --flake ".#${NIXNAME}"
endif


test:
	$(call check_defined,NIXNAME)
ifeq ($(UNAME), Darwin)
	nix build ".#darwinConfigurations.${NIXNAME}.system"
	./result/sw/bin/darwin-rebuild test --flake "$$(pwd)#${NIXNAME}"
else
	sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild test --flake ".#$(NIXNAME)"
endif

# This builds the given NixOS configuration and pushes the results to the
# cache. This does not alter the current running system. This requires
# cachix authentication to be configured out of band.
# TODO: determine if this is necessary for my use 
# cache:
#	$(call require_nixname)
#	nix build '.#nixosConfigurations.$(NIXNAME).config.system.build.toplevel' --json \
#		| jq -r '.[].outputs | to_entries[].value' \
#		| cachix push kahlstrm-nixos-config


# Build a WSL installer
.PHONY: wsl
wsl:
	 nix build ".#nixosConfigurations.wsl.config.system.build.installer"
