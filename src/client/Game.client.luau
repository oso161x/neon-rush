-- NEON RUSH: Crystal Run — client game loop.
-- Reads input, moves the ship, spawns and moves pickups and enemies, checks
-- collisions, runs the level timer and talks to the server (GameServer owns
-- the session and validates every score). One frame per entity, positions
-- kept in arena pixels, so the game looks identical in every play test.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local HUD = require(script.Parent:WaitForChild("HUD"))
local Effects = require(script.Parent:WaitForChild("Effects"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("NeonRushRemotes")
local startGameRemote = remotes:WaitForChild("StartGame")
local beginLevelRemote = remotes:WaitForChild("BeginLevel")
local reportScoreRemote = remotes:WaitForChild("ReportScore")
local reportBonusRemote = remotes:WaitForChild("ReportBonus")
local reportCrystalsRemote = remotes:WaitForChild("ReportCrystals")
local reportLifeRemote = remotes:WaitForChild("ReportLifeLost")
local finishRunRemote = remotes:WaitForChild("FinishRun")
local markClearRemote = remotes:WaitForChild("MarkLevelClear")
local winGameRemote = remotes:WaitForChild("WinGame")
local loseGameRemote = remotes:WaitForChild("LoseGame")
local gameStateRemote = remotes:WaitForChild("GameState")

local C = Config.Colors
local ARENA_W = Config.ARENA_WIDTH
local ARENA_H = Config.ARENA_HEIGHT

-- Run state. `phase` mirrors the server's session: start, playing,
-- levelclear, over.
local phase = "start"
local level = 1
local score = 0
local crystals = 0
local totalCrystals = 0
local lives = Config.MAX_LIVES
local levelsCleared = 0
local combo = 0
local comboTimer = 0
local timeLeft = 0
local best = 0

-- Player state in arena pixels, with velocity for smooth inertia.
local px, py = ARENA_W / 2, ARENA_H / 2
local pvx, pvy = 0, 0
local invulnerableUntil = 0

-- Live entities on the field.
local pickups = {} -- {kind, frame, x, y, radius, bob}
local enemies = {} -- {kind, frame, x, y, vx, vy, radius, spin}
local spawnTimer = 0
local heartTimer = 0
local lastHudSecond = -1

local refs = HUD.build(playerGui)
Effects.init(refs.gui)

-- The ship: a glowing cyan orb with a white-hot core.
local shipGlow = Instance.new("Frame")
shipGlow.Name = "ShipGlow"
shipGlow.AnchorPoint = Vector2.new(0.5, 0.5)
shipGlow.Size = UDim2.fromOffset(64, 64)
shipGlow.BackgroundColor3 = C.Player
shipGlow.BackgroundTransparency = 0.6
shipGlow.BorderSizePixel = 0
shipGlow.Visible = false
shipGlow.Parent = refs.entities
local glowCorner = Instance.new("UICorner")
glowCorner.CornerRadius = UDim.new(0.5, 0)
glowCorner.Parent = shipGlow

local ship = Instance.new("Frame")
ship.Name = "Ship"
ship.AnchorPoint = Vector2.new(0.5, 0.5)
ship.Size = UDim2.fromOffset(40, 40)
ship.BackgroundColor3 = C.Player
ship.BorderSizePixel = 0
ship.Visible = false
ship.Parent = refs.entities
local shipCorner = Instance.new("UICorner")
shipCorner.CornerRadius = UDim.new(0.5, 0)
shipCorner.Parent = ship

local shipCore = Instance.new("Frame")
shipCore.Name = "ShipCore"
shipCore.AnchorPoint = Vector2.new(0.5, 0.5)
shipCore.Size = UDim2.fromOffset(16, 16)
shipCore.BackgroundColor3 = C.PlayerCore
shipCore.BorderSizePixel = 0
shipCore.Parent = ship
local coreCorner = Instance.new("UICorner")
coreCorner.CornerRadius = UDim.new(0.5, 0)
coreCorner.Parent = shipCore

local function placeShip()
	ship.Position = UDim2.fromOffset(px, py)
	shipGlow.Position = UDim2.fromOffset(px, py)
end

local function clearEntities()
	for _, e in ipairs(pickups) do
		e.frame:Destroy()
	end
	for _, e in ipairs(enemies) do
		e.frame:Destroy()
	end
	table.clear(pickups)
	table.clear(enemies)
end

local function makePickupFrame(kind: string, x: number, y: number): Frame
	local colour = C.Crystal
	local size = 28
	if kind == "Star" then
		colour = C.Star
		size = 34
	elseif kind == "Heart" then
		colour = C.Heart
		size = 32
	end
	local f = Instance.new("Frame")
	f.Name = kind
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(size, size)
	f.BackgroundColor3 = colour
	f.BorderSizePixel = 0
	f.Rotation = 45
	f.Parent = refs.entities
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.3, 0)
	c.Parent = f
	local core = Instance.new("Frame")
	core.Name = "Core"
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.fromScale(0.5, 0.5)
	core.Size = UDim2.fromOffset(size / 2, size / 2)
	core.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	core.BorderSizePixel = 0
	core.Parent = f
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0.5, 0)
	cc.Parent = core
	return f
