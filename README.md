# KDE SVG Cursor to Hyprcursor

Convert vector cursor in KDE SVG cursor format to hyprcursor format

---

Usage: ./convert.nu \<source\> [OPTIONS] \
Options:
- --working `<working-dir>` \
    working directory, defaults to `./working` \
    the working directory is used to store files at the [working state](https://github.com/hyprwm/hyprcursor/blob/main/hyprcursor-util/README.md#states), \
    effectively are source files that hyprcursor-util can understand
- --target `<target-dir>` \
    target directory, defaults to `./target`
- --cursors-directory `<cursors-dir>` \
    cursors directory name, defaults to `hyprcursors` \
    cursor file will under `<working-dir>/<cursors-dir>/example-cursor/example-cursor.svg`
- --resize-algorithm: `<resize-algorithm>` \
    defaults to `bilinear`, \
    currently available value: `bilinear`, `nearest`, `none`

Example Usage:
```sh
./convert.nu /share/icons/Breeze_Light
```

SVG and meta.toml file will be output to `<working-dir>/<cursors-dir>/example-cursor/{example.svg, meta.toml}`, \
then, the compiled hyprcursor will be output to `<target-dir>/theme_<cursor-name>/<cursors-dir>/example-cursor.hlc`, \
where the `<cursor-name>` is defined in `index.theme` from the source

---

Dependencies: nu, nu_plugin_formats, hyprcursor-util
- Arch: nushell, hyprcursor
- Nix: nushell, nushellPlugins.formats, hyprcursor

> [!NOTE]
> This script use the core plugin `formats` to parse `index.theme` file, \
> to load a plugin only for this script, you can use the `--plugins` flag of nushell
> ```sh
> nu --plugins "[<path-to-plugin-formats>]" ./convert.nu <source> # other options...
> ```

## References

### KDE SVG Cursor

- format specification: <https://invent.kde.org/plasma/breeze/-/blob/master/cursors/svg-cursor-format.md>

### Hyprcursor

- format standard: <https://standards.hyprland.org/hyprcursor>
- <https://github.com/hyprwm/hyprcursor/blob/main/docs/MAKING_THEMES.md>
- hyprcursor-util: <https://github.com/hyprwm/hyprcursor/blob/main/hyprcursor-util/README.md>

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
