--[[
	GubbyService

	Owns the live Gubby and the server's shared Gubby food total.

	1. Places the first stage's model from ServerStorage.GubbyStages into
	   the Workspace, at the position it was saved at.
	2. Feeds Gubby when a player clicks him from within FeedRadius. Each
	   click takes FeedPerClick food from the player and adds it to the
	   shared total.
	3. Tells every client which foods were fed so they can play the
	   feeding animation.

	The shared total is stored as the GubbyFood attribute on the live
	Gubby model so every client can read it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GubbyService = {}

--------------------------------------------------
-- FOLDERS
--------------------------------------------------

local GubbyStagesFolder = ServerStorage:WaitForChild("GubbyStages")

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

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

function GubbyService:Init(inventoryService)

	self.InventoryService = inventoryService

end

--------------------------------------------------
-- START
--------------------------------------------------

function GubbyService:Start()

	self:SpawnGubby()

end

--------------------------------------------------
-- SPAWN GUBBY
--------------------------------------------------

function GubbyService:SpawnGubby()

	local stageId = GubbyConfig.Stages[1].Id
	local template = GubbyStagesFolder:FindFirstChild(stageId)

	if not template or not template:IsA("Model") or not template.PrimaryPart then
		warn("GubbyService: ServerStorage.GubbyStages needs a Model named", stageId, "with a PrimaryPart.")
		return
	end

	gubbyModel = template:Clone()
	gubbyModel.Name = "Gubby"

	-- Keep Gubby loaded for every player no matter where they are.
	gubbyModel.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	gubbyModel:SetAttribute("GubbyFood", gubbyFood)

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = GubbyConfig.FeedRadius
	clickDetector.Parent = gubbyModel

	clickDetector.MouseClick:Connect(function(player)

		self:Feed(player)

	end)

	gubbyModel.Parent = workspace

end

--------------------------------------------------
-- FEED
--------------------------------------------------

function GubbyService:Feed(player)

	if not gubbyModel then
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

	GubbyFedRemote:FireAllClients(player, foodIds)

end

return GubbyService
