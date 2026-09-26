{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, lanzaboote, nixos-wsl, ... }: let
    experimental-features = [ "nix-command" "flakes" "ca-derivations" ];

    home = { pkgs, lib, ... }: let
      passwordsSync = pkgs.writeShellScript "passwords-sync" ''
        set -euo pipefail
        args=(
          googledrive: "$HOME" --include "/passwords.kdbx" --resilient --recover --max-lock 2m
          --conflict-resolve newer --verbose
        )
        if [ ! -e "$HOME/passwords.kdbx" ]; then
          args=(--resync "''${args[@]}")
        fi
        exec ${pkgs.rclone}/bin/rclone bisync "''${args[@]}"
      '';
    in {
      home.stateVersion = "26.05";

      nix.package = lib.mkDefault pkgs.nix;
      nix.settings.experimental-features = lib.mkDefault experimental-features;

      home.packages = with pkgs; [
        alacritty
        clang-tools
        claude-code
        fzf
        git
        pkgs.home-manager
        keepassxc
        libqalculate
        ripgrep
        tmux
        wl-clipboard
      ];

      programs.bash = {
        enable = true;
        bashrcExtra = builtins.readFile ./files/.bashrc;
        profileExtra = builtins.readFile ./files/.profile;
      };

      home.file = {
        ".alacritty.toml".source = ./files/.alacritty.toml;
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

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."*".AddKeysToAgent = "yes";
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
          EnvironmentFile = "%h/.secrets.env";
          ExecStart = "${passwordsSync}";
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
            ''set -a; . "$HOME/.secrets.env"; set +a; exec ${passwordsSync}''
          ];
          RunAtLoad = true;
          StartInterval = 300;
        };
      };
    };

    nixosBase = { pkgs, ... }: {
      imports = [
        home-manager.nixosModules.home-manager
      ];

      nix.settings.experimental-features = experimental-features;

      nixpkgs.config.allowUnfree = true;

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
        users.jeremiah = {
          imports = [ home ];
          services.ssh-agent.enable = true;
          systemd.user.sessionVariables.SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/ssh-agent";
        };
      };
    };

    nixosGraphical = { pkgs, ... }: let
      # MRU and fuzzy-find switching
      swayYasm = pkgs.buildGoModule {
        pname = "sway-yasm";
        version = "35828bcc70e5bd12562fab84fbdc7040b502b73a";
        src = pkgs.fetchFromGitHub {
          owner = "pancsta";
          repo = "sway-yasm";
          rev = "35828bcc70e5bd12562fab84fbdc7040b502b73a";
          hash = "sha256-KlnuHRGGVT7pG6NqYN6pu3hEB/c11huzqZ3U4MfEH/I=";
        };
        vendorHash = "sha256-s06eql0H3tBQY5ApwRpXNijjIM1tOcPfpZZgBEBJqQs=";
        subPackages = [ "cmd/sway-yasm" ];
        patches = [ ./patches/sway-yasm-title-events.patch ]; # gets it to listen to title changes
      };

      # Lets $mod+hjkl move between both sway windows and neovim splits
      nvimSway = pkgs.stdenv.mkDerivation {
        pname = "nvim-sway";
        version = "0.2.2";
        src = pkgs.fetchFromGitHub {
          owner = "cjab";
          repo = "nvim-sway";
          rev = "8a7f1aeb2b78d454d7cd47c6edda43fb11a35525";
          hash = "sha256-wLOMj/KEI5srAQy4oBsuUBkm2nTtLcgY8p9DAbClpU4=";
        };
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.cjson pkgs.msgpack-c ];
        installPhase = ''
          mkdir -p $out/bin
          cp nvim-sway $out/bin/
          mkdir -p $out/share
          cp -r man $out/share/
        '';
      };
    in {
      imports = [ nixosBase ];

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      home-manager = {
        users.jeremiah = {
          systemd.user.services.sway-yasm = {
            Unit.Description = "sway-yasm daemon";
            Service = {
              ExecStart = "${swayYasm}/bin/sway-yasm daemon --autoconfig=false";
              Environment = "YASM_LOG=1";
              Restart = "on-failure";
              RestartSec = 1;
            };
          };

          home.packages = with pkgs; [
            foot
            jq
            nvimSway
            swayYasm clipman
            swayidle
            swaylock
            waybar
          ];
          home.file = {
            ".config/foot/foot.ini".source = ./files/foot.ini;
            ".config/sway/config".source = ./files/sway/config;
            ".config/sway/term.sh".source = ./files/sway/term.sh;
          };
        };
      };

      services.greetd = {
        enable = true;
        useTextGreeter = true;
        settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
      };
      programs.sway = { enable = true; wrapperFeatures.gtk = true; };
      xdg.portal = { enable = true; wlr.enable = true; };
      security.pam.services.swaylock = {};

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
    homeConfigurations."jeremiah@ubuntu" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };

      modules = [
        home
        {
          targets.genericLinux.enable = true;
          home.username = "jeremiah";
          home.homeDirectory = "/home/jeremiah";
        }
      ];
    };

    nixosConfigurations.desktop2019 = nixpkgs.lib.nixosSystem {
      modules = [
        nixosGraphical
        ./desktop2019/configuration.nix
        lanzaboote.nixosModules.lanzaboote
      ];
    };

    nixosConfigurations.jk-laptop = nixpkgs.lib.nixosSystem {
      modules = [
        nixosGraphical
        ./jk-laptop/configuration.nix
      ];
    };

    nixosConfigurations.desktop2019-wsl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-wsl.nixosModules.default
        nixosBase
        {
          wsl.enable = true;
          wsl.defaultUser = "jeremiah";
          system.stateVersion = "26.05";
        }
      ];
    };
  };
}
