# Yet another dotfile repo

> **!! WARNING !!** \
> These files are not intended to be blindly copied but rather taken as reference \
> **!! WARNING !!**

## What's in here?

Dotfiles aka Linux configuration files that are managed with [chezmoi](https://chezmoi.io), a custom installer shell script meant to be invoked from an Arch live medium and my Nix configuration as part of the dotfiles.

Yes you read that right, this script installs Arch Linux but then the Nix package manager on top of that.
The reason for that is simple: I like to declaratively manage my user available packages and make use of the nix-shell but also don't want to deal with the quirks of NixOS and use a sane enough base which in this case is Arch.

*This repository is work in progress as I'm currently working on creating a rather complex rootfs layout which caters to my needs*
