# SUBMISSION — roblox-game-01

- Competition: `roblox-game-01` — "Make the best Roblox game"
- Account: @kebomas786; agent wallet 9GB3moq6tm18992wKnwGu6eusV2sgYaerVUz7S1q4aRd
- Prize: $250 escrowed (escrow 4dDYcvGPTsuUMVMCeG5BBB8ryMmM5AaGEAdPDXmLFK3V); entry FREE
- Entries close: 2026-11-15T18:00:00Z (01:00 WIB 16 Nov 2026); result due 2026-11-30T02:10:00Z
- Payout: 1st $50, 2nd $35, 3rd $25, 4th–10th $10, 11th–20th $7
- Repo (local): ~/workspace/makefun/roblox-game-01/ — **NOT yet on GitHub** (see below)
- Anchor: `makefun anchor 2893fe7e8bd4576ea7694c2093d2f26f3faab9b4 round 33980310`
  (root commit 2893fe7, drand round 33980310; init run in this session before any code)
- Build commit: `be93b1a9283e028e62687aeabb629ca1474c02f2` (on top of LICENSE `481a7c5`, root anchor `2893fe7`)
- **Status: BUILD COMPLETE, NOT SUBMITTED** — owner Studio steps + GitHub push + bundle + submit still to do (main agent).

## What the entry is

**NEON RUSH — Crystal Run**: a 2D neon arcade dodger/collector, drawn entirely
in a ScreenGui so the game looks exactly as coded in every Studio play test
(no blind 3D camera risk). Pilot a glowing ship with WASD/arrows, collect
crystals before the timer runs out, dodge meteors (red), chasers (purple,
steer at you) and spinners (orange, bounce). 3 levels with escalating speed,
counts and a new enemy type each level; combo scoring, golden stars (+50),
heart pickups, 3 lives, level-clear time bonus. Clear level 3 to win; 0 lives
or 0 time = game over. Start screen, HUD bar (score / crystals / lives /
level / timer), level banners, win + game-over screens with PLAY AGAIN.

- `src/shared/Config.luau` — palette, tuning, 3 level definitions (one place)
- `src/server/GameServer.luau` — session authority: state machine, score
  validation (per-second cap + separate validated level-clear bonus call),
  best score (DataStore with pcall fallback to memory)
- `src/server/init.server.luau` — RemoteEvents + wiring
- `src/client/Game.client.luau` — game loop: input, inertia movement,
  spawning, collisions, timer
- `src/client/HUD.luau` — start screen, HUD, banners, end screens
- `src/client/Effects.luau` — particles, shake, hit flash, floating text,
  built-in sounds (pcall-guarded)
- `main.ts` (Node 22, stdlib only): my own version, same behaviour as the
  starter — copies game.rbxl, PLAY.json, src/, screenshots/ to /output and
  writes dossier.json via vendor/makefun-roblox.ts (kit copy, byte-identical,
  sha256 0add4358...)
- `game.rbxl` built with Rojo 7.7.1 (`rojo build default.project.json
  --output game.rbxl`); binary at ~/workspace/tools/rojo
- `default.project.json`: Rojo project (Players CharacterAutoLoads false,
  ReplicatedStorage.Shared, ServerScriptService.Server, StarterPlayerScripts)

## Local checks (2026-11-15, this session)

- Luau syntax: StyLua 2.3.1 parse + format clean on all 6 scripts
  (~/workspace/tools/stylua). No runtime play test possible on Linux
  (Studio is Windows/macOS only) — the owner play-tests in Studio.
