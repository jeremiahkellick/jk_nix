{ config, pkgs, ... }:

{
  networking.hostName = "desktop2019";
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = false;
  boot.lanzaboote = { enable = true; pkiBundle = "/var/lib/sbctl"; };
  environment.systemPackages = with pkgs; [ sbctl ];

  system.stateVersion = "26.05"; # Did you read the comment?
}
