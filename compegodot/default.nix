# Author        : Tengku Izdihar Rahman Amanullah (tengkuizdihar:matrix.org)
# License       : MIT
# Description   : Create an environment to develop and run Godot Game Engine

{
  # Enable support for OpenGL/Vulkan for your drivers
  nixgl ? import (fetchTarball "https://github.com/guibou/nixGL/archive/7d6bc1b21316bab6cf4a6520c2639a11c25a220e.tar.gz") { }
, # Pin the version of the nix package repository
  pkgs ? import (fetchTarball "https://github.com/nixos/nixpkgs/archive/1caf78f4bf5cba45eb04c45a3c9b46bde8fa50e0.tar.gz") { }
,
}:

let
  template = (import (./nix/godot_export_template.nix) { godot = pkgs.godot; lib = pkgs.lib; });
in
pkgs.stdenv.mkDerivation rec {
  name = "competitive-fps";

  src = ./.;

  buildInputs = [
    # Godot Engine Editor
    pkgs.godot

    # The support for OpenGL/Vulkan
    nixgl.nixGLDefault

    # Seemingly required libraries
    # https://github.com/NixOS/nixpkgs/blob/c5051e2b5fe9fab43a64f0e0d06b62c81a890b90/pkgs/games/oh-my-git/default.nix
    pkgs.alsa-lib
    pkgs.gcc-unwrapped.lib
    pkgs.git
    pkgs.libGLU
    pkgs.xorg.libX11
    pkgs.xorg.libXcursor
    pkgs.xorg.libXext
    pkgs.xorg.libXfixes
    pkgs.xorg.libXi
    pkgs.xorg.libXinerama
    pkgs.xorg.libXrandr
    pkgs.xorg.libXrender
    pkgs.libglvnd
    pkgs.libpulseaudio
    pkgs.zlib
    pkgs.udev
  ];

  nativeBuildInputs = [
    pkgs.godot-headless
    pkgs.autoPatchelfHook
  ];

  buildPhase = ''
    runHook preBuild

    # Cannot create file '~/.config/godot/projects/...'
    export HOME=$TMPDIR

    # Link the export-templates to the expected location. The --export commands
    # expects the template-file at .../templates/3.x.x.stable/linux_x11_64_release
    # with 3.x.x being the version of godot.
    mkdir -p $HOME/.local/share/godot
    ln -s ${template}/share/godot/templates $HOME/.local/share/godot
    mkdir -p $out/share/${name}

    godot-headless --export "Linux/X11" $out/share/${name}/${name}

    runHook postBuild
  '';


  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    ln -s $out/share/${name}/${name} $out/bin

    # Patch binaries.
    interpreter=$(cat $NIX_CC/nix-support/dynamic-linker)
    patchelf \
      --set-interpreter $interpreter \
      --set-rpath ${pkgs.lib.makeLibraryPath buildInputs} \
      $out/share/${name}/${name}

    # Setting icon
    # mkdir -p $out/share/pixmaps
    # cp images/${name}.png $out/share/pixmaps/${name}.png

    runHook postInstall
  '';

  # Alias the godot engine to use nixGL
  shellHook = ''
    alias godot="nixGL godot -e"
  '';
}
