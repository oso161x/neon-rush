-- NEON RUSH: Crystal Run — every pixel of interface.
-- Builds the start screen, the HUD bar, the end screens and the level
-- banners, and owns updating them. The game logic never builds GUI; it
-- calls showStart / updateHUD / showBanner / showEnd. Layout is centred,
-- with the HUD bar across the top middle, clear of Roblox's own menu
-- buttons in the top-left corner.

local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local HUD = {}

local C = Config.Colors

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function stroke(parent: Instance, colour: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = colour
	s.Thickness = thickness
	s.Parent = parent
	return s
end

local function label(
	parent: Instance,
	name: string,
	text: string,
	size: number,
	colour: Color3,
	font: Enum.Font,
	position: UDim2,
	labelSize: UDim2
): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Text = text
	l.TextSize = size
	l.TextColor3 = colour
	l.Font = font
	l.BackgroundTransparency = 1
	l.Position = position
	l.Size = labelSize
	l.Parent = parent
	return l
end

local function button(
	parent: Instance,
	name: string,
	text: string,
	size: UDim2,
	position: UDim2,
	colour: Color3
): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = text
	b.TextSize = 30
	b.TextColor3 = Color3.fromRGB(8, 12, 30)
	b.Font = Enum.Font.GothamBlack
	b.BackgroundColor3 = colour
	b.Position = position
	b.Size = size
	b.AnchorPoint = Vector2.new(0.5, 0)
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 14)
	stroke(b, Color3.fromRGB(255, 255, 255), 2)
	return b
end

-- A centred panel used by the start and end screens.
local function makePanel(parent: Instance, name: string): Frame
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(660, 460)
	panel.BackgroundColor3 = C.Panel
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = parent
	corner(panel, 20)
	stroke(panel, C.ArenaEdge, 3)
	return panel
end

