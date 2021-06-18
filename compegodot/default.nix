# Author        : Tengku Izdihar Rahman Amanullah (tengkuizdihar:matrix.org)
# License       : MIT
# Description   : Create an environment to develop and run Godot Game Engine + GDNative + Rust

let
    # Enable support for OpenGL/Vulkan for your drivers
    nixgl = import (fetchTarball "https://github.com/guibou/nixGL/archive/7d6bc1b21316bab6cf4a6520c2639a11c25a220e.tar.gz") {};

    # Pin the version of the nix package repository
    pkgs = import (fetchTarball "https://github.com/nixos/nixpkgs/archive/5658fadedb748cb0bdbcb569a53bd6065a5704a9.tar.gz") {};
in
    pkgs.mkShell.override { stdenv = pkgs.clangStdenv; } {
        buildInputs = [
            # Rust related dependencies
            pkgs.rustc
            pkgs.cargo
            pkgs.rustfmt
            pkgs.libclang

            # Godot Engine Editor
            pkgs.godot

            # The support for OpenGL/Vulkan
            nixgl.nixGLDefault
        ];

        # Point bindgen to where the clang library would be
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";

        # For rust language server and rust-analyzer
        RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

        # Alias the godot engine to use nixGL
        shellHook = ''
            alias godot="nixGL godot -e"
        '';
    }