end

local function randomFieldPosition(margin: number): (number, number)
	local x = margin + math.random() * (ARENA_W - margin * 2)
	local y = margin + math.random() * (ARENA_H - margin * 2)
	return x, y
end

local function spawnPickup(kind: string)
	local x, y = randomFieldPosition(50)
	-- Never spawn on top of the ship.
	local tries = 0
	while math.abs(x - px) < 120 and math.abs(y - py) < 120 and tries < 8 do
		x, y = randomFieldPosition(50)
		tries += 1
	end
	local radius = 14
	if kind == "Star" then
		radius = 17
	elseif kind == "Heart" then
		radius = 16
	end
	table.insert(pickups, {
		kind = kind,
		frame = makePickupFrame(kind, x, y),
		x = x,
		y = y,
		radius = radius,
		bob = math.random() * math.pi * 2,
	})
end

local function spawnCrystal()
	if math.random() < Config.STAR_CHANCE then
		spawnPickup("Star")
	else
		spawnPickup("Crystal")
	end
end

local function makeEnemyFrame(kind: string, x: number, y: number): Frame
	local colour = C.Meteor
	local size = 36
	if kind == "Chaser" then
		colour = C.Chaser
		size = 38
	elseif kind == "Spinner" then
		colour = C.Spinner
		size = 40
	end
	local f = Instance.new("Frame")
	f.Name = kind
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(size, size)
	f.BackgroundColor3 = colour
	f.BorderSizePixel = 0
	f.Rotation = 45
	f.Parent = refs.entities
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.25, 0)
	c.Parent = f
	local core = Instance.new("Frame")
	core.Name = "Core"
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.fromScale(0.5, 0.5)
	core.Size = UDim2.fromOffset(size / 2, size / 2)
	core.BackgroundColor3 = Color3.fromRGB(20, 8, 16)
	core.BorderSizePixel = 0
	core.Parent = f
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0.5, 0)
	cc.Parent = core
	return f
end