function HUD.build(playerGui: PlayerGui)
	local refs: { [string]: any } = {}

	local gui = Instance.new("ScreenGui")
	gui.Name = "NeonRushGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10
	gui.Parent = playerGui
	refs.gui = gui

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = C.Background
	background.BorderSizePixel = 0
	background.Parent = gui
	refs.background = background

	-- Starfield: faint dots scattered over the background, twinkling later.
	refs.stars = {}
	for i = 1, 48 do
		local star = Instance.new("Frame")
		star.Name = "Star" .. i
		star.AnchorPoint = Vector2.new(0.5, 0.5)
		star.Position = UDim2.fromScale(math.random(), math.random())
		local s = math.random(2, 4)
		star.Size = UDim2.fromOffset(s, s)
		star.BackgroundColor3 = Color3.fromRGB(200, 220, 255)
		star.BackgroundTransparency = 0.35 + math.random() * 0.5
		star.BorderSizePixel = 0
		star.Parent = background
		corner(star, 4)
		refs.stars[i] = star
	end

	-- The arena: the play field everything happens in.
	local arena = Instance.new("Frame")
	arena.Name = "Arena"
	arena.AnchorPoint = Vector2.new(0.5, 0.5)
	arena.Position = UDim2.fromScale(0.5, 0.56)
	arena.Size = UDim2.fromOffset(Config.ARENA_WIDTH, Config.ARENA_HEIGHT)
	arena.BackgroundColor3 = C.Arena
	arena.BorderSizePixel = 0
	arena.ClipsDescendants = true
	arena.Parent = gui
	corner(arena, 12)
	stroke(arena, C.ArenaEdge, 3)
	refs.arena = arena

	-- Entities (player, pickups, enemies, particles) live in this layer.
	local entities = Instance.new("Frame")
	entities.Name = "Entities"
	entities.Size = UDim2.fromScale(1, 1)
	entities.BackgroundTransparency = 1
	entities.Parent = arena
	refs.entities = entities

	-- Red flash overlay for taking a hit.
	local hitOverlay = Instance.new("Frame")
	hitOverlay.Name = "HitOverlay"
	hitOverlay.Size = UDim2.fromScale(1, 1)
	hitOverlay.BackgroundColor3 = C.Danger
	hitOverlay.BackgroundTransparency = 1
	hitOverlay.BorderSizePixel = 0
	hitOverlay.Parent = arena
	corner(hitOverlay, 12)
	refs.hitOverlay = hitOverlay

	-- HUD bar: one centred row across the top middle, clear of the corner.
	local hudBar = Instance.new("Frame")
	hudBar.Name = "HUDBar"
	hudBar.AnchorPoint = Vector2.new(0.5, 0)
	hudBar.Position = UDim2.new(0.5, 0, 0, 12)
	hudBar.Size = UDim2.fromOffset(860, 52)
	hudBar.BackgroundColor3 = C.Panel
	hudBar.BackgroundTransparency = 0.15
	hudBar.BorderSizePixel = 0
	hudBar.Visible = false
	hudBar.Parent = gui
	corner(hudBar, 12)
	stroke(hudBar, C.ArenaEdge, 2)
	refs.hudBar = hudBar

	refs.scoreLabel = label(
		hudBar,
		"Score",
		"SCORE 0",
		26,
		C.Text,
		Config.FontBody,
		UDim2.new(0, 18, 0, 6),
		UDim2.fromOffset(180, 40)
	)
	refs.crystalLabel = label(
		hudBar,
		"Crystals",
		"◆ 0/8",
		26,
		C.Crystal,
		Config.FontBody,
		UDim2.new(0, 210, 0, 6),
		UDim2.fromOffset(130, 40)
	)
	refs.livesLabel = label(
		hudBar,
		"Lives",
		"♥♥♥",
		26,
		C.Heart,
		Config.FontBody,
		UDim2.new(0, 350, 0, 6),
		UDim2.fromOffset(110, 40)
	)
	refs.levelLabel = label(
		hudBar,
		"Level",
		"LEVEL 1",
		26,
		C.Star,
		Config.FontBody,
		UDim2.new(0, 470, 0, 6),
		UDim2.fromOffset(130, 40)
	)
	refs.timeLabel =
		label(hudBar, "Time", "75", 26, C.Text, Config.FontBody, UDim2.new(0, 610, 0, 6), UDim2.fromOffset(90, 40))

	-- Timer bar under the HUD row.
	local timerBack = Instance.new("Frame")
	timerBack.Name = "TimerBack"
	timerBack.AnchorPoint = Vector2.new(0.5, 0)
	timerBack.Position = UDim2.new(0.5, 0, 0, 70)
	timerBack.Size = UDim2.fromOffset(860, 8)
	timerBack.BackgroundColor3 = Color3.fromRGB(40, 46, 90)
	timerBack.BorderSizePixel = 0
	timerBack.Visible = false
	timerBack.Parent = gui
	corner(timerBack, 4)
	refs.timerBack = timerBack
	local timerFill = Instance.new("Frame")
	timerFill.Name = "TimerFill"
	timerFill.Size = UDim2.fromScale(1, 1)
	timerFill.BackgroundColor3 = C.Star
	timerFill.BorderSizePixel = 0
	timerFill.Parent = timerBack
	corner(timerFill, 4)
	refs.timerFill = timerFill

	-- Level banner: big centre text that pops in and out.
	local banner = Instance.new("TextLabel")
	banner.Name = "Banner"
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.fromScale(0.5, 0.42)
	banner.Size = UDim2.fromOffset(900, 90)
	banner.BackgroundTransparency = 1
	banner.Text = ""
	banner.TextColor3 = C.Text
	banner.Font = Config.FontTitle
	banner.TextSize = 54
	banner.TextStrokeTransparency = 0.4
	banner.Visible = false
	banner.Parent = gui
	refs.banner = banner
	local bannerSub = Instance.new("TextLabel")
	bannerSub.Name = "BannerSub"
	bannerSub.AnchorPoint = Vector2.new(0.5, 0.5)
	bannerSub.Position = UDim2.fromScale(0.5, 0.5)
	bannerSub.Size = UDim2.fromOffset(900, 40)
	bannerSub.BackgroundTransparency = 1
	bannerSub.Text = ""
	bannerSub.TextColor3 = C.DimText
	bannerSub.Font = Config.FontBody
	bannerSub.TextSize = 24
	bannerSub.Visible = false
	bannerSub.Parent = gui
	refs.bannerSub = bannerSub

	-- Start screen.
	local startPanel = makePanel(gui, "StartPanel")
	refs.startPanel = startPanel
	label(
		startPanel,
		"Title",
		"NEON RUSH",
		68,
		C.ArenaEdge,
		Config.FontTitle,
		UDim2.new(0.5, 0, 0, 28),
		UDim2.fromOffset(620, 84)
	).AnchorPoint =
		Vector2.new(0.5, 0)
	label(
		startPanel,
		"Subtitle",
		"★ C R Y S T A L   R U N ★",
		24,
		C.Star,
		Config.FontBody,
		UDim2.new(0.5, 0, 0, 112),
		UDim2.fromOffset(620, 34)
	).AnchorPoint =
		Vector2.new(0.5, 0)
	label(
		startPanel,
		"HowTo",
		"Collect the crystals before time runs out.\nDodge the red meteors — 3 hits and the run ends.\nGolden stars are worth 50. Chain pickups for combo points!",
		22,
		C.Text,
		Config.FontBody,
		UDim2.new(0.5, 0, 0, 158),
		UDim2.fromOffset(600, 108)
	).AnchorPoint =
		Vector2.new(0.5, 0)
	label(
		startPanel,
		"Controls",
		"MOVE: WASD or Arrow Keys",
		22,
		C.DimText,
		Config.FontBody,
		UDim2.new(0.5, 0, 0, 272),
		UDim2.fromOffset(600, 32)
	).AnchorPoint =
		Vector2.new(0.5, 0)
	refs.bestLabel = label(
		startPanel,
		"Best",
		"BEST SCORE: 0",
		22,
		C.Star,
		Config.FontBody,
		UDim2.new(0.5, 0, 0, 310),
		UDim2.fromOffset(600, 32)
	)
	refs.bestLabel.AnchorPoint = Vector2.new(0.5, 0)
	refs.playButton =
		button(startPanel, "PlayButton", "PLAY", UDim2.fromOffset(260, 64), UDim2.new(0.5, 0, 0, 356), C.Crystal)

	-- End screen (win or game over — same panel, different words).
	local endPanel = makePanel(gui, "EndPanel")
	refs.endPanel = endPanel
	refs.endTitle = label(
		endPanel,
		"EndTitle",
		"GAME OVER",
		60,
		C.Danger,
		Config.FontTitle,
		UDim2.new(0.5, 0, 0, 36),
		UDim2.fromOffset(620, 76)
	)
	refs.endTitle.AnchorPoint = Vector2.new(0.5, 0)
	refs.endStats = label(
		endPanel,
		"EndStats",
		"",
		26,
		C.Text,
		Config.FontBody,
		UDim2.new(0.5, 0, 0, 130),
		UDim2.fromOffset(600, 120)
	)
	refs.endStats.AnchorPoint = Vector2.new(0.5, 0)
	refs.endBest = label(
		endPanel,
		"EndBest",
		"",
		24,
		C.Star,
		Config.FontBody,
		UDim2.new(0.5, 0, 0, 256),
		UDim2.fromOffset(600, 36)
	)
	refs.endBest.AnchorPoint = Vector2.new(0.5, 0)
	refs.againButton =
		button(endPanel, "AgainButton", "PLAY AGAIN", UDim2.fromOffset(300, 64), UDim2.new(0.5, 0, 0, 320), C.Crystal)

	return refs
