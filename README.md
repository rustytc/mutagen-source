# mutagen-source
The public source code of the Mutagen: Lock and Load RPG game.

<img width="3840" height="2160" alt="cover art" src="https://github.com/user-attachments/assets/15e2d17c-757d-47a7-84d2-6c9b933d9755" />


Copyright (C) Rusty Tincan 2026

## Introduction:
Mutagen: Lock and Load is an unfinished* and prototypical* Godot hobby project which I have been passively working on since roughly February 2025. It is a 2D turn-based RPG which leans towards strategy rather than pure RNG.
Its source code has been publicized on this repo as of June 2026. I am doing so because I want this game and project to be truly free to the public. I have chosen GPL v3.0 as the license for which protects its code assets. It's art assets, including music, sounds, sprites, dialogue, videos, etc. are proprietary, and cannot be used in other projects without my explicit permission.


## Modifying and Compiling
This game is made entirely in the Godot 4.3 engine. It is specifically frozen at this version of the engine, as it utilizes specific depricated behaviors and plugins such as NavigationAgent2D, and I do not want to risk potential problems from upgrading Godot versions.


Modifying this game's code is as simple as [downloading Godot 4.3](https://godotengine.org/download/archive/4.3-stable/) and opening this very source code up from its project.godot file. From there you can basically do anything. Compiling builds of this game is the same, just export it directly from Godot's exporter to whatever platform you desire. 


## Premise:
This game is about a post apocalyptic Earth, following an alien invasion and global pandemic. You play as a scouter, whose sister has become infected with the deadly virus. He is informed by his superiors that a cure has been developed, and is housed in a far away research facility. If he doesn't go and retrieve it, they will execute his sister to prevent the spread of the virus. The wasteland is completely swamped with feral mutants and raiders, yet he's decided to go anyway.


## Gameplay:
Throughout the game, you unlock various weapons. These weapons each present their own unique behaviors in combat.
<br></br>
<img width="642" height="360" alt="image" src="https://github.com/user-attachments/assets/9acb7204-18ae-48c5-9227-28018787da89" />
<img width="636" height="361" alt="image" src="https://github.com/user-attachments/assets/a62f8dde-3446-4040-bb7e-8817e09f7f98" />
<br></br>
When fighting enemies in turn-based battles, the player can choose which of the enemy's limbs to attack, which each have their own unique hit rates and damage modifiers (Think the game Fallout).
<br></br>
<img width="636" height="361" alt="image" src="https://github.com/user-attachments/assets/f0aa9611-9c20-4f72-aef9-fc25b63b9b9f" />
<br></br>
The player has to keep track of both their health and radiation percentage. Radiation is accumulated by specific enemy attacks, which are usually telegraphed, and can be blocked before execution.
<br></br>
<img width="636" height="361" alt="image" src="https://github.com/user-attachments/assets/78b9745e-9c23-4d9e-8f39-449630c25be5" />
<img width="637" height="357" alt="image" src="https://github.com/user-attachments/assets/c5e3c000-0ccc-4fbb-8617-10102ae15136" />
<img width="637" height="357" alt="image" src="https://github.com/user-attachments/assets/3ea7dfa4-5ea8-4425-8063-9fc40fa598cf" />
<img width="637" height="357" alt="image" src="https://github.com/user-attachments/assets/58ccd088-dd62-4486-86ac-2a31cce613da" />
<br></br>
The player also has to keep track of enemy distancing (Think the game 'JoJo 7th Stand User'), advancing or backing away from enemies to manage accuracy % and damage amount.
<br></br>
<img width="637" height="357" alt="image" src="https://github.com/user-attachments/assets/2ee328ac-14a2-4bc1-900b-45f1b594c063" />
<img width="637" height="357" alt="image" src="https://github.com/user-attachments/assets/e67d5b0e-174a-41da-b8f8-b26f32e02db3" />
<br></br>
Enemies have specific behavior types (both inside and outside of combat), weaknesses, and attacks. Each battle in this game is almost like a puzzle.
In the game's world (outside of combat), enemies stalk, hunt down, or look out for the player. When confronted, enemies will chase the player down using Godot's grid-based A* pathfinding.
<br></br>
<img width="637" height="357" alt="image" src="https://github.com/user-attachments/assets/2be755f1-8fab-4ea9-978a-17a1c09d1752" />
<br></br>
The game's levelling system leans towards build customization, as the player can choose which of three base stats (Strength, Survival, Intelligence) to invest in at each new level.
<br></br>
<img width="637" height="357" alt="image" src="https://github.com/user-attachments/assets/18ed414e-a02b-43e4-a7da-c5082374986e" />
<br></br>

<br></br>
## Can I use your code?
Feel free. Not sure why you would, but you can. Just follow GPL v3.0.


## Can I use your assets?
Ask me, first. If it's a mod, I don't really care. If it's something bigger, ask. I don't exactly know why someone would do this, but that's my rule.


## Modding
It's a thing you can do. And it's also a thing that's pretty easy to do.
<img width="548" height="199" alt="image" src="https://github.com/user-attachments/assets/60c8a2e0-82f4-4047-a7cb-ce2fc7672b06" />
<img width="262" height="258" alt="image" src="https://github.com/user-attachments/assets/9291f47e-3c06-48a1-8488-bfea8533cdef" />
<img width="180" height="72" alt="image" src="https://github.com/user-attachments/assets/3ceb74f5-f4cd-45d0-a225-76ae6c1eae14" />
Like any Godot game with Godot Modloader support, edit the game in Godot, pick what changes you want made and export them in a resource pack (.pck), and then throw that thing into the /mods folder.

## Contributors
If you'd like to submit contributions to the source code/game project (for bug fixes or feature completions), you can. It's not guaranteed that I'll approve them, but if they're good, I just might. And if you ever get mugged, I'll be there. Waiting. To defend you. Also, you will be credited if I merge from your pull. By submitting a contribution, you grant me the right to use, modify, distribute, and commercialize it as part of Mutagen without compensating you.

## Footnote
Mutagen is a highly unfinished prototypical game. I am making it for fun. I am open to ideas and contributors, but more or less just for the sake of making a good game. It's code can read a bit unserious at times, and sometimes outright hacky. That is because I am focused more on getting systems to work than I am perfecting them. Of course, that doesn't excuse my habit of overengineering things ;)
