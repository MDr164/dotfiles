{ config, pkgs, ... }:

{
    home = {
        username = "user";
        homeDirectory = "/home/user";
        stateVersion = "22.05";
        packages = [
            btop
            neovim
        ];
    }
}
