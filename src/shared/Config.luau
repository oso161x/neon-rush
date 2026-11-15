-- NEON RUSH: Crystal Run — shared tuning, palette and level definitions.
-- One place for every number the client and the server both need, so a
-- balance change is a one-line edit here and never a hunt through scripts.

local Config = {}

-- The play field, in pixels. The arena frame is this big, centred on screen.
Config.ARENA_WIDTH = 960
Config.ARENA_HEIGHT = 600
Config.PLAYER_RADIUS = 20
Config.PLAYER_SPEED = 430 -- pixels per second at full tilt
Config.PLAYER_ACCEL = 2600 -- how fast the ship reaches full speed

-- Palette: one deep-space night, neon on top. Every script reads these.
Config.Colors = {
	Background = Color3.fromRGB(10, 12, 34),
	Arena = Color3.fromRGB(18, 22, 52),
	ArenaEdge = Color3.fromRGB(0, 229, 255),
	Player = Color3.fromRGB(0, 229, 255),
	PlayerCore = Color3.fromRGB(255, 255, 255),
	Crystal = Color3.fromRGB(0, 255, 170),
	Star = Color3.fromRGB(255, 210, 63),
	Heart = Color3.fromRGB(255, 92, 138),
	Meteor = Color3.fromRGB(255, 64, 80),
	Chaser = Color3.fromRGB(170, 80, 255),
	Spinner = Color3.fromRGB(255, 140, 0),
	Text = Color3.fromRGB(240, 244, 255),
	DimText = Color3.fromRGB(150, 165, 210),
	Danger = Color3.fromRGB(255, 64, 80),
	Panel = Color3.fromRGB(24, 30, 68),
}

Config.FontTitle = Enum.Font.GothamBlack
Config.FontBody = Enum.Font.GothamBold
Config.FontMono = Enum.Font.Code

-- Scoring.
Config.CRYSTAL_POINTS = 10
Config.STAR_POINTS = 50
Config.COMBO_WINDOW = 2.5 -- seconds between pickups to keep the combo alive
Config.COMBO_STEP = 2 -- extra points per combo step
Config.COMBO_MAX_STEP = 5
Config.LEVEL_CLEAR_BONUS = 100
Config.TIME_BONUS_PER_SECOND = 5

-- Three levels. Each one is a real step up: more crystals to find, less time,
-- faster enemies, a shorter spawn gap, and a new enemy type from level 2 on.
Config.Levels = {
	{
		Name = "LEVEL 1 — FIRST LIGHT",
		GoalCrystals = 8,
		TimeLimit = 75,
		SpawnInterval = 1.1,
		EnemySpeedMin = 120,
		EnemySpeedMax = 185,
		MaxEnemies = 7,
		EnemyTypes = { "Meteor" },
	},
	{
		Name = "LEVEL 2 — CHASER FIELD",
		GoalCrystals = 12,
		TimeLimit = 70,
		SpawnInterval = 0.85,
		EnemySpeedMin = 150,
		EnemySpeedMax = 230,
		MaxEnemies = 10,
		EnemyTypes = { "Meteor", "Chaser" },
	},
	{
		Name = "LEVEL 3 — SPIN STORM",
		GoalCrystals = 16,
		TimeLimit = 65,
		SpawnInterval = 0.65,
		EnemySpeedMin = 180,
		EnemySpeedMax = 280,
		MaxEnemies = 13,
		EnemyTypes = { "Meteor", "Chaser", "Spinner" },
	},
}

Config.MAX_LIVES = 3
Config.INVULNERABLE_SECONDS = 1.5 -- flashing grace period after a hit
Config.HEART_SPAWN_SECONDS = 25 -- a heart pickup appears this often at most
Config.CRYSTALS_ON_FIELD = 3 -- crystals kept on the field at once
Config.STAR_CHANCE = 0.12 -- chance a new pickup is a golden star instead

-- Server-side sanity caps: no honest run scores faster than this.
Config.MAX_POINTS_PER_SECOND = 400
Config.MAX_TOTAL_SCORE = 99999

return Config
