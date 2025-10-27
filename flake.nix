{
  description = "LeetGPU CLI Nix Wrapper";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      version = "v1.0.0";
      urls = {
        "x86_64-linux" = "https://cli.leetgpu.com/dist/${version}/leetgpu-linux-amd64";
        "aarch64-linux" = "https://cli.leetgpu.com/dist/${version}/leetgpu-linux-arm64";
        "x86_64-darwin" = "https://cli.leetgpu.com/dist/${version}/leetgpu-macos-amd64";
        "aarch64-darwin" = "https://cli.leetgpu.com/dist/${version}/leetgpu-macos-arm64";
      };
      hashes = {
        "x86_64-linux" = "sha256-GlJzzXkHTrW7Yg4nC1tD1hAlj4YMeveG7DibKu5UDxM=";
        "aarch64-linux" = "sha256-PA6u/xecC0FWQKECH+GwZJrRTr382RG+tWhLm08IlW0=";
        "x86_64-darwin" = "sha256-HMP042zVK3DmVxHsPx/sgZr+0k5mFcJD6XiihLqN7wg=";
        "aarch64-darwin" = "sha256-jEiSHDsLopiYmdsXx36SJKxv1xEI2PRRI6H7ienCskU=";
      };
      systems = nixpkgs.lib.systems.flakeExposed;

      inherit (nixpkgs.lib) genAttrs;
    in {
      packages = genAttrs (systems) (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          inherit (pkgs) fetchurl lib autoPatchelfHook;
          inherit (pkgs.stdenv) mkDerivation isLinux;
        in {
          leetgpu_cli = mkDerivation {
            inherit version;

            pname = "leetgpu_cli";
            src = fetchurl {
              url = urls.${system} or (throw "Unsupported system: ${system}");
              sha256 = hashes.${system} or (throw "Unsupported system: ${system}");
            };
            dontUnpack = true;
            nativeBuildInputs = lib.optionals isLinux [ autoPatchelfHook ];
            buildInputs = lib.optionals isLinux [
              pkgs.stdenv.cc.cc.lib
            ];

            installPhase = ''
              mkdir -p "$out/bin"
              cp "$src" "$out/bin/leetgpu"
              chmod +x "$out/bin/leetgpu"
            '';

            meta = with lib; {
              description = "LeetGPU CLI";
              license = licenses.unfree;
              platforms = platforms.all;
              mainProgram = "leetgpu";
            };
          };

          default = self.packages.${system}.leetgpu_cli;
        }
      );

      homeManagerModules.default =
        { config, lib, pkgs, ... }:
        {
          options.programs.leetgpu = {
            enable = lib.mkEnableOption "LeetGPU CLI";

            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.leetgpu_cli;
              description = "The leetgpu package to use";
            };
          };

          config = lib.mkIf config.programs.leetgpu.enable {
            home.packages = [ config.programs.leetgpu.package ];
          };
        };
    };
}
