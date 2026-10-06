--[[
	GubbyService

	Owns the live Gubby and the run's shared Gubby state.

	1. Keeps one Model, Workspace.Gubby, for the whole game. Its contents
	   are swapped for the current stage's model from
	   ServerStorage.GubbyStages, so the ClickDetector and attributes are
	   never lost.
	2. Places Gubby on Workspace.Map.GubbySpawn: the bottom of his Root
	   rests on the spawn's top face, facing the spawn's front.
	3. Feeds Gubby when a player clicks him from within FeedRadius. Each
	   click takes FeedPerClick food from the player, adds it to the
	   shared total, refills the hunger timer and checks for a new stage.
	4. Tells every client which foods were fed so they can play the
	   feeding animation.
	5. When the hunger timer runs out, Gubby explodes. For now that
	   restarts the run.

	Attributes on Workspace.Gubby: GubbyFood, GubbyStage.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GubbyService = {}

-- Prints Gubby's food total, stage changes and explosions to Output
-- while there is no UI.
local DEBUG_PRINT_GUBBY = true

--------------------------------------------------
-- FOLDERS
--------------------------------------------------

local GubbyStagesFolder = ServerStorage:WaitForChild("GubbyStages")

local GubbySpawn = workspace
	:WaitForChild("Map")
	:WaitForChild("GubbySpawn")

local GubbyFedRemote = ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild("GubbyFed")

local GubbyConfig = require(
	ReplicatedStorage
		:WaitForChild("Shared")
		:WaitForChild("Config")
		:WaitForChild("GubbyConfig")
)

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

-- Extra studs allowed on the server's distance check, so a player who
-- moves slightly between clicking and the server receiving it is not
-- rejected.
local FEED_DISTANCE_TOLERANCE = 5

--------------------------------------------------
-- STATE
--------------------------------------------------

local gubbyModel = nil
local gubbyFood = 0
local currentStage = nil

--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function debugPrint(message)

	if DEBUG_PRINT_GUBBY then
		print("[Gubby] " .. message)
	end

end

-- Moves Gubby so the bottom of his Root sits on GubbySpawn's top face.
local function placeOnSpawn()

	local root = gubbyModel.PrimaryPart

	local spawnTop = GubbySpawn.CFrame * CFrame.new(0, GubbySpawn.Size.Y / 2, 0)
	local rootTarget = spawnTop * CFrame.new(0, root.Size.Y / 2, 0)

	-- Keep the model's pivot in the same place relative to its Root.
	local pivotOffset = root.CFrame:ToObjectSpace(gubbyModel:GetPivot())

	gubbyModel:PivotTo(rootTarget * pivotOffset)

end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

function GubbyService:Init(inventoryService, growthService, hungerService)

	self.InventoryService = inventoryService
	self.GrowthService = growthService
	self.HungerService = hungerService

end

--------------------------------------------------
-- START
--------------------------------------------------

function GubbyService:Start()

	gubbyModel = Instance.new("Model")
	gubbyModel.Name = "Gubby"

	-- Keep Gubby loaded for every player no matter where they are.
	gubbyModel.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = GubbyConfig.FeedRadius
	clickDetector.Parent = gubbyModel

	clickDetector.MouseClick:Connect(function(player)

		self:Feed(player)

	end)

	self:SetStage(GubbyConfig.Stages[1])
	gubbyModel:SetAttribute("GubbyFood", gubbyFood)

	gubbyModel.Parent = workspace

	self.HungerService.TimeUp.Event:Connect(function()

		self:Explode()

	end)

end

--------------------------------------------------
-- SET STAGE
--------------------------------------------------

-- Replaces Gubby's contents with the given stage's model.
function GubbyService:SetStage(stage)

	local template = GubbyStagesFolder:FindFirstChild(stage.Id)

	if not template or not template:IsA("Model") or not template.PrimaryPart then
		warn("GubbyService: ServerStorage.GubbyStages needs a Model named", stage.Id, "with a PrimaryPart.")
		return
	end

	for _, child in ipairs(gubbyModel:GetChildren()) do
		if not child:IsA("ClickDetector") then
			child:Destroy()
		end
	end

	local stageModel = template:Clone()
	local rootName = template.PrimaryPart.Name

	for _, child in ipairs(stageModel:GetChildren()) do
		child.Parent = gubbyModel
	end

	stageModel:Destroy()

	gubbyModel.PrimaryPart = gubbyModel:FindFirstChild(rootName)

	placeOnSpawn()

	currentStage = stage
	gubbyModel:SetAttribute("GubbyStage", stage.Id)

	debugPrint("Stage: " .. stage.Id)

end

--------------------------------------------------
-- FEED
--------------------------------------------------

function GubbyService:Feed(player)

	if not gubbyModel or not gubbyModel.PrimaryPart then
		return
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	if not rootPart then
		return
	end

	local distance = (rootPart.Position - gubbyModel.PrimaryPart.Position).Magnitude

	if distance > GubbyConfig.FeedRadius + FEED_DISTANCE_TOLERANCE then
		return
	end

	local foodIds = self.InventoryService:TakeFood(
		player,
		GubbyConfig.FeedPerClick
	)

	if #foodIds == 0 then
		return
	end

	gubbyFood += #foodIds
	gubbyModel:SetAttribute("GubbyFood", gubbyFood)

	self.HungerService:AddFood(#foodIds)

	GubbyFedRemote:FireAllClients(player, foodIds)

	debugPrint("Food: " .. gubbyFood)

	local newStage = self.GrowthService:GetStageForFood(gubbyFood)

	if newStage ~= currentStage then
		self:SetStage(newStage)
	end

end

--------------------------------------------------
-- EXPLODE
--------------------------------------------------

-- The hunger timer ran out. For now this restarts the run: Gubby goes
-- back to the first stage with no food, everyone's carried food is
-- cleared, the timer is refilled and every player respawns.
function GubbyService:Explode()

	debugPrint("Exploded! Restarting the run.")

	gubbyFood = 0
	gubbyModel:SetAttribute("GubbyFood", gubbyFood)

	self:SetStage(GubbyConfig.Stages[1])

	self.InventoryService:ClearAll()
	self.HungerService:Reset()

	for _, player in ipairs(Players:GetPlayers()) do
		player:LoadCharacter()
	end

end

return GubbyService
