# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdc";
  boot.loader.grub.useOSProber = true;

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "398abbb0";

  boot.kernelParams = [ "zfs.swappiness=1" "zfs.min_free_kbytes=4294967296" "zfs.watermark_scale_factor=200" ];

  fileSystems."/mediapool/vmbackups" = {
    device = "mediapool/vmbackups";
    fsType = "zfs";
  };

  fileSystems."/mediapool/archive" = {
    device = "mediapool/archive";
    fsType = "zfs";
  };

  services.zfs.autoScrub.enable = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking = {
    networkmanager.enable = true;
    hostName = "nas";
    domain = "nas.alebordo.it";
    #interfaces.enp2s0.ipv4.addresses = [{
    #  address = "192.168.1.28";
    #  prefixLength = 24;
    #}];
    #defaultGateway = "192.168.1.1";
    #nameservers = ["1.1.1.1" "8.8.8.8"];
    useDHCP = false;
    interfaces.enp2s0.useDHCP = false;
    bridges.br0.interfaces = [ "enp2s0" ];
    interfaces.br0 = {
      ipv4.addresses = [{ address = "192.168.1.28"; prefixLength = 24; }];
      ipv4.routes = [{ address = "0.0.0.0"; prefixLength = 0; via = "192.168.1.1"; }];
    };
    nameservers = [ "192.168.1.1" ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Rome";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.aless = {
    isNormalUser = true;
    description = "aless";
    group = "aless";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  users.groups.aless = {};

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     zfs_2_3
     smartmontools
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };
  users.users."aless".openssh.authorizedKeys.keyFiles = [
    /home/aless/.ssh/authorized_keys
  ];

  services.samba = {
    enable = true;
    package = pkgs.samba; # Ensure Samba is installed
    openFirewall = true;

    # Global settings
    settings = {
      global = {
          "workgroup" = "HOME";
          "realm" = "alebordo.it"; 
          "netbios name" = "nas";
          "server string" = "ZFS Archive Server";
          "dns proxy" = "no";

          "security" = "user";
          "map to guest" = "bad user";
          "server signing" = "auto";
          "client signing" = "auto";

          "log level" = "1";
          "log file" = "/var/log/samba/%m.log";
          "max log size" = "1000";

          "socket options" = "TCP_NODELAY IPTOS_LOWDELAY";
          "read raw" = "yes";
          "write raw" = "yes";
          "use sendfile" = "yes";
          "min receivefile size" = "16384";
          "aio read size" = "16384";
          "aio write size" = "16384";

          "server multi channel support" = "yes";

          "load printers" = "no";
          "printing" = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";

          "unix charset" = "UTF-8";
          "dos charset" = "CP932";
      };

      # Define the share
      "archive" = {
        path = "/mediapool/archive";
        comment = "ZFS Archive Share";
        validUsers = [ "aless" ];
        invalidUsers = [ "root" ];
        browseable = true;
        readOnly = false;
        writable = true;
        createMask = "0644";
        forceCreateMode = "0644";
        directoryMask = "0755";
        forceDirectoryMode = "0755";
        forceUser = "aless";
        forceGroup = "aless";
        vetoFiles = [ "._*" ".DS_Store" ".Thumbs.db" ".Trashes" ];
        deleteVetoFiles = true;
        followSymlinks = true;
        wideLinks = true;
        eaSupport = true;
        inheritAcls = true;
        hideUnreadable = true;
      };
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  networking.firewall = {
    enable = true;
    extraCommands = ''
      iptables -I FORWARD 1 -i br0 -j ACCEPT
      iptables -I FORWARD 1 -o br0 -j ACCEPT
    '';
  };
  services.fail2ban.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
