--[[
	FoodService

	1. Keeps every food zone full. Missing food is spawned back one at a
	   time, with the zone's SpawnDelay between each spawn.
	2. Picks which food spawns by rarity weight.
	3. Collects food when a player is close enough and has room. Food a
	   full player walks over stays on the ground.

	Zones are Parts in Workspace.Map.FoodZones. Food spawns HoverHeight
	studs above a random point of the zone's top face. The zone's ZoneType
	attribute picks its settings from FoodConfig.ZoneTypes.

	Food templates are Models in ReplicatedStorage.FoodModels with a Root
	PrimaryPart and a FoodId attribute. They live in ReplicatedStorage so
	clients can clone them for the feeding animation. All food data comes
	from FoodConfig.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FoodService = {}

--------------------------------------------------
-- FOLDERS
--------------------------------------------------

local FoodFolder = workspace:WaitForChild("Food")

local FoodZonesFolder = workspace
	:WaitForChild("Map")
	:WaitForChild("FoodZones")

local FoodModelsFolder = ReplicatedStorage:WaitForChild("FoodModels")

local FoodConfig = require(
	ReplicatedStorage
		:WaitForChild("Shared")
		:WaitForChild("Config")
		:WaitForChild("FoodConfig")
)

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

-- How often the server checks players against food, in seconds.
local PICKUP_CHECK_INTERVAL = 0.1

--------------------------------------------------
-- STATE
--------------------------------------------------

-- Rarity -> list of food templates with that rarity.
local templatesByRarity = {}

-- List of { Part, Settings, FoodCount, Refilling }.
local zones = {}

-- Spawned food model -> the zone it belongs to.
local activeFood = {}

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

	self:LoadTemplates()
	self:LoadZones()

	for _, zone in ipairs(zones) do
		self:RefillZone(zone)
	end

	task.spawn(function()

		while true do
			task.wait(PICKUP_CHECK_INTERVAL)
			self:CheckPickups()
		end

	end)

end

--------------------------------------------------
-- LOAD TEMPLATES
--------------------------------------------------

function FoodService:LoadTemplates()

	for _, template in ipairs(FoodModelsFolder:GetChildren()) do

		local foodId = template:GetAttribute("FoodId")
		local foodData = foodId and FoodConfig.Foods[foodId]

		if not template:IsA("Model") or not template.PrimaryPart then
			warn("FoodService: Food model needs to be a Model with a PrimaryPart:", template:GetFullName())
		elseif not foodData then
			warn("FoodService: No FoodConfig entry for food model:", template:GetFullName())
		elseif not FoodConfig.RarityWeights[foodData.Rarity] then
			warn("FoodService: No rarity weight for", foodData.Rarity, "used by", foodId)
		else
			templatesByRarity[foodData.Rarity] = templatesByRarity[foodData.Rarity] or {}
			table.insert(templatesByRarity[foodData.Rarity], template)
		end

	end

end

--------------------------------------------------
-- LOAD ZONES
--------------------------------------------------

function FoodService:LoadZones()

	for _, zonePart in ipairs(FoodZonesFolder:GetChildren()) do

		if zonePart:IsA("BasePart") then

			local zoneType = zonePart:GetAttribute("ZoneType")
			local settings = zoneType and FoodConfig.ZoneTypes[zoneType]

			if settings then
				table.insert(zones, {
					Part = zonePart,
					Settings = settings,
					FoodCount = 0,
					Refilling = false,
				})
			else
				warn("FoodService: Unknown ZoneType on", zonePart:GetFullName(), zoneType)
			end

		end

	end

	if #zones == 0 then
		warn("FoodService: No food zones found.")
	end

end

--------------------------------------------------
-- PICK TEMPLATE
--------------------------------------------------

-- Rolls a rarity by weight, then picks a random food of that rarity.
-- Rarities with no food models are skipped.
local function pickTemplate()

	local totalWeight = 0

	for rarity, templates in pairs(templatesByRarity) do
		if #templates > 0 then
			totalWeight += FoodConfig.RarityWeights[rarity]
		end
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = math.random() * totalWeight

	for rarity, templates in pairs(templatesByRarity) do

		if #templates > 0 then

			roll -= FoodConfig.RarityWeights[rarity]

			if roll <= 0 then
				return templates[math.random(1, #templates)]
			end

		end

	end

	return nil

end

--------------------------------------------------
-- SPAWN FOOD
--------------------------------------------------

-- Spawns one food above a random point of the zone's top face.
-- Returns false if nothing could be spawned.
function FoodService:SpawnFood(zone)

	local template = pickTemplate()

	if not template then
		warn("FoodService: No valid food models to spawn.")
		return false
	end

	local zonePart = zone.Part
	local zoneSize = zonePart.Size

	local surfacePoint = zonePart.CFrame:PointToWorldSpace(Vector3.new(
		(math.random() - 0.5) * zoneSize.X,
		zoneSize.Y / 2,
		(math.random() - 0.5) * zoneSize.Z
	))

	local food = template:Clone()

	-- Stream the whole model to clients at once so it never shows up
	-- half-loaded.
	food.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	food:PivotTo(CFrame.new(surfacePoint + Vector3.new(0, FoodConfig.HoverHeight, 0)))

	food.Parent = FoodFolder

	activeFood[food] = zone
	zone.FoodCount += 1

	return true

end

--------------------------------------------------
-- REFILL ZONE
--------------------------------------------------

-- Spawns food one at a time until the zone is full. Safe to call
-- while the zone is already refilling.
function FoodService:RefillZone(zone)

	if zone.Refilling then
		return
	end

	zone.Refilling = true

	task.spawn(function()

		while zone.FoodCount < zone.Settings.MaxFood do

			task.wait(zone.Settings.SpawnDelay)

			if not self:SpawnFood(zone) then
				break
			end

		end

		zone.Refilling = false

	end)

end

--------------------------------------------------
-- CHECK PICKUPS
--------------------------------------------------

function FoodService:CheckPickups()

	for _, player in ipairs(Players:GetPlayers()) do

		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")

		if rootPart then

			for food in pairs(activeFood) do

				local foodRoot = food.PrimaryPart

				if foodRoot and (foodRoot.Position - rootPart.Position).Magnitude <= FoodConfig.PickupRadius then
					self:CollectFood(player, food)
				end

			end

		end

	end

end

--------------------------------------------------
-- COLLECT FOOD
--------------------------------------------------

function FoodService:CollectFood(player, food)

	local zone = activeFood[food]

	if not zone then
		return
	end

	local foodId = food:GetAttribute("FoodId")
	local foodData = FoodConfig.Foods[foodId]

	if not foodData then
		return
	end

	local added = self.InventoryService:AddFood(
		player,
		foodId,
		foodData.FoodValue
	)

	-- Player is full: the food stays for someone else.
	if not added then
		return
	end

	activeFood[food] = nil
	zone.FoodCount -= 1

	food:Destroy()

	self:RefillZone(zone)

end

return FoodService
