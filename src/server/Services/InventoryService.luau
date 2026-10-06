--[[
	InventoryService

	Stores the total amount of Food currently carried
	by each player.

	Food is represented as one number.

	Example:

	Food = 18

	The type of food collected does not matter after
	pickup. FoodConfig determines how much Food the
	picked-up object contributes.
]]

local Players = game:GetService("Players")

local InventoryService = {}

local foodAmounts = {}

function InventoryService:Init()

end

function InventoryService:Start()

	Players.PlayerAdded:Connect(function(player)

		foodAmounts[player] = 0

	end)

	Players.PlayerRemoving:Connect(function(player)

		foodAmounts[player] = nil

	end)

	for _, player in ipairs(Players:GetPlayers()) do

		foodAmounts[player] = 0

	end

end

function InventoryService:AddFood(
	player,
	amount
)

	if type(amount) ~= "number" then
		return false
	end

	if amount <= 0 then
		return false
	end

	if not foodAmounts[player] then
		return false
	end

	foodAmounts[player] =
		foodAmounts[player] + amount

	return true

end

function InventoryService:GetFood(player)

	return foodAmounts[player] or 0

end

function InventoryService:RemoveFood(
	player,
	amount
)

	if type(amount) ~= "number" then
		return false
	end

	if amount <= 0 then
		return false
	end

	local currentFood =
		foodAmounts[player]

	if currentFood == nil then
		return false
	end

	if currentFood < amount then
		return false
	end

	foodAmounts[player] =
		currentFood - amount

	return true

end

return InventoryService