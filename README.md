# 🛠 Drake Snake (Turbo Pascal, DOS)

**Drake Snake** is a DOS jump-and-run adventure game, written in **Turbo Pascal** in the early 1990s.  
The player controls *Drake*, an adventurer with a **jetpack**, **gun**, and **bombs**, exploring underground tunnels in search of treasure.  

Unlike the classic snake game, this is a **up-and-down-scrolling action platformer** with enemies, limited resources, and destructible walls.  

---

## 📂 Source Code Structure

The project is organized into multiple Pascal source files and include files:

- **Main program files**
  - `dr_snake.pas`, `dr2snake.pas`, `drsn2ake.pas` … `volldrak.pas`  
    → Entry points and level loaders.

- **Core gameplay**
  - `drakgame.pas` – Main game loop and mechanics.
  - `herospie.pas`, `herocons.pas` – Player control and constants.
  - `anfang.pas`, `dsanfang.pas`, `ds_begin.pas` – Game start / menu code.
  - `playdrak.pas`, `playdrk2.pas` – Playfield / level handling.

- **Graphics & animation**
  - `drakespr.pas` – Sprite handling.
  - `flyanim.pas`, `flugspie.pas`, `flyafrik.pas` – Jetpack / flying routines.
  - `planepic.pas`, `kartflug.pas`, `kart2flg.pas`, `kart3flg.pas` – Backgrounds and map graphics.

- **Sound & music**
  - `draktune.pas` – Sound and music routines.
  - `dieseq.pas` – Sound sequencing.

- **Levels**
  - `drsn3ake.pas`, `drsn4ake.pas`, … `drsn6ake.pas`, `lvl2blvl.pas` – Level data and logic.

- **Includes (`includes/*.inc`)**
  - `ds_block.inc` – Block / tile definitions.
  - `ds_lspr.inc` – Sprite loader.
  - `ds_vline.inc` – Low-level graphics routine.
  - `hirespal.inc`, `setzfarb.inc`, `setzpal.inc` – Palette setup.
  - `kat_init.inc` – Initialization routines.

---

## 🔗 Dependencies Between Modules

Each Pascal unit declares its dependencies via `uses` and `{$I ...}` include files.  
A few representative examples:

| File                  | Uses                                                                 | Includes      |
|-----------------------|----------------------------------------------------------------------|---------------|
| `8iff2bld.pas`        | HeroSpiel, Crt                                                       | –             |
| `anfang.pas`          | Crt, FlyAfrik, Kart3Flg                                              | –             |
| `dieseq.pas`          | GrafikOn, Crt, HeroSpiel                                             | –             |
| `dr2snake.pas`        | Crt                                                                  | –             |
| `drakeext.pas`        | HeroSpiel, Crt, Dos, GameCon, Joystick, DSAnfang                     | –             |
| `drakespr.pas`        | HeroSpiel, Crt, Dos                                                  | –             |
| `drakgame.pas`        | HeroSpiel, Crt, Dos, GameCon, Joystick, DrakeExt, PlayDrk2, Mouse, DieSeq | –        |
| `draktune.pas`        | Crt                                                                  | –             |
| `drsn2ake.pas`        | HeroSpiel, Crt, Dos, GameCon, Joystick, DSAnfang, DrakeExt, PlayDrak | –             |
| `drsn3ake.pas`        | HeroSpiel, Crt, Dos, GameCon, Joystick, DSAnfang, DrakeExt, PlayDrk2, Mouse | –      |

This shows how **`drakgame.pas`** is the central unit, tying together **player control**, **input**, **game constants**, **levels**, and **sound**.  

A full dependency graph can be generated if needed (see `scripts/dependency_graph.py` in this repo for automation).

---

## 🔧 Building

The game was originally developed with **Borland Turbo Pascal 6/7** for DOS.

### Option 1: Compile with Turbo Pascal
1. Start Turbo Pascal inside DOSBox.
2. Load `dr_snake.pas` or `volldrak.pas`.
3. Compile & run (`Ctrl+F9`).

### Option 2: Free Pascal (partial)
Some parts may compile with [Free Pascal](https://www.freepascal.org/) in `tp` mode, but due to inline assembler and DOS graphics calls, **DOSBox + Turbo Pascal** is recommended for authentic execution.

---

## 🎮 Controls

- **Arrow keys** – Move
- **Space** – Fire gun
- **B** – Drop bomb
- **Up (jetpack)** – Activate jetpack
- **ESC** – Quit game

(Energy, ammo, bombs, and fuel are limited; collect items to refill.)

---

## 📑 License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.  
- You are free to use, study, and share the code.  
- Any modifications or derivative works **must also be published under the same license**.  

See [LICENSE](LICENSE) for details.

---

## 🙏 Credits

- Original development: *Martin Keydel, Markus Schröder, Ralph Wiedemann, Daniel Rinck*  
- Language: **Turbo Pascal (DOS)**  
- Release: early 1990s  
- Open-sourced for preservation and retro-computing enthusiasts
