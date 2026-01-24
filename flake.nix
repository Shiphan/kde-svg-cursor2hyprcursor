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
      };
    };
}
