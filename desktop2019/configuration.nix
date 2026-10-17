{ config, pkgs, ... }:

{
  networking.hostName = "desktop2019";
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = false;
  boot.lanzaboote = { enable = true; pkiBundle = "/var/lib/sbctl"; };
  environment.systemPackages = with pkgs; [ sbctl ];
  home-manager.users.jeremiah.home.packages = with pkgs; [ discord ];

  services.pipewire.wireplumber.extraConfig."51-disable-avermedia"."monitor.alsa.rules" = [{
    matches = [{ "device.vendor.id" = "0x07ca"; "device.product.id" = "0x1570"; }];
    actions.update-props."device.disabled" = true;
  }];

  system.stateVersion = "26.05"; # Did you read the comment?
}