local function spawnEnemy()
	local def = Config.Levels[level]
	if #enemies >= def.MaxEnemies then
		return
	end
	local kind = def.EnemyTypes[math.random(#def.EnemyTypes)]
	local speed = def.EnemySpeedMin + math.random() * (def.EnemySpeedMax - def.EnemySpeedMin)
	-- Enter from a random edge, aimed across the arena.
	local edge = math.random(4)
	local x, y, vx, vy = 0, 0, 0, 0
	if edge == 1 then -- top
		x = math.random(40, ARENA_W - 40)
		y = -30
		vx = (math.random() - 0.5) * speed
		vy = speed
	elseif edge == 2 then -- bottom
		x = math.random(40, ARENA_W - 40)
		y = ARENA_H + 30
		vx = (math.random() - 0.5) * speed
		vy = -speed
	elseif edge == 3 then -- left
		x = -30
		y = math.random(40, ARENA_H - 40)
		vx = speed
		vy = (math.random() - 0.5) * speed
	else -- right
		x = ARENA_W + 30
		y = math.random(40, ARENA_H - 40)
		vx = -speed
		vy = (math.random() - 0.5) * speed
	end
	local radius = 18
	if kind == "Spinner" then
		radius = 20
	end
	table.insert(enemies, {
		kind = kind,
		frame = makeEnemyFrame(kind, x, y),
		x = x,
		y = y,
		vx = vx,
		vy = vy,
		radius = radius,
		spin = 90 + math.random() * 120,
	})
end

local function dist(ax: number, ay: number, bx: number, by: number): number
	local dx = ax - bx
	local dy = ay - by
	return math.sqrt(dx * dx + dy * dy)
end

local function addScore(points: number, atX: number, atY: number, text: string)
	score += points
	reportScoreRemote:FireServer(score)
	Effects.floatText(refs.entities, UDim2.fromOffset(atX, atY - 30), text, C.Star, 24)
end

local function collectPickup(i: number)
	local p = pickups[i]
	local centre = UDim2.fromOffset(p.x, p.y)
	if p.kind == "Crystal" then
		combo += 1
		comboTimer = Config.COMBO_WINDOW
		local step = math.min(combo - 1, Config.COMBO_MAX_STEP)
		local points = Config.CRYSTAL_POINTS + step * Config.COMBO_STEP
		crystals += 1
		totalCrystals += 1
		reportCrystalsRemote:FireServer(crystals)
		addScore(points, p.x, p.y, "+" .. tostring(points))
		if combo >= 3 then
			Effects.floatText(
				refs.entities,
				UDim2.fromOffset(p.x, p.y - 62),
				"COMBO x" .. tostring(combo),
				C.Crystal,
				20
			)
		end
		Effects.burstParticles(refs.entities, centre, C.Crystal, 10, 8)
	elseif p.kind == "Star" then
		addScore(Config.STAR_POINTS, p.x, p.y, "+" .. tostring(Config.STAR_POINTS) .. " ★")
		Effects.burstParticles(refs.entities, centre, C.Star, 14, 9)
	elseif p.kind == "Heart" then
		if lives < Config.MAX_LIVES then
			lives += 1
		else
			addScore(25, p.x, p.y, "+25")
		end
		Effects.burstParticles(refs.entities, centre, C.Heart, 12, 8)
	end
	Effects.playPickup()
	p.frame:Destroy()
	table.remove(pickups, i)
end

-- Forward declaration: loseLife ends the run, endRun is defined below.
local endRun

local function loseLife()
	if os.clock() < invulnerableUntil then
		return
	end
	lives -= 1
	reportLifeRemote:FireServer(lives)
	Effects.playHit()
	Effects.flashHit(refs.hitOverlay)
	Effects.shakeScreen(refs.arena, 8, 0.35)
	Effects.burstParticles(refs.entities, UDim2.fromOffset(px, py), C.Danger, 16, 9)
	combo = 0
	comboTimer = 0
	invulnerableUntil = os.clock() + Config.INVULNERABLE_SECONDS
	-- Knock the ship away from the arena centre edge it was hit near.
	pvx = -pvx * 0.6
	pvy = -pvy * 0.6
	if lives <= 0 then
		endRun(false)
	end
end

local function checkCollisions()
	if os.clock() < invulnerableUntil then
		-- Still check pickups while invulnerable; only enemy hits are ignored.
		for i = #pickups, 1, -1 do
			local p = pickups[i]
			if dist(px, py, p.x, p.y) < Config.PLAYER_RADIUS + p.radius then
				collectPickup(i)
			end
		end
		return
	end
	for i = #pickups, 1, -1 do
		local p = pickups[i]
		if dist(px, py, p.x, p.y) < Config.PLAYER_RADIUS + p.radius then
			collectPickup(i)
			if phase ~= "playing" then
				return
			end
		end
	end
	for _, e in ipairs(enemies) do
		if dist(px, py, e.x, e.y) < Config.PLAYER_RADIUS + e.radius - 6 then
			loseLife()
			return
		end
	end
end

local function resetLevelState(levelIndex: number)
	local def = Config.Levels[levelIndex]
	level = levelIndex
	crystals = 0
	timeLeft = def.TimeLimit
	spawnTimer = 0
	heartTimer = 0
	combo = 0
	comboTimer = 0
	px, py = ARENA_W / 2, ARENA_H / 2
	pvx, pvy = 0, 0
	invulnerableUntil = 0
	clearEntities()
	for _ = 1, Config.CRYSTALS_ON_FIELD do
		spawnCrystal()
	end
	placeShip()
end

local function beginLevel(levelIndex: number)
	resetLevelState(levelIndex)
	phase = "playing"
	HUD.showPlaying(refs)
	HUD.updateHUD(
		refs,
		score,
		crystals,
		Config.Levels[level].GoalCrystals,
		lives,
		level,
		timeLeft,
		Config.Levels[level].TimeLimit
	)
	HUD.showBanner(
		Config.Levels[level].Name,
		"Collect " .. tostring(Config.Levels[level].GoalCrystals) .. " crystals!",
		C.ArenaEdge
	)
	ship.Visible = true
	shipGlow.Visible = true
end

local function clearLevel()
	phase = "levelclear"
	levelsCleared += 1
	-- The bonus is a lump sum the server checks on its own call (a
	-- per-second cap would refuse it); the local total syncs from the
	-- server's answer, so the server's number is always the real one.
	local bonus = Config.LEVEL_CLEAR_BONUS + math.floor(timeLeft) * Config.TIME_BONUS_PER_SECOND
	markClearRemote:FireServer()
	reportBonusRemote:FireServer(bonus)
	clearEntities()
	Effects.burstParticles(refs.entities, UDim2.fromOffset(ARENA_W / 2, ARENA_H / 2), C.Star, 40, 10)
	HUD.showBanner("LEVEL CLEAR!", "+" .. tostring(bonus) .. " bonus", C.Star)
	if level >= #Config.Levels then
		task.delay(2, function()
			if phase ~= "levelclear" then
				return
			end
			winGameRemote:FireServer()
			finishRunRemote:FireServer()
		end)
	else
		task.delay(2, function()
			if phase ~= "levelclear" then
				return
			end
			beginLevelRemote:FireServer(level + 1)
		end)
	end
end

endRun = function(won: boolean)
	if phase == "over" then
		return
	end
	phase = "over"
	ship.Visible = false
	shipGlow.Visible = false
	clearEntities()
	if not won then
		loseGameRemote:FireServer()
	end
	finishRunRemote:FireServer()
end

local function startRun()
	score = 0
	totalCrystals = 0
	lives = Config.MAX_LIVES
	levelsCleared = 0
	startGameRemote:FireServer()
end

-- Server answers.
gameStateRemote.OnClientEvent:Connect(function(kind: string, payload: { [string]: any })
	if kind == "Started" then
		best = payload.best or best
		beginLevel(1)
	elseif kind == "StartRefused" then
		HUD.showBanner("PLEASE WAIT", "A run is already in progress.", C.Danger)
	elseif kind == "LevelBegan" then
		if payload.ok then
			beginLevel(payload.level)
		end
	elseif kind == "BestScore" then
		best = payload.best or 0
		if phase == "start" then
			HUD.showStart(refs, best)
		end
	elseif kind == "ScoreChecked" then
		if not payload.ok then
			-- The server refused our total: trust the server's number.
			score = payload.total or score
		end
	elseif kind == "BonusChecked" then
		-- The level-clear bonus lands from the server's own total.
		score = payload.total or score
	elseif kind == "RunFinished" then
		local finalScore = payload.score or score
		local finalBest = payload.best or best
		local isBest = payload.isBest or false
		best = finalBest
		ship.Visible = false
		shipGlow.Visible = false
		local won = levelsCleared >= #Config.Levels and lives > 0
		HUD.showEnd(refs, won, finalScore, finalBest, isBest, totalCrystals, levelsCleared)
	end
end)

refs.playButton.MouseButton1Click:Connect(function()
	startRun()
end)

refs.againButton.MouseButton1Click:Connect(function()
	startRun()
end)

-- Input: WASD or arrow keys. Roblox's default camera scripts eat the arrow
-- keys, so the loop reads the raw key state instead of InputBegan.
local function readMoveInput(): (number, number)
	local dx = 0
	local dy = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.Left) or UserInputService:IsKeyDown(Enum.KeyCode.A) then
		dx -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Right) or UserInputService:IsKeyDown(Enum.KeyCode.D) then
		dx += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Up) or UserInputService:IsKeyDown(Enum.KeyCode.W) then
		dy -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Down) or UserInputService:IsKeyDown(Enum.KeyCode.S) then
		dy += 1
	end
	return dx, dy
