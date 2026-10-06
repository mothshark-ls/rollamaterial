--[[
	HungerService

	Gubby's hunger timer. It counts down one second at a time while
	players are in the server. Feeding adds SecondsPerFood for each food
	unit. When it reaches 0, TimeUp fires.

	The time left is stored as the HungerTime attribute on Workspace.Gubby
	so the client can show it later.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GubbyConfig = require(
	ReplicatedStorage
		:WaitForChild("Shared")
		:WaitForChild("Config")
		:WaitForChild("GubbyConfig")
)

local HungerService = {}

-- Prints the timer to Output while there is no UI.
local DEBUG_PRINT_TIMER = true

--------------------------------------------------
-- STATE
--------------------------------------------------

local timeLeft = 0

--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function updateAttribute()

	local gubbyModel = workspace:FindFirstChild("Gubby")

	if gubbyModel then
		gubbyModel:SetAttribute("HungerTime", timeLeft)
	end

end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

function HungerService:Init()

	-- Fires when the timer reaches 0.
	self.TimeUp = Instance.new("BindableEvent")

end

--------------------------------------------------
-- START
--------------------------------------------------

function HungerService:Start()

	self:Reset()

	task.spawn(function()

		while true do

			task.wait(1)

			if #Players:GetPlayers() > 0 and timeLeft > 0 then

				timeLeft -= 1
				updateAttribute()

				if DEBUG_PRINT_TIMER then
					print(string.format("[Hunger] %ds left", timeLeft))
				end

				if timeLeft <= 0 then
					self.TimeUp:Fire()
				end

			end

		end

	end)

end

--------------------------------------------------
-- ADD TIME
--------------------------------------------------

function HungerService:AddFood(foodAmount)

	timeLeft += foodAmount * GubbyConfig.SecondsPerFood
	updateAttribute()

end

--------------------------------------------------
-- RESET
--------------------------------------------------

function HungerService:Reset()

	timeLeft = GubbyConfig.HungerStartTime
	updateAttribute()

end

return HungerService
