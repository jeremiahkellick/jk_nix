{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, lanzaboote, home-manager, ... }: let
    home = { pkgs, lib, ... }: {
      home.stateVersion = "26.05";

      home.packages = with pkgs; [
        alacritty
        clang-tools
        claude-code
        fzf
        git
        keepassxc
        ripgrep
        tmux
        wl-clipboard
      ];

      home.file = {
        ".alacritty.toml".source = ./files/.alacritty.toml;
        ".bash_profile".source = ./files/.bash_profile;
        ".bashrc".source = ./files/.bashrc;
        ".clang-format".source = ./files/.clang-format;
        ".git-completion.bash".source = ./files/.git-completion.bash;
        ".git-prompt.sh".source = ./files/.git-prompt.sh;
        ".gitconfig".source = ./files/.gitconfig;
        ".gitignore".source = ./files/.gitignore;
        ".tmux.conf".source = ./files/.tmux.conf;
        ".tmux-linux.conf".source = ./files/.tmux-linux.conf;
        ".tmux-macos.conf".source = ./files/.tmux-macos.conf;
        ".zprofile".source = ./files/.zprofile;
      };

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        initLua = builtins.readFile ./files/init.lua;
        plugins = with pkgs.vimPlugins; [
          (pkgs.vimUtils.buildVimPlugin {
            name = "jkellick-one-dark-vim";
            src = pkgs.fetchFromGitHub {
              owner = "jeremiahkellick";
              repo = "jkellick-one-dark-vim";
              rev = "64dda0e293db18ca9b650c7326c1b0070cc01316";
              hash = "sha256-6mtSLJEER/jjyasBR09QpmP9AyD1CmLpe04w+E5lkqM=";
            };
          })
          blink-cmp
          fzf-lua
          gitsigns-nvim
          luasnip
          nvim-lspconfig
          (nvim-treesitter.withPlugins (p: with p; [ c cpp lua objc query vim vimdoc ]))
          nvim-treesitter-textobjects
          undotree
          vim-fugitive
          vim-repeat
          vim-sleuth
          vim-surround
          vim-tmux-navigator
          vim-unimpaired
        ];
      };

      # Synchronize passwords.kdbx
      programs.rclone = {
        enable = true;
        remotes.googledrive.config = { type = "drive"; scope = "drive"; };
      };
      systemd.user.services.passwordssync = {
        Unit = { Requires = [ "rclone-config.service" ]; After = [ "rclone-config.service" ]; };
        Service = {
          Type = "oneshot";
          EnvironmentFile = "%h/secrets.env";
          ExecStart = ''
            ${pkgs.rclone}/bin/rclone bisync googledrive: %h --include "/passwords.kdbx" \
	        --resilient --recover --max-lock 2m --conflict-resolve newer --verbose
          '';
        };
      };
      systemd.user.timers.passwordssync = {
        Timer = { OnStartupSec = "1min"; OnUnitActiveSec = "5min"; };
        Install.WantedBy = [ "timers.target" ];
      };
      # macOS equivalent
      launchd.agents.passwordssync = {
        enable = true;
        config = {
          ProgramArguments = [
            "/bin/sh" "-c"
            ''set -a; . "$HOME/secrets.env"; set +a; exec \
	          ${pkgs.rclone}/bin/rclone bisync googledrive: "$HOME" --include "/passwords.kdbx" \
	              --resilient --recover --max-lock 2m --conflict-resolve newer --verbose''
          ];
          RunAtLoad = true;
          StartInterval = 300;
        };
      };
    };

    nixos = { pkgs, lib, ... }: {
      imports = [
        home-manager.nixosModules.home-manager
      ];

      nix.settings.experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
      nixpkgs.config.allowUnfree = true;

      boot.loader.systemd-boot.enable = lib.mkDefault true;
      boot.loader.efi.canTouchEfiVariables = true;
      networking.networkmanager.enable = true;
      time.timeZone = "America/Denver";
      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
      users.users."jeremiah" = {
        isNormalUser = true;
        description = "Jeremiah";
        extraGroups = [ "networkmanager" "wheel" ];
        packages = with pkgs; [
          # packages for only this user
        ];
      };
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        users.jeremiah = home;
      };

      services.displayManager.sddm.enable = true;
      services.desktopManager.plasma6.enable = true;

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      services.printing.enable = true;

      programs.firefox.enable = true;
    };
  in {
    nixosConfigurations.desktop2019 = nixpkgs.lib.nixosSystem {
      modules = [
        nixos
        ./desktop2019/configuration.nix
        lanzaboote.nixosModules.lanzaboote
      ];
    };
  };
}
