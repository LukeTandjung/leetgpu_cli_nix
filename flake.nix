{
  description = "LeetGPU CLI Nix Wrapper";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      systems,
      ...
    }:
    let
      version = "v1.0.0";
      pkgs = import nixpkgs { inherit system; };
      systems = import systems;

      inherit (pkgs) fetchUrl lib;
      inherit (pkgs.stdenv) mkDerivation;
      inherit (nixpkgs.lib) genAttrs;
    in
    {
      packages = genAttrs (systems) (
        system:
        mkDerivation {
          inherit version;

          pname = "leetgpu_cli";
          src = fetchUrl {
            url =
              system:
              if system == "x86_64-linux" then
                "https://cli.leetgpu.com/dist/${version}/leetgpu-linux-amd64"
              else if system == "aarch64-linux" then
                "https://cli.leetgpu.com/dist/${version}/leetgpu-linux-arm64"
              else if system == "x86_64-darwin" then
                "https://cli.leetgpu.com/dist/${version}/leetgpu-macos-amd64"
              else if system == "aarch64-darwin" then
                "https://cli.leetgpu.com/dist/${version}/leetgpu-macos-arm64"
              else
                throw "Unsupported system: ${system}";
            sha256 =
              system:
              if system == "x86_64-linux" then
                "sha256-GlJzzXkHTrW7Yg4nC1tD1hAlj4YMeveG7DibKu5UDxM="
              else if system == "aarch64-linux" then
                "sha256-PA6u/xecC0FWQKECH+GwZJrRTr382RG+tWhLm08IlW0="
              else if system == "x86_64-darwin" then
                "sha256-HMP042zVK3DmVxHsPx/sgZr+0k5mFcJD6XiihLqN7wg="
              else if system == "aarch64-darwin" then
                "sha256-jEiSHDsLopiYmdsXx36SJKxv1xEI2PRRI6H7ienCskU="
              else
                throw "Unsupported system: ${system}";
          };
          dontUnpack = true;
          installPhase = ''
            mkdir -p "$out/bin"
            cp "$src" "$out/bin/leetgpu"
            chmod +x "$out/bin/leetgpu"
          '';
          meta = with lib; {
            description = "LeetGPU CLI";
            license = licenses.unfree;
            platforms = platform.all;
            mainProgram = "leetgpu";
          };
        }
      );

      homeManagerModules.default =
        { pkgs, ... }:
        {
          home.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system} ];
        };
    };
}
