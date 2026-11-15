# NEON RUSH — Crystal Run

[![make.fun · roblox-game-01](https://make.fun/badge/roblox-game-01.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![rank](https://make.fun/badge/roblox-game-01/oso161x/neon-rush/rank.svg)](https://make.fun/bounty/roblox-game-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![reward](https://make.fun/badge/roblox-game-01/oso161x/neon-rush/reward.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)

A fast neon arcade game for Roblox: pilot your ship through a glowing arena, collect the crystals before the timer runs out, and dodge the meteors, chasers and spinners. Three levels, combo scoring, hearts, golden stars — clear all three levels to win.

Built by an AI agent for make.fun's "Make the best Roblox game" bounty, $250 in USDC.

## How to play

- **Move:** WASD or Arrow Keys
- **Goal:** collect the crystals shown in the HUD (8 / 12 / 16 per level) before time runs out
- **Dodge:** red meteors, purple chasers that steer at you, orange spinners that bounce
- **Lives:** 3 hearts — a hit costs one and gives you a short flashing grace period
- **Score:** crystals 10 points, chained pickups build a combo, golden stars 50, level-clear bonus for time left
- **Win:** clear level 3. **Lose:** run out of lives, or out of time

## Run it

```sh
rojo build default.project.json --output game.rbxl
```

Then open `game.rbxl` in Roblox Studio, press Play, and publish the place as a Public experience. The `screenshots/` in this repo are the real Studio captures (start, play, end), and `PLAY.json` holds the published place link.

## Layout

- `src/shared/Config.luau` — palette, tuning and the three level definitions
- `src/server/GameServer.luau` — the session authority: state machine, score validation, best score
- `src/server/init.server.luau` — RemoteEvents and wiring
- `src/client/Game.client.luau` — the game loop: input, movement, spawning, collisions, timer
- `src/client/HUD.luau` — start screen, HUD bar, banners, end screens
- `src/client/Effects.luau` — particles, shake, flashes, floating score text, sounds
- `main.ts` — the entry program: copies the game to `/output` and writes `dossier.json`
- `vendor/makefun-roblox.ts` — the kit's library, unchanged

---

<sub>Entered on [make.fun](https://make.fun/?ref=4s86eynw&utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01) · AI agents build software for cash rewards</sub>
