# Proposal

A living document of an unnamed 5 versus 5 competitive FPS, similar to Counter-Strike in many regards.

# Table of Contents

- [Proposal](#proposal)
- [Table of Contents](#table-of-contents)
- [Introduction](#introduction)
- [Design Philosophy](#design-philosophy)
- [Specification - Defusal Game Mode](#specification---defusal-game-mode)
  - [Actors](#actors)
  - [Maps](#maps)
  - [Rounds and Winning Condition](#rounds-and-winning-condition)
  - [Time](#time)
  - [Objective](#objective)
  - [Economic System](#economic-system)
  - [Weapon](#weapon)
  - [Movement](#movement)
  - [Utility](#utility)
  - [Health Management](#health-management)
  - [Interaction](#interaction)
- [Media](#media)
- [Afterwords & Credits](#afterwords--credits)
- [Glossary](#glossary)

# Introduction

This document shall describe the mission and vision for the game. The approach that we use to do so is called "top-bottom" starting from the elevator pitch of the game. After that, we will detail more and more aspect of the game such as rounds in a single game, maps, and the economic system being used. It will all end with the concept art and afterwords that might come from the developer.

The unnamed team based competitive tactical shooter will value the player skill more than the utilities that they possess. It's basically an open source version of Counter Strike: Global Offensive. Because of the main inspiration, most of the the things that's mentioned in this proposal will borrow some of the vocabulary from said game. The open source nature of the game should in turn create a community that will hold itself even if the original company/developer is gone. To achieve this, there's several things that must be considered when developing the game. Below are some of them:

1. **The game must be simple to play but hard to master**. This mission can be achieved by having a very small sets of things that the player must consider at all times but gradually increases as the skill of the player grows. For example, an inexperienced player would not consider pre-aiming an angle when going inside of a bomb site.
2. **Produce a well maintained learning material for players, content creators, and programmers**. For players, it might be great to give them a tour of the game in the form of tutorial levels, training maps, and videos. Content creators in the other hand can be introduced to the game with the usage of tools and commands that could benefit them in developing a new map, for example. Programmers could also benefit from being able to read the auto generated documentation such as the auto-generating documentation for Rust Programming Language.
3. **Don't forget about the spectators**. The game should be able to be enjoyed by player and spectators because those who watch is but another potential player. The developer's appreciation toward spectators can be shown through making the game replay friendly and stream friendly. We could just use the current concept of source engine that took snapshot of the world every single step and broadcast it.
4. **Market the game to the right people**. Before the time of release, the organization that mainly develop the game should research and then hold on to the main audience of the game. We cater towards people with the age of 16 above that cares a lot about legacies and meritocracy for the professional play. We shall not obey and be persuaded by the opinion of those that don't intend to play or enjoy the game. Internet drama for the game shall exist, but it should never break the beautiful relationship between the developer and the community.
5. **Learn the mistake of your elder**. Learning from the history of mistakes about popular e-sport game such as Counter Strike: Global Offensive and Valorant would bring a tremendous value towards our mission to make a game that put their community first and profit second. For example, we/anyone should not monopolize the activity of the game. The community and professionals shall be the judge to where the game would lead.
6. **The game should be honest and not pay to win**. To support the financial situation for keeping the game alive and maintained, we could opt-in to creating skins and maybe tickets to a self-managed tournament. Keep the game honest and the community proud.

# Design Philosophy

The design philosophy should govern every single content that's being made for the game. It will answer questions about what should be implemented, what should not be implemented, and the core motivation behind it. Below are the philosophy behind every single design decision, presented in a nifty bullet points.

1. **It must follow the principle, Keep It Simple Stupid**. This philosophy have been expressed beautifully by at least two very good programmers, notably Tim Peters (the creator of zen of python) and the late Terry A. Davis (the creator of Temple OS).
2. **It must be clear to the senses and not ambiguous**. There's at least three sensors of the human being that we can manipulate within the realm of video games. The auditory perception of the human ear, vision, and space. In terms of hearing, the game should be as clear as possible when presenting critical gameplay related sounds such as foot steps and gunshots. We allow background noises and musics but it should never be the "main character" during the gameplay. As for the vision, we must be as clear as possible at distinguishing between the critical elements of the game. Lastly, the sense of space can be expressed through fluid movement, scale between real world object and something on the map, and the presence of the player such as the length of the barrel the gun that the player's is using.
3. **Balance between what's fair and what's fun**. The designer must balance between what's fair for the player involved and what's fun to play. In general, something that's fair tends eliminate the feeling of uncertainty but bore the player if it's used too much. For example, a map that only have a single box that obscure the vision of both team is fair, but doesn't present any interesting gameplay and strategies. In terms of fun, the notorious but beautifully crafted solution is by applying controlled randomization on the bullet sprays.
4. **Customization for the needy and line that should not be crossed**. The player should be able to customize things in the game that have ties to accessibility such as the color of elements in the game. But we must make a hard limit towards what's allowed and not allowed in competitive play, such as the weapon placement on the screen and the field of view of the player.

This is the core believe of how the designer shall move from now on.

# Specification - Defusal Game Mode

This section shall explain the details of the game that shall be implemented. Note that the specification lived in a living document and may change from time to time. It should not aim to be backward compatible like most software specification would be. The description would start at the actors that have the ability to change the dynamic of a single game. Then it will explain every single element that's in the game in such a detail that there would be no ambiguity in the intent but provide enough room for freedom of creativity. Right now, the would only provide defusal game mode, but will expand to other modes given the community's will and time.

## Actors

There would be two teams consisted of five player on each one. To avoid confusion, both team would be generally mentioned as **attackers** and **defenders**. It should however not to be confused with censoring the lore of the game that seems to be prevalent in every single industry right now. The designer shall have the creative freedom to even emulate the classic stories of counter-terrorist versus terrorist that's pretty prevalent in the history books or even a made up one.

Starting from the **defenders**, their main objective is to stop the **attackers** from accomplishing their objective. This side of the team is designed to be reactive but also leaves rooms for some proactive action that could lead to interesting moments. They're also designed to be strong when defending themselves but not enough to overwhelm the **attackers**, given they're playing on the same skill level. The **attackers** on the other hand is the catalyst of the game. They should always tries to accomplish their objective and be severely punished if they didn't do so at the end of the round.

## Maps

A single level of a game is entirely made out of a single map. The purpose of a map is to give every single player a self resetting (per round) sandbox that they can play with. It could also be a place for the spectators to peer into. A single map have at least four main point of interest that must exist in order to create a coherent and competitively viable map. Below are the tables that would detail it.

| Spot Name      | Description                                                                                                        |
| -------------- | ------------------------------------------------------------------------------------------------------------------ |
| Defender Spawn | A place for the defending team to spawn in. Usually it should be near the bomb site.                               |
| Attacker Spawn | A place for the attacking team to spawn in. Usually they have a lot more coverage on the map compared to defender. |
| Bomb Site A    | A bomb site where the attacking team can place bomb in.                                                            |
| Bomb Site B    | A bomb site where the attacking team can place bomb in.                                                            |

The map need to be competitively viable. The competitiveness of the map can be measured by the percentage of winning between the two teams (defenders vs attackers). This implies a very thorough play testing and a lot of experimentation. For a map to be viable, there are several common parameters that we can manipulate. Some of them are listed below.

- The rotation time for the defenders and attackers.
- How much angle does the player need to clear to get into an advantaged position.
- How much time is needed to get into the first contact point.
- The many strategies and playstyle that the map could support.

In designing the map, the designer keep some aesthetic objective in mind. Below are the several points that need to be considered.

- It should be simple and explicit.
- It should be thematically congruent across the map.
- It should always prioritize gameplay rather than realism.
- Every single spot (or at least hot-spot) should be recognizable and named.

## Rounds and Winning Condition

Every single match in this game is divided into rounds. Every single round would have the same amount of time and at the starting point of the round, the player would get their "allowance" in the form of economic advantage, with exception that's documented in "economic system" section of the document. For a team to win a round, they must follow the objective of the game and if they failed to do so, the game could punish them with the reward system that's in place. The objective of defending and attacking team is different, as expected. Below are the objectives of both team, presented in a neatly organized table.

| Team                  | Objectives                                           | Reward - If Succesful                            | Punishment - If Unsuccesful              |
| --------------------- | ---------------------------------------------------- | ------------------------------------------------ | ---------------------------------------- |
| Defending & Attacking | Eliminating the entire opposing team.                | Economical advantage and a single winning point. | Moderate economical disadvantage.        |
| Defending             | Running out the round time **OR** defusing the bomb. | Economical advantage and a single winning point. | Moderate economical disadvantage.        |
| Attacking             | Planting the bomb **AND** wait for it to explode.    | Economical advantage and a single winning point. | Moderate/severe economical disadvantage. |

**TABLE-NOTE**: Severe economical damage to the attacking team shall be imposed upon them if they lost by not planting the bomb **AND** wasted the round's time.

The game will decide the winner by using a system we call "The Magic Number". This system emulates the one used in Counter-Strike and many other game in the same genre. Before describing the rules of the game, we will introduce some jargon that we will use to describe this system. It's as follows:

1. **Magic Number**: A positive number that represents the minimum amount of winning-rounds a team must get to win the game. The default one is 16.
2. **Half-Time**: A positive number that represents the number of round that team have gone through. The formula for a half-time is `Magic_Number - 1`.
3. **Match Point**: The formula for a match point is `Magic_Number - 1`.
4. **Overtime**: When both team have the same amount of winning-rounds as match point, they'll go through a phase called overtime.

Below is the full rules that governs "The Magic Number" system:

1. The team that reaches the "magic number" first shall win the match.
2. The roles of both team shall be switched when the total number of round reaches half-time.
3. The game will switch into overtime when both teams have the same amount of winning-rounds as match point.
4. Overtime is a looping phase that will determine the winner of the game. Both team will fight with the same roles they have at second-half, with the same amount of money described in [economic system](#economic-system), and one of them must try to reach the newly set magic number which is `magic number = latest magic number + 3`. Overtime process will be used again if both team also have the same amount of winning-rounds as match point, following the newly set magic number. Every single time a new overtime is done, the role of both team will be switched again.

If one of the team felt very overwhelmed or underleveled compared to the opposing force, they can majority-vote to surrender themselves. The minimum difference of round between the surrendering and the winning team must be equal or greater than the one set by the server. By default, the differences is 8 rounds.

## Time

Time is a valuable resource in a round. Every single activity that you're going to do in the game will consume a bit amount of time. For the game designers, the exact time in seconds that's listed below should not be a hard coded rule that shouldn't be changed, but rather a framework towards making an ideal time so that both team could maximize their potentials. Right now, it's decided that **buy time should be around 15 seconds long** where each member of the team will buy their desired weapon of choice and communicate their strategy with each other.

TODO: describe how time is set in a single game and their relation with other element in the game such as utilities, time to kill, and rounds.

## Objective

The objective of the game shall be competed between the two team that participates in a single match. Generally speaking, the winner of a match is the team that have the highest number of rounds won. Right now, the default way to do this is by implementing the "magic number" that must be met to win, explained in the [Rounds](#rounds) section of the document. The team specific objective could also change and will happen after the half-match point.

**The defender** aims to make the plan of the attacker seems impossible to accomplish. Below are some of the most used strategy:

1. Wasting the time of the attacker. This method can be achieved by smart manipulation of the environment through [utilities](#utility) and mind games. 
2. Eliminate every single member of the opposing team. This way is rather straight forward and self-explanatory. 
3. Defusing the bomb that's planted by the attacking team. The defender would have a limited choices between defusing the bomb or not doing it to "save" weapon for the next round.

**The attackers** in the other hand tries to achieve their objective and these are some of the most used strategies.

1. Killing all of the defenders or 
2. Successfully planting and guarding the bomb till the time of explosion.

The other silent enemy of the attackers is the time itself. If an attacking team fails to either kill all the opposing team or plant the bomb until the end of the round, they will be punished economically in the next round.

## Economic System

In a competitive game such as The Solver Series, there's a need for a system to regulates, awards, and punish the action of the player. In this game, that system will be implemented through the means of in-game cash. The in-game cash is reset after the half-time and when the game is over.

TODO: details how each team get punished and rewarded through the economic system that transcend rounds but not matches.

## Weapon

TODO: describe every single weapon that's in the game, their role, and statistics.

## Movement

TODO: describe the desired feeling and purpose of movement and their relation to the elements in the game.

## Utility

TODO: explain the purpose and need of each and every single utility and their manipulation to the senses and elements in the game.

## Health Management

TODO: explain that every single person in the game have 100 health and the damage of the guns can be reduced using armor for the body and head. The regular armor will protect the user from damages in the upper area of the body (chest, arm) but not the lower one (legs, foot, crotch). With more investment, player could buy helmet that protects the head and neck but could not be bought separately from the body armor.

## Interaction

TODO: explain the way that player can interact with the world. Dropping guns and utilities for their friends, defusing the bomb, opening and closing doors, manipulating sound cues like going through a checkpoint, killing a team mate, ping-ing a location, drawing on the map, voice chat, and team/inter-team chat etc.

# Media

TODO: concept art that expresses the identity of the game, the art style that it conforms to, and the feeling of being in the game with your team mates.

# Afterwords & Credits

Thank you for reading the proposal of the game. May it flourish into something that others enjoy.

- Author: Tengku Izdihar Rahman Amanullah

# Glossary

Below are all of the more uncommon words that we use for this document. What matters here is the intent of the word rather than the exact definition of it, so be careful when translating the document to other languages.

- **Counter Strike: Global Offensive**: A competitive tactical shooter with unique mechanics that's being developed by Valve.
- **Economic System**: A system that regulates, awards, and punish the action of the player through the means in-game cash.
- **Elevator Pitch**: A short summary of the game that can be said within the duration of a single elevator ride.
- **In-Game Cash**: Specific to this game (also CSGO and Valorant), this term refers to the context isolated currency that can be used to buy weapons and utilities. It **does not** have anything to do with real life money (Fiat, cryptocurrency, etc.) and shall be resetted for at least every single time the team switches or the match is over.
- **Maps**: The current world which the player will play in. It's often self contained, small, and aim to produce the best engagement between the team involved.
- **Match**: Contest between two teams.
- **Pre-Aiming**: A technique used by players to place their crosshair onto the the possible location of the target even before they see them.
