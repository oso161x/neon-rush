-- NEON RUSH: Crystal Run — server bootstrap.
-- Creates the RemoteEvents the client talks through, then hands every call
-- to GameServer, which owns the session. Nothing here trusts the client:
-- each handler returns the server's answer, and a bad call is a quiet no.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- NOTE (2026-11-15 fix): this file is the init script of its Rojo folder, so
-- the folder IS this Script and GameServer is its CHILD — not a sibling under
-- ServerScriptService. `script.Parent:WaitForChild("GameServer")` hung forever
-- (server never started, no remotes, client hung, no UI at all in Play).
local GameServer = require(script:WaitForChild("GameServer"))

local remotes = Instance.new("Folder")
remotes.Name = "NeonRushRemotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

-- Client -> server requests.
local startGameRemote = makeRemote("StartGame")
local beginLevelRemote = makeRemote("BeginLevel")
local reportScoreRemote = makeRemote("ReportScore")
local reportBonusRemote = makeRemote("ReportBonus")
local reportCrystalsRemote = makeRemote("ReportCrystals")
local reportLifeRemote = makeRemote("ReportLifeLost")
local finishRunRemote = makeRemote("FinishRun")
local markClearRemote = makeRemote("MarkLevelClear")
local winGameRemote = makeRemote("WinGame")
local loseGameRemote = makeRemote("LoseGame")

-- Server -> client answers (one channel, typed by its first field).
local gameStateRemote = makeRemote("GameState")

local function sendState(player: Player, kind: string, payload: { [string]: any })
	gameStateRemote:FireClient(player, kind, payload or {})
end

Players.PlayerAdded:Connect(function(player)
	GameServer.playerJoined(player)
	local session = GameServer.getSession(player)
	-- The client shows the best score on the start screen as soon as it loads.
	task.spawn(function()
		task.wait(0.5)
		if session then
			sendState(player, "BestScore", { best = session.best })
		end
	end)
end)

startGameRemote.OnServerEvent:Connect(function(player)
	local ok, why = GameServer.startGame(player)
	if ok then
		sendState(player, "Started", { level = 1, best = (GameServer.getSession(player) or {}).best or 0 })
	else
		sendState(player, "StartRefused", { reason = why })
	end
end)

beginLevelRemote.OnServerEvent:Connect(function(player, level)
	local ok = GameServer.beginLevel(player, level)
	sendState(player, "LevelBegan", { level = level, ok = ok })
end)

reportScoreRemote.OnServerEvent:Connect(function(player, total)
	local ok, serverTotal = GameServer.reportScore(player, total)
	sendState(player, "ScoreChecked", { ok = ok, total = serverTotal })
end)

reportBonusRemote.OnServerEvent:Connect(function(player, bonus)
	local ok, serverTotal = GameServer.reportBonus(player, bonus)
	sendState(player, "BonusChecked", { ok = ok, total = serverTotal })
end)

reportCrystalsRemote.OnServerEvent:Connect(function(player, count)
	GameServer.reportCrystals(player, count)
end)

reportLifeRemote.OnServerEvent:Connect(function(player, livesLeft)
	GameServer.reportLifeLost(player, livesLeft)
end)

markClearRemote.OnServerEvent:Connect(function(player)
	GameServer.markLevelClear(player)
end)

winGameRemote.OnServerEvent:Connect(function(player)
	GameServer.winGame(player)
end)

loseGameRemote.OnServerEvent:Connect(function(player)
	GameServer.loseGame(player)
end)

finishRunRemote.OnServerEvent:Connect(function(player)
	local finalScore, best, isBest = GameServer.finishRun(player)
	sendState(player, "RunFinished", { score = finalScore, best = best, isBest = isBest })
end)

print("[NeonRush] server ready — remotes live, sessions owned by GameServer.")
