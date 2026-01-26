{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nushell
          nushellPlugins.formats
          hyprcursor
        ];
        NU_PLUGIN_FORMATS = "${pkgs.nushellPlugins.formats}/bin/nu_plugin_formats";
      };
      formatter.${system} = pkgs.nixfmt-tree;

      generatePackage = import ./generate-package.nix;
      generateDerivation = callPackage: args: callPackage (self.generatePackage args) { };

      packages.${system} = {
        breeze-dark-hyprcursor = self.generateDerivation pkgs.callPackage {
          source = "${pkgs.kdePackages.breeze}/share/icons/breeze_cursors";
          cursorName = "Breeze Dark";
          linkSource = true;
        };
        breeze-light-hyprcursor = self.generateDerivation pkgs.callPackage {
          source = "${pkgs.kdePackages.breeze}/share/icons/Breeze_Light";
          cursorName = "Breeze Light";
          linkSource = true;
        };
      }
      // (
        let
          # TODO: currently animated cursor in oxygen don't have the `delay` property in metadata,
          # wait for this mr: <https://invent.kde.org/plasma/oxygen/-/merge_requests/80>
          oxygen = pkgs.kdePackages.oxygen.overrideAttrs (previousAttrs: {
            patches = (previousAttrs.patches or [ ]) ++ [
              (pkgs.fetchpatch2 {
                url = "https://invent.kde.org/plasma/oxygen/-/merge_requests/80.patch";
                hash = "sha256-j8Uwlizq4+h0utTnQ4GKXc5i2eXl576X2fJgfz1JEKo=";
              })
            ];
          });
        in
        {
          oxygen-black-hyprcursor = self.generateDerivation pkgs.callPackage {
            source = "${oxygen}/share/icons/Oxygen_Black";
            cursorName = "Oxygen Black";
            linkSource = true;
          };
          oxygen-blue-hyprcursor = self.generateDerivation pkgs.callPackage {
            source = "${oxygen}/share/icons/Oxygen_Blue";
            cursorName = "Oxygen Blue";
            linkSource = true;
          };
          oxygen-white-hyprcursor = self.generateDerivation pkgs.callPackage {
            source = "${oxygen}/share/icons/Oxygen_White";
            cursorName = "Oxygen White";
            linkSource = true;
          };
          oxygen-yellow-hyprcursor = self.generateDerivation pkgs.callPackage {
            source = "${oxygen}/share/icons/Oxygen_Yellow";
            cursorName = "Oxygen Yellow";
            linkSource = true;
          };
          oxygen-zion-hyprcursor = self.generateDerivation pkgs.callPackage {
            source = "${oxygen}/share/icons/Oxygen_Zion";
            cursorName = "Oxygen Zion";
            linkSource = true;
          };
        }
      );
    };
}
