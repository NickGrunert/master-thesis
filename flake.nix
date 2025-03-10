{
  description = "Master Thesis Flake containing Typst";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, flake-parts,... }@inputs: 
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [
      "x86_64-linux"
    ];
    perSystem = { pkgs, ... }: {
      formatter = pkgs.alejandra;
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          (writeShellScriptBin "run" ''
            typst watch thesis.typ
          '')
          typst
          typst-live
        ];
      };
    };
  };
}
