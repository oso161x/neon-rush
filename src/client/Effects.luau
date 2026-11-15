-- NEON RUSH: Crystal Run — juice. Every visible reaction to what the
-- player does lives here: pickup bursts, hit flashes, screen shake, floating
-- score text and the two built-in sounds. The game logic never touches a
-- GuiObject directly for feedback; it calls one of these.

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Effects = {}

-- One shared sound parent, created lazily under the GUI root.
local soundParent: Instance? = nil
local pickupSound: Sound? = nil
local hitSound: Sound? = nil

local function getSounds(guiRoot: Instance)
	if soundParent then
		return
	end
	soundParent = Instance.new("Folder")
	soundParent.Name = "NeonRushSounds"
	soundParent.Parent = guiRoot
	-- Built-in client sounds: they ship with Roblox, no asset upload needed.
	pickupSound = Instance.new("Sound")
	pickupSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	pickupSound.Volume = 0.5
	pickupSound.Parent = soundParent
	hitSound = Instance.new("Sound")
	hitSound.SoundId = "rbxasset://sounds/button.wav"
	hitSound.Volume = 0.7
	hitSound.Parent = soundParent
end

function Effects.init(guiRoot: Instance)
	getSounds(guiRoot)
end

function Effects.playPickup()
	if pickupSound then
		pcall(function()
			pickupSound:Play()
		end)
	end
end

function Effects.playHit()
	if hitSound then
		pcall(function()
			hitSound:Play()
		end)
	end
end

-- A burst of small squares that fly outwards and fade. Used for pickups,
-- hits and level clears; colour and size are the caller's.
function Effects.burstParticles(parent: Instance, centre: UDim2, colour: Color3, count: number, size: number)
	for _ = 1, count do
		local bit = Instance.new("Frame")
		bit.Name = "Particle"
		bit.AnchorPoint = Vector2.new(0.5, 0.5)
		bit.Position = centre
		bit.Size = UDim2.fromOffset(size, size)
		bit.BackgroundColor3 = colour
		bit.BorderSizePixel = 0
		bit.Parent = parent
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = bit

		local angle = math.random() * math.pi * 2
		local distance = 34 + math.random() * 46
		local target = UDim2.new(
			centre.X.Scale,
			centre.X.Offset + math.cos(angle) * distance,
			centre.Y.Scale,
			centre.Y.Offset + math.sin(angle) * distance
		)
		local tween = TweenService:Create(
			bit,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = target, BackgroundTransparency = 1, Size = UDim2.fromOffset(2, 2) }
		)
		tween:Play()
		tween.Completed:Connect(function()
			bit:Destroy()
		end)
	end
end

-- Floating "+10" / "COMBO x3" text that rises and fades where it happened.
function Effects.floatText(parent: Instance, centre: UDim2, text: string, colour: Color3, textSize: number)
	local label = Instance.new("TextLabel")
	label.Name = "FloatText"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = centre
	label.Size = UDim2.fromOffset(160, 36)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = colour
	label.Font = Enum.Font.GothamBlack
	label.TextSize = textSize
	label.TextStrokeTransparency = 0.6
	label.Parent = parent

	local tween = TweenService:Create(
		label,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = centre + UDim2.fromOffset(0, -56), TextTransparency = 1, TextStrokeTransparency = 1 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

-- A full-arena red flash for taking a hit, fading fast.
function Effects.flashHit(overlay: GuiObject)
	overlay.BackgroundTransparency = 0.55
	local tween = TweenService:Create(
		overlay,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	tween:Play()
end

-- Shake the arena frame for `duration` seconds; the frame returns to its
-- rest position when the shake ends. Only one shake runs at a time.
local shakeToken = 0
function Effects.shakeScreen(arena: GuiObject, strength: number, duration: number)
	shakeToken += 1
	local token = shakeToken
	local rest = arena.Position
	local startedAt = os.clock()
	task.spawn(function()
		while os.clock() - startedAt < duration and token == shakeToken do
			local dx = math.random(-strength, strength)
			local dy = math.random(-strength, strength)
			arena.Position = rest + UDim2.fromOffset(dx, dy)
			task.wait(0.03)
		end
		if token == shakeToken then
			arena.Position = rest
		end
	end)
end

-- Fade a whole screen in (from transparent) or out, for transitions.
function Effects.fadeGroup(frame: GuiObject, targetTransparency: number, duration: number)
	local tween = TweenService:Create(
		frame,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = targetTransparency }
	)
	tween:Play()
	return tween
end

return Effects
