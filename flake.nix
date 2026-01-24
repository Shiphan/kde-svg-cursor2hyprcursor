{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
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
    };
}
