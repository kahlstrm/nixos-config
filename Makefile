# We need to do some OS switching below.
UNAME := $(shell uname)

NIXNAME ?= $(shell hostname)

HAS_NH := $(shell command -v nh 2>/dev/null)
# Determine the 'nh' subcommand based on OS
ifeq ($(HAS_NH),)
    NH_SUBCMD :=
else
    ifeq ($(UNAME), Darwin)
        NH_SUBCMD := darwin
    else
        NH_SUBCMD := os
    endif
endif

switch:
ifneq ($(HAS_NH),)
	nh $(NH_SUBCMD) switch -a -H "${NIXNAME}" .
else ifeq ($(UNAME), Darwin)
	nix build --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${NIXNAME}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${NIXNAME}"
else
	sudo nixos-rebuild switch --flake ".#${NIXNAME}"
endif

build:
ifneq ($(HAS_NH),)
	nh $(NH_SUBCMD) build -a -H "${NIXNAME}" .
else ifeq ($(UNAME), Darwin)
	nix build --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${NIXNAME}.system"
else
	sudo nixos-rebuild build --flake ".#${NIXNAME}"
endif

repl:
ifneq ($(HAS_NH),)
	nh $(NH_SUBCMD) repl -H "${NIXNAME}" .
else
	$(error repl command only requires nh)
endif

test:
ifeq ($(UNAME), Darwin)
	nix build ".#darwinConfigurations.${NIXNAME}.system"
	./result/sw/bin/darwin-rebuild test --flake "$$(pwd)#${NIXNAME}"
else
	sudo nixos-rebuild test --flake ".#$(NIXNAME)"
endif

bootloader:
ifeq ($(UNAME), Darwin)
	$(error boot only work on Linux)
else
	sudo nixos-rebuild switch --install-bootloader --flake ".#${NIXNAME}"
endif

# TODO: look into deploy-rs or something to make this work on darwin as well
deploy-pannu:
ifeq ($(UNAME), Darwin)
	$(error boot only work on Linux)
else
	nixos-rebuild switch --build-host pannu --target-host pannu --flake . --use-remote-sudo
endif

fmt:
	fd '\.nix$$'| xargs nixfmt
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
.PHONY: wsl switch build test
wsl:
	 nix build --extra-experimental-features nix-command --extra-experimental-features flakes ".#nixosConfigurations.wsl.config.system.build.tarballBuilder"
	 sudo result/bin/nixos-wsl-tarball-builder
