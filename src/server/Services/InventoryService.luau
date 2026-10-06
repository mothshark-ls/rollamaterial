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

-- player -> { Food = number, Capacity = number, Queue = { { FoodId, Clicks } } }
local playerData = {}

--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function updateAttributes(player, data)

	player:SetAttribute("CarriedFood", data.Food)
	player:SetAttribute("FoodCapacity", data.Capacity)

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
-- GET FOOD
--------------------------------------------------

function InventoryService:GetFood(player)

	local data = playerData[player]

	return data and data.Food or 0

end

return InventoryService
