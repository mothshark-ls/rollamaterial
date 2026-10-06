--[[
	InventoryService

	Tracks how much food each player is carrying.

	Carried food is one number with a capacity, shown as e.g. 3/15.
	A pickup queue remembers which foods were picked up, in order, so
	feeding can show the right food. Each queue entry is worth a number
	of clicks, and the clicks in the queue always add up to the carried
	food.

	CarriedFood and FoodCapacity are also set as player attributes so
	the client can show them.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FoodConfig = require(
	ReplicatedStorage
		:WaitForChild("Shared")
		:WaitForChild("Config")
		:WaitForChild("FoodConfig")
)

local InventoryService = {}

-- Prints each player's food counter to Output while there is no UI.
local DEBUG_PRINT_COUNTER = true

-- player -> { Food = number, Capacity = number, Queue = { { FoodId, Clicks } } }
local playerData = {}

--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function updateAttributes(player, data)

	player:SetAttribute("CarriedFood", data.Food)
	player:SetAttribute("FoodCapacity", data.Capacity)

	if DEBUG_PRINT_COUNTER then
		print(string.format("[Food] %s: %d/%d", player.Name, data.Food, data.Capacity))
	end

end

local function setupPlayer(player)

	local data = {
		Food = 0,
		Capacity = FoodConfig.StartingCapacity,
		Queue = {},
	}

	playerData[player] = data

	updateAttributes(player, data)

end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

function InventoryService:Init()

end

--------------------------------------------------
-- START
--------------------------------------------------

function InventoryService:Start()

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)

		playerData[player] = nil

	end)

	for _, player in ipairs(Players:GetPlayers()) do

		setupPlayer(player)

	end

end

--------------------------------------------------
-- ADD FOOD
--------------------------------------------------

-- Adds a picked-up food. Only the space left is added, so a +2 food
-- at 14/15 adds 1. Returns false if the player is full.
function InventoryService:AddFood(player, foodId, foodValue)

	local data = playerData[player]

	if not data then
		return false
	end

	if type(foodValue) ~= "number" or foodValue <= 0 then
		return false
	end

	local space = data.Capacity - data.Food

	if space <= 0 then
		return false
	end

	local amount = math.min(foodValue, space)

	data.Food += amount

	table.insert(data.Queue, {
		FoodId = foodId,
		Clicks = amount,
	})

	updateAttributes(player, data)

	return true

end

--------------------------------------------------
-- TAKE FOOD
--------------------------------------------------

-- Takes up to `amount` food for feeding Gubby. Each unit comes from the
-- front of the pickup queue. Returns the FoodId of each unit taken, in
-- pickup order. When the counter reaches 0 the queue is cleared.
function InventoryService:TakeFood(player, amount)

	local data = playerData[player]
	local taken = {}

	if not data then
		return taken
	end

	while #taken < amount and data.Food > 0 do

		local entry = data.Queue[1]

		if not entry then
			break
		end

		table.insert(taken, entry.FoodId)

		entry.Clicks -= 1
		data.Food -= 1

		if entry.Clicks <= 0 then
			table.remove(data.Queue, 1)
		end

	end

	if data.Food <= 0 then
		data.Food = 0
		table.clear(data.Queue)
	end

	if #taken > 0 then
		updateAttributes(player, data)
	end

	return taken

end

--------------------------------------------------
-- CLEAR ALL
--------------------------------------------------

-- Empties every player's carried food. Used when the run restarts.
function InventoryService:ClearAll()

	for player, data in pairs(playerData) do

		data.Food = 0
		table.clear(data.Queue)

		updateAttributes(player, data)

	end

end

--------------------------------------------------
-- GET FOOD
--------------------------------------------------

function InventoryService:GetFood(player)

	local data = playerData[player]

	return data and data.Food or 0

end

return InventoryService