end

function HUD.showStart(refs, best: number)
	refs.endPanel.Visible = false
	refs.hudBar.Visible = false
	refs.timerBack.Visible = false
	refs.bestLabel.Text = "BEST SCORE: " .. tostring(best)
	refs.startPanel.Visible = true
end

function HUD.showPlaying(refs)
	refs.startPanel.Visible = false
	refs.endPanel.Visible = false
	refs.hudBar.Visible = true
	refs.timerBack.Visible = true
end

function HUD.updateHUD(
	refs,
	score: number,
	crystals: number,
	goal: number,
	lives: number,
	level: number,
	timeLeft: number,
	timeLimit: number
)
	refs.scoreLabel.Text = "SCORE " .. tostring(score)
	refs.crystalLabel.Text = "◆ " .. tostring(crystals) .. "/" .. tostring(goal)
	local hearts = ""
	for _ = 1, lives do
		hearts ..= "♥"
	end
	refs.livesLabel.Text = hearts
	refs.levelLabel.Text = "LEVEL " .. tostring(level)
	refs.timeLabel.Text = tostring(math.max(math.ceil(timeLeft), 0))
	local frac = math.clamp(timeLeft / timeLimit, 0, 1)
	refs.timerFill.Size = UDim2.fromScale(frac, 1)
	if timeLeft <= 10 then
		refs.timerFill.BackgroundColor3 = C.Danger
		refs.timeLabel.TextColor3 = C.Danger
	else
		refs.timerFill.BackgroundColor3 = C.Star
		refs.timeLabel.TextColor3 = C.Text
	end
end

local bannerToken = 0
function HUD.showBanner(refs, text: string, subtext: string, colour: Color3)
	bannerToken += 1
	local token = bannerToken
	refs.banner.Text = text
	refs.banner.TextColor3 = colour
	refs.bannerSub.Text = subtext or ""
	refs.banner.Visible = true
	refs.bannerSub.Visible = true
	refs.banner.TextTransparency = 0
	refs.bannerSub.TextTransparency = 0
	refs.banner.Size = UDim2.fromOffset(700, 70)
	local pop = TweenService:Create(refs.banner, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(900, 90),
	})
	pop:Play()
	task.delay(1.6, function()
		if token ~= bannerToken then
			return
		end
		local fade = TweenService:Create(refs.banner, TweenInfo.new(0.4), { TextTransparency = 1 })
		local fadeSub = TweenService:Create(refs.bannerSub, TweenInfo.new(0.4), { TextTransparency = 1 })
		fade:Play()
		fadeSub:Play()
		fade.Completed:Connect(function()
			if token == bannerToken then
				refs.banner.Visible = false
				refs.bannerSub.Visible = false
			end
		end)
	end)
end

function HUD.showEnd(
	refs,
	won: boolean,
	score: number,
	best: number,
	isBest: boolean,
	crystals: number,
	levelsCleared: number
)
	refs.hudBar.Visible = false
	refs.timerBack.Visible = false
	if won then
		refs.endTitle.Text = "★ YOU WIN! ★"
		refs.endTitle.TextColor3 = C.Star
	else
		refs.endTitle.Text = "GAME OVER"
		refs.endTitle.TextColor3 = C.Danger
	end
	refs.endStats.Text = "SCORE  "
		.. tostring(score)
		.. "\nCRYSTALS  "
		.. tostring(crystals)
		.. "\nLEVELS CLEARED  "
		.. tostring(levelsCleared)
		.. " / 3"
	if isBest then
		refs.endBest.Text = "★ NEW BEST SCORE! ★"
	else
		refs.endBest.Text = "BEST SCORE: " .. tostring(best)
	end
	refs.endPanel.Visible = true
end

return HUD
