# KDE SVG Cursor to Hyprcursor

## Nix

This repo provide a flake that can generate package/derivation

- Example `flake.nix`:
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    kde-svg-cursor2hyprcursor = {
      url = "github:Shiphan/kde-svg-cursor2hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, kde-svg-cursor2hyprcursor }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        # use generatePackage
        breeze-dark-hyprcursor = pkgs.callPackage (kde-svg-cursor2hyprcursor.generatePackage {
          source = "${pkgs.kdePackages.breeze}/share/icons/breeze_cursors";
          cursorName = "Breeze Dark";
          # optional
          renameTo = "Breeze_Dark";
          # whether if you want the content of source (e.g. `index.theme`, cursors, cursors_scalable) be linked to this package,
          # optional, default to false
          linkSource = true;
        }) { };

        # use generateDerivation, accept arguments as generatePackage
        breeze-light-hyprcursor = kde-svg-cursor2hyprcursor.generateDerivation pkgs.callPackage {
          source = "${pkgs.kdePackages.breeze}/share/icons/Breeze_Light";
          cursorName = "Breeze Light";
          linkSource = true;
        };

        # or just use the package provided by the flake
        breeze-dark-hyprcursor-1 = kde-svg-cursor2hyprcursor.packages.${system}.breeze-dark-hyprcursor;
        breeze-light-hyprcursor-1 = kde-svg-cursor2hyprcursor.packages.${system}.breeze-light-hyprcursor;
      };
    };
}
```
