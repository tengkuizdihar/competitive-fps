# Table Of Contents
- [Table Of Contents](#table-of-contents)
- [How To Contribute](#how-to-contribute)
- [Technicalities](#technicalities)
  - [Project Structure](#project-structure)
  - [Tools](#tools)
  - [Programming Style](#programming-style)
  - [Supported Operating System for Developers](#supported-operating-system-for-developers)

# How To Contribute

Developer and designer alike can contribute by doing the following things in order.
1. They must be interested in game development in general or are willingly spare their free time as the owner did for the project.
2. Read the proposal or at least skim it a bit to understand the general philosophy of the project.
3. Search for unsolved issues or create a new one. Be it bugs, new features, or beyond.
4. Create a Merge Request for it.
5. I'll be notified if there's any unmerged or new issues.

# Technicalities

## Project Structure

Right now the project is structured in such a way to avoid confusion and made to be as simple as possible.

```
- root
    - .gitlab-ci.yml    # The
    - compegodot        # The main implementation of PROPOSAL.md, primarily using Godot Engine.
        - addons        # This is where all of the addons lives. To add more, make sure that it's compatible with this project's open source license.
        - assets        # Filled with 3D models, audio, and other files related to artist/programmer generated content.
        - interfaces    # Not to be confused with "User Interface", this one is filled with programming interfaces that can be used for contracts between nodes.
        - materials     # This folder is filled with ready to use material resources.
        - player        # Everything related to how a player would work should be placed inside of this folder.
        - world_item    # Any item that the player might came across to should be placed inside of this folder. Including the levels.
        - global.gd     # Sometimes there's a need to define globally accessible classes and enums and you should put it here.
        - state.gd      # Globally managed variables that you can use for produce-consume pattern.
        - util.gd       # Any function that can be generally utilized should be placed here.
        - score.gd      # It's basically a specialized `state.gd` that only cares about scores. Could be deprecated in the future in favor of `state.gd`.
    - documents         # Documentation about the game's design, philosophy, and more.
    - arts              # Folder filled by art related file such as blend files for Blender (Graphic Software).
```

The folder `compegodot` is filled with the implementation of the proposal made in Godot Engine 3.x. Right now it's the only implementation available, but other contributor are free to create their own implementation based on the proposal. The second main folder is called `documents`. Right now it's filled mainly with the proposal itself and any media related to the project's documentation.

## Tools

These are the usual tools used for developing the game. Every single one of these tools are encouraged to be Free Libre Open Source Software.

- Game Engine
  - [Godot Engine](https://godotengine.org/), a FLOSS game engine licensed under the permissive [MIT license](https://github.com/godotengine/godot/blob/master/LICENSE.txt) is a great choice to prototype and finalize the proposed game. It's a very well developed engine with a lot of potential for extensive usage because it has integration with other languages such as [Rust Programming Language](https://www.rust-lang.org/).
- Text Editor
  - [VSCodium](https://vscodium.com/), A FLOSS fork of Visual Studio Code made by none other than [Microsoft](https://www.youtube.com/watch?v=Oo-cIGVaOYE).

## Programming Style

TODO: add a programming style that could help other contributors to align the styles with the intended one

## Supported Operating System for Developers

Currently, the main developer for this game uses linux as a daily driver. It's however not a limitation towards other people in other platform to contribute to the project. Right now the platforms you as a developer should use are:

- Linux
  - Any mainstream linux flavor that you're using should be able to run the engine.
- Windows
  - Any version of modern windows such as Windows 10 should be able to run the engine. Currently it is not known whether the project could be developed in an older Windows version such as Windows 8, Windows 7, or Windows Vista.
- Mac
  - Currently, it is not known whether the project could be developed in an Apple based environment or not.