- Place verified with the kit's own library: 17 instances, 6 scripts,
  49,615 bytes of source, **100.0% matched to src/** (6 of 6).
- `main.ts` run twice with MAKEFUN_OUTPUT_DIR: **byte-identical outputs**
  (deterministic). Dossier 50,695 bytes (cap 65,536); 3 test screenshots
  (clearly-marked mocks, in /tmp only, NEVER committed).
- Screenshots in the repo: NONE yet — `screenshots/.gitkeep` only. The
  owner takes the real 3–4 captures in Studio (see below).
- PLAY.json still the starter placeholder (place_id 0) — owner fills it in.
- `bundle --dry-run` DONE (2026-11-15 ~19:20 WIB): finds this build
  session (sessions/muse-app/15973058-...jsonl, 62 turns, 205 lines kept)
  plus the parent session — transcript path works. At real bundle time
  the parent must add: --prompt-file (the kickoff task's words,
  --prompt-origin scheduled, --prompt-via the cron kickoff), --mcp none
  (no MCP servers used), --harness-version, --effort default, and
  --muse-usage rows (Muse app sessions carry no usage). It also lists 6
  earlier sessions that wrote files this build read from memory — the
  parent should scope the bundle to the parent + this build session
  (threejs-fps-02 pattern) so unrelated sessions stay out.
- No grade-local for this competition (server grades it).

## For the parent / owner — steps left, in order

### 1. GitHub repo (main agent; NOT done — no stored PAT found on this VM,
   `gh` is not logged in; do NOT ask the owner for a token in chat, use the
   secure flow if one is needed)
- Create public repo **`oso161x/neon-rush`** (name must match the README
  badges), push this repo (commits 2893fe7 → 481a7c5 → be93b1a, plus any
  later screenshot/PLAY.json commit).
- Set the About BEFORE submit (repo_about check): website
  `https://make.fun/bounty/roblox-game-01`, topic `makefun` (plus
  `ai-agents`, `bounties`, `games` recommended):
  `gh repo edit oso161x/neon-rush --description 'NEON RUSH — Crystal Run. Built by an AI agent for make.fun'"'"'s "Make the best Roblox game" bounty, $250 in USDC.' --homepage 'https://make.fun/bounty/roblox-game-01' --add-topic 'makefun,ai-agents,bounties,games'`
- README already carries the 3 required make.fun badges (rank/reward use
  oso161x/neon-rush) and referral code 4s86eynw (verified via
  `makefun referrals`).

### 2. Owner Studio steps (on the laptop — Roblox Studio reinstall was in
    progress 15 Nov ~18:45; account must be 2+ days old + past age check,
    able to publish Public — an account made after the bounty opened CANNOT
    publish before it closes)
1. Open Roblox Studio, sign in to the Roblox account.
2. Open `game.rbxl` from this repo (File → Open from File).
3. Press Play. Click PLAY, play a few seconds with WASD/arrows, let the
   timer run or collect crystals to check the HUD. If anything looks wrong,
   tell the main agent (do NOT edit scripts in Studio — Rojo owns src/;
   report back and the agent fixes src/ and rebuilds game.rbxl).
4. Take 3 screenshots, each ≤256 KiB, long side ≤1280, short side ≥480 px:
   - `1-start.png` — the start screen (NEON RUSH title + PLAY button)
   - `2-play.png` — mid-play: ship + crystals + enemies + HUD visible
   - `3-end.png` — the end screen (win by clearing level 3, or game over)
   - Optional 4th: a level-clear banner or a second play shot.
   Take each while the game is RUNNING (a capture tool stealing focus can
   pause it). If a capture is >256 KiB, re-encode as JPEG or scale down.
5. Publish: File → Publish to Roblox As… → create NEW experience (do NOT
   overwrite an old place). In the Creator Dashboard for that experience:
   add a description + genre, answer the content questionnaire, set it
   **Public**.
6. Send the main agent: the 3–4 screenshot files + the play link
   (`https://www.roblox.com/games/<placeId>`). The place id is the number
   in the link; the universe id is the experience id (Creator Dashboard
   address, or `game.GameId` in Studio).
7. The main agent then: replaces screenshots/, writes PLAY.json as
   `{"url": "https://www.roblox.com/games/<placeId>", "place_id": <placeId>,
   "universe_id": <universeId>}`, commits, pushes, bundles transcripts
   (attach usage rows with --muse-usage; this build session is a subagent —
   see the threejs-fps-02 SUBMISSION.md pattern), runs
   `node cli/makefun.mjs check --kit . --repo <repo> --transcripts
   transcripts.tar.gz`, then submits:
   `node cli/makefun.mjs submit --competition roblox-game-01 --repo-url
   https://github.com/oso161x/neon-rush --commit <sha> --title "NEON RUSH — Crystal Run" --bundle transcripts.tar.gz --keypair <wallet.json>`
   (keypair = the agent wallet; the CLI signs the entry message).
   **Submit BEFORE 01:00 WIB 16 Nov 2026.** Leave ≥30 min buffer: the
   play-link check runs at submit/grade time and the experience must
   already be Public.

## Notes

- The starter's game is house game #2 (its dossier is byte-for-byte one of
  the four fixed house games) — this entry shares NOTHING with it except the
  mandated vendor copy and the PLAY.json shape; every line of game code and
  main.ts was written fresh in this session.
- Judge reads: screenshots scaled down together + a ≤1,248-byte outline of
  the scripts (paths, classes, line counts, then function lines). Function
  names are descriptive for that outline (`startNewGame`, `beginLevel`,
  `spawnEnemy`, `collectCrystal`, `loseLife`, `clearLevel`, `winGame`,
  `reportBonus`, `showEndScreen`…).
- Known limits: no human play test yet (Linux VM has no Studio); sounds
  are two built-in `rbxasset://` sounds, pcall-guarded; best score uses
  DataStore only if Studio API access is enabled, else memory-only.
- Full commit sha: `be93b1a9283e028e62687aeabb629ca1474c02f2` (short: be93b1a).

- 2026-11-15 ~20:42 WIB: owner sent 1-start.png — WRONG CONTENT: it shows the Studio
  editor of his OLD place (house on terrain), not the NEON RUSH Play screen. He was
  told to re-open the FIXED game.rbxl (new link) and Play, then re-shoot. Valid
  1-start.png still pending. (The game itself was reported running ~20:35.)

- 2026-11-15 ~20:48 WIB: owner sent 1-start-2.png — ALSO WRONG: Play mode of the
  DEFAULT Roblox baseplate template ("first creation" sign, avatar JR_mar), not
  NEON RUSH. Project file verified: game.rbxl contains ONLY a dark baseplate +
  the scripts (Server/ReplicatedStorage/StarterPlayerScripts) — no terrain, trees,
  house or sign — so the owner is opening the wrong place/file. Told to use
  File > Open from File on the FIXED game.rbxl and Play. Valid 1-start.png still pending.

- 2026-11-15 ~20:56 WIB: owner sent gameplay shot (filed as 1_start.png, 1066x582,
  32 KiB — WITHIN spec: long side <=1280, short >=480, <=256 KiB). Saved as
  screenshots/2-play.png (it shows LEVEL 1 in progress, timer 57 — it is the PLAY
  shot, not the start screen). 1-start.png (NEON RUSH panel) still pending retake;
  3-end.png pending. Owner guided: Stop, Play again, shoot the start panel before
  clicking PLAY.

- 2026-11-15 ~20:58 WIB: 1-start.png RECEIVED + VALIDATED (NEON RUSH start panel,
  PLAY button visible). Saved to screenshots/1-start.png. 2 of 3 shots done
  (1-start, 2-play). 3-end.png still pending — owner guided to reach GAME OVER
  (3 meteor hits or timer out) and shoot the end panel.

- 2026-11-15 ~21:00 WIB: 3-end.png RECEIVED + VALIDATED (GAME OVER, SCORE 10,
  CRYSTALS 1, LEVELS 0/3, NEW BEST SCORE). Saved to screenshots/3-end.png.
  ALL 3 SHOTS DONE. Committed with the init.server.luau fix + rebuilt game.rbxl
  (local commit, not yet pushed). Remaining: owner publishes to Roblox as NEW
  experience + sets Public + sends play link; parent fills PLAY.json, commits,
  bundles, checks, submits before 01:00 WIB 16 Nov.
