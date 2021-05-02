# Table Of Contents
- [Table Of Contents](#table-of-contents)
- [THe Solver Series](#the-solver-series)
  - [Project Structure](#project-structure)
  - [How to Contribute](#how-to-contribute)
  - [Roadmap](#roadmap)
    - [**Aim-Solver**](#aim-solver)
    - [**Dispute-Solver**](#dispute-solver)
    - [**Team-Solver**](#team-solver)

# The Solver Series

This is an open source project about the most versatile and fun **first person shooter**. There's already an implementation made in Godot Engine, but every single changes is based on the proposal inside of PROPOSAL.odt. Right now I'm the only one who is developing it on my free time, but you're welcome to contribute to the project.

For any question, you can contact me on matrix which is listed in https://tengkuizdihar.gitlab.io/contact/.

## Project Structure

Right now the project is structured in such a way to avoid confusion and made to be as simple as possible.

```
- root
    - compegodot
    - documents
```

The folder `compegodot` is filled with the implementation of the proposal made in Godot Engine 3.x. Right now it's the only implementation available, but other contributor are free to create their own implementation based on the proposal. The second main folder is called `documents`. Right now it's filled mainly with the proposal itself and any media related to the project.

## How to Contribute

Developer and designer alike can contribute by doing the following things in order.
1. They must be intrested in game development in general or are willingly spare their freetime as the owner did for the project.
2. Read the proposal or at least skim it a bit to understand the philosophy of the project.
3. Search for unsolved issues or create a new one. Be it bugs, new features, or anything else.
4. Create a Merge Request for it.
5. I'll be notified if there's any unmerged or new issues. 

## Roadmap

Right now, the project does have a roadmap and an end game for the lifetime of the project. The endgame itself is not the end of the project, but rather the start of a new era where every single feature is implemented well. To gain traffic and interest from the larger public, right now I'm branding the project as "The Solver Series". "The Solver Series" is a series of games that would add a lot of feature on top of each other until the "perfect" or at least "usable" game could exist. Below is the list of games and their features.

### **Aim-Solver**

The first game in The Solver Series that's all about aiming and training. It features customizations and offline capabilities for those who wants it. The game itself would focus on self improvement in the aiming department and will feature source-like movement as its main locomotion system. The features intended to be in the game will be,

- [ ] Easy to use UI customization that also includes an export and import function, for portability.
- [ ] Importing aim settings from other games.
- [ ] Variety of target to shot at.
- [ ] Different guns for different needs.
- [ ] Movement system that's inspired by the Counter Strike series.
  - [x] Crouch Jumping
  - [x] Bunny Hopping
  - [x] Air Strafing
  - [ ] Counter Strafing
- [ ] Light weight experience that's not only targetting the toaster, but also your HD tv.

### **Dispute-Solver**

The second game in The Solver Series that's all about 1v1 PVP. This game will include every single feature of The Aim Solver but now with a lot more variety of weapons and game modes. In multiplayer, the server will have the highest authority on what and what can't be done. This attributes will contribute to make the game much safer from hackers and the like. The features intended to be in the game will be,

- [ ] Multiplayer capabilities among two parties with a single server.
- [ ] Replayability for each match that's modular and can be copied by the user for save keeping purposes.
- [ ] Matchmaking based on the reputation and skill of the player.
- [ ] Statistics and data that the user can use to know which skill they need to improve upon.

### **Team-Solver**

The endgame of The Solver Series that's all about 5v5 PVP. This game will also include every single feature of its predecessor and now with a working competitive mode that will clash two teams made out of 5 players doing their best to win. 

- [ ] A better more robust matchmaking that's suited for a 10 player per match.
- [ ] A nicer and universal spectating system so other could use their client to do so.
- [ ] Delay based spectating for competitive matches.
- [ ] A more flexible and transparent skill assignments.

