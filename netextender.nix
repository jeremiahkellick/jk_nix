{ config, pkgs, lib, ... }: let
  netExtender = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "netextender";
    version = "10.2.850";

    src = pkgs.fetchurl {
      url = "https://software.sonicwall.com/NetExtender/"
        + "NetExtender.Linux-${finalAttrs.version}.x86_64.tgz";
      hash = "sha256-Vqa0LS8YQRRdR/HJyTswVLKa35LaKFdxX3j7yqdBQbw=";
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall
      install -Dm755 netExtender $out/bin/netExtender
      install -Dm755 nxMonitor $out/bin/nxMonitor
      install -Dm644 sslvpn $out/share/netExtender/sslvpn
      install -Dm644 ca-bundle.crt $out/share/netExtender/ca-bundle.crt
      install -Dm644 netExtender.1 $out/share/man/man1/netExtender.1
      runHook postInstall
    '';

    postFixup = ''
      for bin in netExtender nxMonitor; do
        wrapProgram $out/bin/$bin --prefix PATH : ${lib.makeBinPath (with pkgs; [
          bash coreutils gawk gnugrep gnused iproute2 kmod nettools ppp
          wireguard-tools
        ])}
      done
    '';

    meta.license = lib.licenses.unfree;
  });

  fhsLinks = {
    "/bin/bash" = "${pkgs.bash}/bin/bash";
    "/bin/cp" = "${pkgs.coreutils}/bin/cp";
    "/bin/echo" = "${pkgs.coreutils}/bin/echo";
    "/sbin/ifconfig" = "${pkgs.nettools}/bin/ifconfig";
    "/sbin/ip" = "${pkgs.iproute2}/bin/ip";
    "/sbin/lsmod" = "${pkgs.kmod}/bin/lsmod";
    "/sbin/route" = "${pkgs.nettools}/bin/route";
    "/usr/bin/wg" = "${pkgs.wireguard-tools}/bin/wg";
    "/usr/bin/wg-quick" = "${pkgs.wireguard-tools}/bin/wg-quick";
    "/usr/sbin/ip" = "${pkgs.iproute2}/bin/ip";
    "/usr/sbin/netExtender" = "${netExtender}/bin/netExtender";
    "/usr/sbin/nxMonitor" = "${netExtender}/bin/nxMonitor";
    "/usr/sbin/pppd" = "${pkgs.ppp}/sbin/pppd";
    # The wrapper, so it picks up the system resolvconf configuration.
    "/usr/sbin/resolvconf" = "/run/current-system/sw/bin/resolvconf";
    "/usr/share/netExtender" = "${netExtender}/share/netExtender";
  };
in {
  environment.systemPackages = [ netExtender ];

  boot.kernelModules = [ "ppp_generic" "ppp_async" ];

  # /etc/ppp is deliberately kept out of environment.etc (i.e. services.pppd
  # stays off) so that it's a plain writable directory netExtender can scribble
  # its pid files, resolv.conf backup and route scripts into.
  systemd.tmpfiles.rules = [
    "d /etc/ppp 0755 root root -"
    "d /etc/ppp/peers 0755 root root -"
    "C+ /etc/ppp/peers/sslvpn 0644 root root - ${netExtender}/share/netExtender/sslvpn"
  ] ++ lib.mapAttrsToList (path: target: "L+ ${path} - - - - ${target}") fhsLinks;

  # Writes /etc/ppp/{ip,ipv6}-{up,down} and the route helper scripts.
  systemd.services.netextender-install = {
    description = "Install SonicWall NetExtender pppd hooks";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${netExtender}/bin/netExtender -i";
    };
  };

  systemd.services.netextender = {
    description = "SonicWall NetExtender SSL VPN tunnel";
    after = [ "network-online.target" "netextender-install.service" ];
    wants = [ "network-online.target" ];
    requires = [ "netextender-install.service" ];
    serviceConfig = {
      Type = "exec";
      StateDirectory = "netextender";
      Environment = "HOME=/var/lib/netextender";
      EnvironmentFile = "${config.users.users.jeremiah.home}/.secrets.env";
      ExecStart = "${netExtender}/bin/netExtender"
        + " -u \${NET_EXTENDER_USER}"
        + " -p \${NET_EXTENDER_PASSWORD}"
        + " -d \${NET_EXTENDER_DOMAIN}"
        + " \${NET_EXTENDER_SERVER}";
      KillSignal = "SIGTERM";
      TimeoutStopSec = 30;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
