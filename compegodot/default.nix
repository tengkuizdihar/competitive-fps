# Author        : Tengku Izdihar Rahman Amanullah (tengkuizdihar:matrix.org)
# License       : MIT
# Description   : Create an environment to develop and run Godot Game Engine

let
    # Enable support for OpenGL/Vulkan for your drivers
    nixgl = import (fetchTarball "https://github.com/guibou/nixGL/archive/7d6bc1b21316bab6cf4a6520c2639a11c25a220e.tar.gz") {};

    # Pin the version of the nix package repository
    pkgs = import (fetchTarball "https://github.com/nixos/nixpkgs/archive/860b56be91fb874d48e23a950815969a7b832fbc.tar.gz") {};
in
    pkgs.mkShell {
        buildInputs = [
            # Godot Engine Editor
            pkgs.godot

            # The support for OpenGL/Vulkan
            nixgl.nixGLDefault
        ];

        # Alias the godot engine to use nixGL
        shellHook = ''
            alias godot="nixGL godot -e"
        '';
    }