{
  source,
  cursorName,
  renameTo ? cursorName,
  linkSource ? false,
}:

{
  lib,
  runCommand,
  hyprcursor,
  nushell,
  nushellPlugins,
}:

runCommand "kde-svg-cursor2hyprcursor"
  {
    nativeBuildInputs = [
      nushell
      hyprcursor
    ];
  }
  (
    ''
      nu --plugins "[${nushellPlugins.formats}/bin/nu_plugin_formats]" \
        ${./convert.nu} \
        "${source}"

      mkdir -p "$out/share/icons"
      mv "target/theme_${cursorName}" "$out/share/icons/${renameTo}"
    ''
    + lib.optionalString linkSource ''
      ln -s "${source}"/* "$out/share/icons/${renameTo}/"
    ''
  )
