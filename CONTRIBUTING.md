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
1. They must be intrested in game development in general or are willingly spare their freetime as the owner did for the project.
2. Read the proposal or at least skim it a bit to understand the philosophy of the project.
3. Search for unsolved issues or create a new one. Be it bugs, new features, or anything else.
4. Create a Merge Request for it.
5. I'll be notified if there's any unmerged or new issues. 

# Technicalities

## Project Structure

Right now the project is structured in such a way to avoid confusion and made to be as simple as possible.

```
- root
    - compegodot
        - assets        # Filled with 3D models, audio, and other files related to artist/programmer generated content.
        - interfaces    # Not to be confused with User Interface, this one is filled with interface class that can be used for abstraction between nodes.
        - materials     # This folder is filled with ready to use materials.
        - player        # Everything related to how a player would work should be placed inside of this folder.
        - world_item    # Any item that the player might came across to should be placed inside of this folder.
        - global.gd     # Sometimes there's a need to define globally accessible classes and enums and you should put it here.
        - state.gd      # Globally managed variables that you can use for produce-consume pattern.
        - util.gd       # Any function that can be generally utilized should be placed here.
    - documents         # Documentation about the game's design, philosophy, and more.
```

The folder `compegodot` is filled with the implementation of the proposal made in Godot Engine 3.x. Right now it's the only implementation available, but other contributor are free to create their own implementation based on the proposal. The second main folder is called `documents`. Right now it's filled mainly with the proposal itself and any media related to the project.

## Tools

These are the usual tools used for developing the game. Every single one of these tools are encouraged to be Free Libre Open Source Software.

- Game Engine
  - [Godot Engine](https://godotengine.org/), a FLOSS game engine licensed under the permissive [MIT license](https://github.com/godotengine/godot/blob/master/LICENSE.txt) is a great choice to upstart the flow of the game. It's a very well developed engine with a lot of potential for extensive usage because it has integration with other languages such as [Rust Programming Language](https://www.rust-lang.org/).
- Text Editor
  - [VSCodium](https://vscodium.com/), A FLOSS fork of Visual Studio Code made by none other than [Microsoft](https://www.youtube.com/watch?v=Oo-cIGVaOYE).

## Programming Style

TODO: add a programming style that could help other contributors to align the styles with the intended one

## Supported Operating System for Developers

Currently, the main developer for this game uses linux as a daily driver. It's however not a limitation towards other people in other platform to contribute to the project. Right now the platforms you as a developer should use are:

- Linux
  - Any mainstream linux flavor that you're using will probably run the engine just fine.
- Windows
  - Although the opinion of the programmer differs towards anything made by Microsoft, it's safe to say that support on that OS is good enough for usual use of the engine.
