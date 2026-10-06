--[[
	FoodService

	Phase 1 responsibilities:

	1. Spawn food at the designated food spawn points.
	2. Give spawned food a pickup interaction.
	3. Validate pickup requests on the server.
	4. Add collected food to InventoryService.
	5. Remove collected food from the world.

	The physical food model only identifies itself with FoodId.

	All actual food properties come from FoodConfig.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local FoodService = {}

--------------------------------------------------
-- FOLDERS
--------------------------------------------------

local FoodFolder = workspace:WaitForChild("Food")
local FoodSpawnsFolder = workspace:WaitForChild("FoodSpawns")

local FoodModelsFolder = ServerStorage:WaitForChild("FoodModels")

local ConfigFolder = ReplicatedStorage
	:WaitForChild("Shared")
	:WaitForChild("Config")

local FoodConfig = require(
	ConfigFolder:WaitForChild("FoodConfig")
)

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local PICKUP_DISTANCE = 10

--------------------------------------------------
-- HELPERS
--------------------------------------------------

-- Food can be a single Part or a Model made of parts.
local function getFoodPart(food)

	if food:IsA("BasePart") then
		return food
	end

	return food:FindFirstChildWhichIsA(
		"BasePart",
		true
	)

end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

function FoodService:Init(inventoryService)

	self.InventoryService = inventoryService

end

--------------------------------------------------
-- START
--------------------------------------------------

function FoodService:Start()

	self:SpawnInitialFood()

end

--------------------------------------------------
-- SPAWN INITIAL FOOD
--------------------------------------------------

function FoodService:SpawnInitialFood()

	local spawnPoints = FoodSpawnsFolder:GetChildren()

	if #spawnPoints == 0 then
		warn("FoodService: No food spawn points found.")
		return
	end

	for _, spawnPoint in ipairs(spawnPoints) do

		if spawnPoint:IsA("BasePart") then
			self:SpawnFoodAt(spawnPoint)
		end

	end

end

--------------------------------------------------
-- SPAWN FOOD
--------------------------------------------------

function FoodService:SpawnFoodAt(spawnPoint)

	local foodTemplates = FoodModelsFolder:GetChildren()

	if #foodTemplates == 0 then
		warn("FoodService: No food models found in ServerStorage.FoodModels.")
		return
	end

	-- Pick one of the configured food models.
	local validTemplates = {}

	for _, template in ipairs(foodTemplates) do

		if template:IsA("Model") or template:IsA("BasePart") then

			local foodId = template:GetAttribute("FoodId")

			if foodId and FoodConfig[foodId] then
				table.insert(validTemplates, template)
			end

		end

	end

	if #validTemplates == 0 then
		warn("FoodService: No valid food models found.")
		return
	end

	local template = validTemplates[
	math.random(1, #validTemplates)
	]

	local food = template:Clone()

	food.Name = template.Name

	-- Move the model to the spawn point.
	food:PivotTo(
		spawnPoint.CFrame
			+ Vector3.new(0, 2, 0)
	)

	food.Parent = FoodFolder

	self:SetupPickup(food)

end

--------------------------------------------------
-- SETUP PICKUP
--------------------------------------------------

function FoodService:SetupPickup(food)

	local foodId = food:GetAttribute("FoodId")

	if not foodId then
		warn(
			"FoodService: Food has no FoodId:",
			food:GetFullName()
		)
		return
	end

	local foodData = FoodConfig[foodId]

	if not foodData then
		warn(
			"FoodService: No FoodConfig entry for:",
			foodId
		)
		return
	end

	-- Find the physical part of the food.
	local interactionPart = getFoodPart(food)

	if not interactionPart then
		warn(
			"FoodService: Food has no BasePart:",
			food:GetFullName()
		)
		return
	end

	local prompt = Instance.new("ProximityPrompt")

	prompt.Name = "PickupPrompt"

	prompt.ActionText = "Pick Up"

	prompt.ObjectText = foodId

	prompt.HoldDuration = 0

	prompt.MaxActivationDistance = PICKUP_DISTANCE

	prompt.RequiresLineOfSight = false

	prompt.Parent = interactionPart

	--------------------------------------------------
	-- PLAYER REQUESTS PICKUP
	--------------------------------------------------

	prompt.Triggered:Connect(function(player)

		self:CollectFood(
			player,
			food
		)

	end)

end

--------------------------------------------------
-- COLLECT FOOD
--------------------------------------------------

function FoodService:CollectFood(player, food)

	-- The food may already have been collected.
	if not food or not food.Parent then
		return
	end

	-- Make sure the food is still inside our active Food folder.
	if food.Parent ~= FoodFolder then
		return
	end

	local foodId = food:GetAttribute("FoodId")

	if not foodId then
		return
	end

	-- Make sure the food still exists in configuration.
	local foodData = FoodConfig[foodId]

	if not foodData then
		return
	end

	--------------------------------------------------
	-- SERVER-SIDE DISTANCE VALIDATION
	--------------------------------------------------

	local character = player.Character

	if not character then
		return
	end

	local rootPart = character:FindFirstChild(
		"HumanoidRootPart"
	)

	if not rootPart then
		return
	end

	local foodPart = getFoodPart(food)

	if not foodPart then
		return
	end

	local distance = (
		rootPart.Position - foodPart.Position
	).Magnitude

	if distance > PICKUP_DISTANCE + 3 then
		return
	end

	--------------------------------------------------
	-- ADD FOOD TO PLAYER INVENTORY
	--------------------------------------------------
	local foodValue = foodData.FoodValue

	local added = self.InventoryService:AddFood(
		player,
		foodValue
	)

	if not added then
		return
	end

	--------------------------------------------------
	-- REMOVE FOOD FROM WORLD
	--------------------------------------------------

	food:Destroy()

end

return FoodService