end

local starClock = 0

RunService.RenderStepped:Connect(function(dt: number)
	dt = math.min(dt, 0.05)
	starClock += dt
	-- Twinkle a few stars each frame; cheap ambience.
	for i = 1, 6 do
		local star = refs.stars[math.random(#refs.stars)]
		star.BackgroundTransparency = 0.3 + (math.sin(starClock * 2 + i) * 0.5 + 0.5) * 0.6
	end
	if phase ~= "playing" then
		return
	end

	-- Movement with inertia.
	local dx, dy = readMoveInput()
	if dx ~= 0 or dy ~= 0 then
		local len = math.sqrt(dx * dx + dy * dy)
		pvx += (dx / len) * Config.PLAYER_ACCEL * dt
		pvy += (dy / len) * Config.PLAYER_ACCEL * dt
	else
		pvx *= math.max(1 - 6 * dt, 0)
		pvy *= math.max(1 - 6 * dt, 0)
	end
	local speed = math.sqrt(pvx * pvx + pvy * pvy)
	if speed > Config.PLAYER_SPEED then
		pvx = pvx / speed * Config.PLAYER_SPEED
		pvy = pvy / speed * Config.PLAYER_SPEED
	end
	px = math.clamp(px + pvx * dt, Config.PLAYER_RADIUS, ARENA_W - Config.PLAYER_RADIUS)
	py = math.clamp(py + pvy * dt, Config.PLAYER_RADIUS, ARENA_H - Config.PLAYER_RADIUS)
	placeShip()

	-- Invulnerability flashing.
	local invulnerable = os.clock() < invulnerableUntil
	ship.BackgroundTransparency = if invulnerable and math.floor(os.clock() * 12) % 2 == 0 then 0.6 else 0
	shipGlow.BackgroundTransparency = if invulnerable then 0.85 else 0.6

	-- Combo decay.
	if comboTimer > 0 then
		comboTimer -= dt
		if comboTimer <= 0 then
			combo = 0
		end
	end

	-- Timer.
	timeLeft -= dt
	if timeLeft <= 0 then
		timeLeft = 0
		HUD.updateHUD(
			refs,
			score,
			crystals,
			Config.Levels[level].GoalCrystals,
			lives,
			level,
			timeLeft,
			Config.Levels[level].TimeLimit
		)
		endRun(false)
		return
	end

	-- Spawning.
	local def = Config.Levels[level]
	spawnTimer -= dt
	if spawnTimer <= 0 then
		spawnTimer = def.SpawnInterval
		spawnEnemy()
	end
	heartTimer += dt
	if heartTimer >= Config.HEART_SPAWN_SECONDS then
		heartTimer = 0
		local hasHeart = false
		for _, p in ipairs(pickups) do
			if p.kind == "Heart" then
				hasHeart = true
			end
		end
		if not hasHeart then
			spawnPickup("Heart")
		end
	end
	-- Keep the crystal count topped up.
	local crystalCount = 0
	for _, p in ipairs(pickups) do
		if p.kind == "Crystal" or p.kind == "Star" then
			crystalCount += 1
		end
	end
	if crystalCount < Config.CRYSTALS_ON_FIELD then
		spawnCrystal()
	end

	-- Pickups bob in place.
	for _, p in ipairs(pickups) do
		p.bob += dt * 3
		p.frame.Position = UDim2.fromOffset(p.x, p.y + math.sin(p.bob) * 4)
	end

	-- Enemies move; chasers steer, spinners bounce and spin.
	for i = #enemies, 1, -1 do
		local e = enemies[i]
		if e.kind == "Chaser" then
			local dx2 = px - e.x
			local dy2 = py - e.y
			local d = math.sqrt(dx2 * dx2 + dy2 * dy2)
			if d > 1 then
				local steer = 320 * dt
				e.vx += (dx2 / d) * steer
				e.vy += (dy2 / d) * steer
				local s = math.sqrt(e.vx * e.vx + e.vy * e.vy)
				local cap = def.EnemySpeedMax * 0.8
				if s > cap then
					e.vx = e.vx / s * cap
					e.vy = e.vy / s * cap
				end
			end
		elseif e.kind == "Spinner" then
			e.frame.Rotation += e.spin * dt
			if e.x < 20 or e.x > ARENA_W - 20 then
				e.vx = -e.vx
			end
			if e.y < 20 or e.y > ARENA_H - 20 then
				e.vy = -e.vy
			end
		end
		e.x += e.vx * dt
		e.y += e.vy * dt
		e.frame.Position = UDim2.fromOffset(e.x, e.y)
		if e.kind ~= "Spinner" and (e.x < -80 or e.x > ARENA_W + 80 or e.y < -80 or e.y > ARENA_H + 80) then
			e.frame:Destroy()
			table.remove(enemies, i)
		end
	end

	checkCollisions()

	-- Level goal reached?
	if phase == "playing" and crystals >= def.GoalCrystals then
		clearLevel()
		return
	end

	-- HUD refresh, once per whole second of timer plus on change.
	local whole = math.ceil(timeLeft)
	if whole ~= lastHudSecond then
		lastHudSecond = whole
		HUD.updateHUD(refs, score, crystals, def.GoalCrystals, lives, level, timeLeft, def.TimeLimit)
	end
end)

HUD.showStart(refs, best)
print("[NeonRush] client ready — press PLAY to start.")
