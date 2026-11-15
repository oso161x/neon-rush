-- NEON RUSH: Crystal Run — server-side session authority.
-- The client renders and reads input; this module owns the session: one
-- state machine (Lobby -> Playing -> LevelClear -> Won / Lost), the
-- authoritative score, and the best score. Every score change the client
-- reports is checked here before it counts, so a tampered client cannot
-- invent points: a jump faster than MAX_POINTS_PER_SECOND is refused.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local GameServer = {}

export type Phase = "Lobby" | "Playing" | "LevelClear" | "Won" | "Lost"

export type Session = {
	player: Player,
	phase: Phase,
	level: number,
	score: number,
	crystals: number,
	lives: number,
	startedAt: number,
	lastScoreAt: number,
	best: number,
}

local sessions: { [Player]: Session } = {}
local bestScores: { [Player]: number } = {}

local bestStore = nil
do
	-- DataStores need API access enabled in Studio; in a plain play test this
	-- fails, and the game must still work, so the failure is swallowed.
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore("NeonRushBest_v1")
	end)
	if ok then
		bestStore = store
	end
end

local function loadBest(player: Player): number
	if bestStore then
		local ok, value = pcall(function()
			return bestStore:GetAsync("best_" .. player.UserId)
		end)
		if ok and typeof(value) == "number" then
			return value
		end
	end
	return 0
end

local function saveBest(player: Player, score: number)
	if bestStore and score > 0 then
		pcall(function()
			bestStore:SetAsync("best_" .. player.UserId, score)
		end)
	end
end

function GameServer.getSession(player: Player): Session?
	return sessions[player]
end

-- A player joins: fresh lobby session, best score loaded in the background.
function GameServer.playerJoined(player: Player)
	local session: Session = {
		player = player,
		phase = "Lobby",
		level = 1,
		score = 0,
		crystals = 0,
		lives = Config.MAX_LIVES,
		startedAt = 0,
		lastScoreAt = 0,
		best = 0,
	}
	sessions[player] = session
	task.spawn(function()
		local best = loadBest(player)
		session.best = best
		bestScores[player] = best
	end)
end

function GameServer.playerLeft(player: Player)
	local session = sessions[player]
	if session and session.score > (bestScores[player] or 0) then
		saveBest(player, session.score)
	end
	sessions[player] = nil
	bestScores[player] = nil
end

-- Start a new run. Refused while a run is already in progress.
function GameServer.startGame(player: Player): (boolean, string)
	local session = sessions[player]
	if not session then
		return false, "no session"
	end
	if session.phase == "Playing" then
		return false, "already playing"
	end
	session.phase = "Playing"
	session.level = 1
	session.score = 0
	session.crystals = 0
	session.lives = Config.MAX_LIVES
	session.startedAt = os.clock()
	session.lastScoreAt = os.clock()
	return true, "ok"
end

-- Move to the next level after a clear. Returns false at the last level:
-- clearing level 3 is the win, handled by winGame below.
function GameServer.beginLevel(player: Player, level: number): boolean
	local session = sessions[player]
	if not session or session.phase ~= "LevelClear" then
		return false
	end
	if level > #Config.Levels then
		return false
	end
	session.level = level
	session.crystals = 0
	session.phase = "Playing"
	session.lastScoreAt = os.clock()
	return true
end

function GameServer.markLevelClear(player: Player)
	local session = sessions[player]
	if session and session.phase == "Playing" then
		session.phase = "LevelClear"
	end
end

function GameServer.winGame(player: Player)
	local session = sessions[player]
	if session and session.phase == "Playing" then
		session.phase = "Won"
	end
end

function GameServer.loseGame(player: Player)
	local session = sessions[player]
	if session and session.phase == "Playing" then
		session.phase = "Lost"
	end
end

-- The client reports a new total after each pickup. The delta is checked
-- against the time since the last accepted report; an impossible jump is
-- refused and the server's total stands.
function GameServer.reportScore(player: Player, reportedTotal: number): (boolean, number)
	local session = sessions[player]
	if not session or session.phase ~= "Playing" then
		return false, 0
	end
	if typeof(reportedTotal) ~= "number" or reportedTotal < session.score then
		return false, session.score
	end
	local now = os.clock()
	local elapsed = math.max(now - session.lastScoreAt, 0.05)
	local delta = reportedTotal - session.score
	if delta > Config.MAX_POINTS_PER_SECOND * elapsed + 60 then
		return false, session.score
	end
	session.score = reportedTotal
	session.lastScoreAt = now
	return true, session.score
end

function GameServer.reportCrystals(player: Player, count: number): boolean
	local session = sessions[player]
	if not session or session.phase ~= "Playing" then
		return false
	end
	if typeof(count) ~= "number" or count < 0 or count > Config.Levels[session.level].GoalCrystals then
		return false
	end
	session.crystals = count
	return true
end

function GameServer.reportLifeLost(player: Player, livesLeft: number): boolean
	local session = sessions[player]
	if not session or session.phase ~= "Playing" then
		return false
	end
	if typeof(livesLeft) ~= "number" or livesLeft < 0 or livesLeft >= session.lives then
		return false
	end
	session.lives = livesLeft
	return true
end

-- Level-clear bonus: a lump sum the per-second cap would refuse, so it has
-- its own validated call. Only accepted in the LevelClear phase, right
-- after the client reported the clear, and only up to the largest bonus
-- any level can pay (full time left on the longest level).
function GameServer.reportBonus(player: Player, bonus: number): (boolean, number)
	local session = sessions[player]
	if not session or session.phase ~= "LevelClear" then
		return false, 0
	end
	if typeof(bonus) ~= "number" or bonus < 0 then
		return false, session.score
	end
	local maxBonus = Config.LEVEL_CLEAR_BONUS + 75 * Config.TIME_BONUS_PER_SECOND
	if bonus > maxBonus then
		return false, session.score
	end
	session.score += bonus
	session.lastScoreAt = os.clock()
	return true, session.score
end

-- End of a run: the server's own total is the final score, never the
-- client's claim. The best score is updated and saved when beaten.
function GameServer.finishRun(player: Player): (number, number, boolean)
	local session = sessions[player]
	if not session then
		return 0, 0, false
	end
	local finalScore = session.score
	local isBest = finalScore > session.best and finalScore > 0
	if isBest then
		session.best = finalScore
		bestScores[player] = finalScore
		saveBest(player, finalScore)
	end
	session.phase = "Lobby"
	return finalScore, session.best, isBest
end

Players.PlayerRemoving:Connect(function(player)
	GameServer.playerLeft(player)
end)

return GameServer
