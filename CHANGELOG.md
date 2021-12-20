# Changelog
Here be all the changes to the released version of the game.

# Version 0.0.5
The fifth ever release of my game! After some time, the changes now are noticeable! Some of them are quite game changing like improving the movement and shooting mechanics, option menus, config file, and more!

The changelog for this version are:

1. A new weapon type: Sniper Rifles! You can use it by picking it up in the training grounds on the Guns Table.
2. A new training mode: Spray Training! Use it so you can determine how accurate you are at disposing your foes with the help of a never-changing-position-target-practice!
3. A new menu: Pause Menu! This menu is used mainly to go into the main menu without closing the game and can be accessed using the escape button.
4. A new sub in main menu: Option Menu! Right now it could only be used to adjust the volume of the game and the mouse sensitivity.
5. Use the scene path instead of the PackedScene to avoid recursive nodes error.
6. Fix the algorithm for movement which now fixes jitters when going against the wall and it's a LOT more stable.
7. Refactor player's export names into lower case.
8. Add a function to `Utils` for clamping vector on a certain axis
9. Deactivate auto bhop for player. For now.

That's all for today. I hope for your feedback and enjoyment when playing it. See you around!

# Version 0.0.4
The fourth ever release of my game!
As always, the changes are incremental and really small to be seen, but it's there and I'm planning to always building it, brick by brick, until it's done!
The changelog for this version are:

1. Make a new level for training! Right now there's only one training option in it, and a bunch of well placed guns, but more to come!
2. Upgrade the project from Godot 3.3.3 to Godot 3.4, and it miraculously fixed a bug regarding standing on top of moving platform. Now the player could stand on it, and stay in place!
3. Player now will correctly reduce their speed when going against the wall. I fixed it using one line of code, after experimenting with the one that takes  massive refactoring.
4. And other fixes that I haven't note!

# Version 0.0.3
The third ever release of the game! This time, it's all about gun play and fixing bugs. There's still a lot more refactoring and polishing to be done, but in the mean time, here be the third release.

## Changelog
* Implements inaccuracy, spray pattern, recoil, and aim punch based upon an excellent [video made by TheWarOwl](https://www.youtube.com/watch?v=octRQYnnuig).
* Make a lot of adjustment on how input is processed.
* Resolves a lot of Godot warning.
* Fixes how crouching works so it doesn't move when it's on a slanted surface.
* Make the crouch faster.
* Upgrade the version of the game engine from Godot 3.3.2 to Godot 3.3.3.
* Remove Rust as a language of choice for GDNative, for now.
* Enable exporting the game automatically via CI/CD for Microsoft's Windows, Linux, Apples' Macintosh, and the Web.


# Version 0.0.2
The second ever version of the game is out. It doesn't have that many improvements, mostly bug fixes and tweaks.

# Version 0.0.1
The first ever tagged release of my in-development game! The game itself is in a very early state, sorry for the bugs! In the game development, this would be considered pre-alpha of the project.

## Warning
There is no sound/music available for this build except for the gun shot, knife swooshing, and the ding when you hit a target.

## Basic Character Manipulation:
1. Move with the infamous "WASD" keys.
2. Jump using the spacebar.
3. Crouch using the ctrl key.
4. Swap your weapon with the "Q" key.
5. Switch weapons with the numbers key
  * Key "1" for primary weapon (which is unavailable because I haven't implemented it yet)
  * Key "2" for secondary weapon
  * Key "3" for melee weapon
6. Drop your weapon using "G", will not work for knife.
7. Pick up your dropped weapon by getting close enough to it and press E.
8. Use your weapon (shoot the gun or swing the knife) using the left key.

### How to play the game.
1. Shoot the available target and observe that counter go up!
2. Shoot the reset button to reset the scoreboard.

I hope you like it!
