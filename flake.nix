{
  description = "NixOS VPS flake (host-based layout + home-manager)";

  inputs = {
    # 使用 GitHub 官方源(全球 CDN,速度快)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 中国大陆用户如需使用清华镜像,可替换为:
    # nixpkgs.url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-24.11";
    # home-manager.url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/home-manager.git?ref=release-24.11";
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      hostDir = "caijq";
      hostName = "caijq";
      username = "caijq";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      mkHost = hostDir:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit hostName username;
          };
          modules = [
            ./hosts/${hostDir}
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit hostName username;
              };
              home-manager.users.${username} = import ./home/default.nix;
            }
          ];
        };
    in {
      formatter.${system} = pkgs.alejandra;

      checks.${system}.format = pkgs.runCommand "format-check" {
        nativeBuildInputs = [ pkgs.alejandra ];
        src = ./.;
      } ''
        cd "$src"
        alejandra --check .
        touch "$out"
      '';

      nixosConfigurations.${hostName} = mkHost hostDir;
    };
}
