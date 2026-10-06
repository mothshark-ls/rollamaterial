--[[
	GubbyController

	Presentation for Gubby on this player's screen:

	1. Outline: shows an outline around Gubby's Handle while the mouse is
	   over him and the player is close enough to feed.
	2. Feeding animation: every food fed by any player floats from in
	   front of that player to Gubby's Mouth. Foods are queued and start
	   FeedAnimationInterval apart so they never overlap.
	3. Eating sounds: when a food reaches the mouth, Eat plays, then
	   Chew, then Burp. Food arriving before Burp restarts Eat and Chew.
	   Sounds come from ReplicatedStorage.GubbySounds (Eat, Chew, Burp);
	   any that are missing are skipped.

	When Gubby changes stage his parts are replaced, so the outline and
	sounds are re-attached to the new parts.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GubbyController = {}

--------------------------------------------------
-- FOLDERS
--------------------------------------------------

local FoodModelsFolder = ReplicatedStorage:WaitForChild("FoodModels")

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

local OUTLINE_COLOR = Color3.new(1, 1, 1)

-- How long to wait for ReplicatedStorage.GubbySounds before playing
-- without sounds.
local SOUNDS_WAIT_TIME = 5

--------------------------------------------------
-- STATE
--------------------------------------------------

local gubbyModel = nil
local highlight = nil
local soundsFolder = nil

-- FoodId -> food model template.
local foodTemplates = {}

-- Queued { Player, FoodId } waiting to fly to Gubby.
local feedQueue = {}
local processingQueue = false

-- Eat, Chew and Burp sounds placed on Gubby.
local sounds = {}

-- Increases every time food arrives, so an older sound chain knows it
-- was interrupted.
local eatingSequence = 0

--------------------------------------------------
-- HELPERS
--------------------------------------------------

-- Mouth can be an Attachment (or Bone) or a Part named "Mouth".
local function getMouthPosition()

	local mouth = gubbyModel:FindFirstChild("Mouth", true)

	if mouth and mouth:IsA("Attachment") then
		return mouth.WorldPosition
	elseif mouth and mouth:IsA("BasePart") then
		return mouth.Position
	end

	return gubbyModel:GetPivot().Position

end

-- Restarts a sound, then runs nextStep when it finishes, unless more
-- food arrived in the meantime. Missing sounds are skipped.
local function playThen(sound, sequence, nextStep)

	if not sound then
		nextStep()
		return
	end

	sound.TimePosition = 0
	sound:Play()

	sound.Ended:Once(function()

		if sequence == eatingSequence then
			nextStep()
		end

	end)

end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

function GubbyController:Init()

end

--------------------------------------------------
-- START
--------------------------------------------------

function GubbyController:Start()

	for _, template in ipairs(FoodModelsFolder:GetChildren()) do

		local foodId = template:GetAttribute("FoodId")

		if foodId then
			foodTemplates[foodId] = template
		end

	end

	gubbyModel = workspace:WaitForChild("Gubby")

	self:SetupOutline()

	gubbyModel:GetAttributeChangedSignal("GubbyStage"):Connect(function()

		self:AttachToStage()

	end)

	GubbyFedRemote.OnClientEvent:Connect(function(player, foodIds)

		for _, foodId in ipairs(foodIds) do
			table.insert(feedQueue, {
				Player = player,
				FoodId = foodId,
			})
		end

		self:ProcessFeedQueue()

	end)

	soundsFolder = ReplicatedStorage:WaitForChild("GubbySounds", SOUNDS_WAIT_TIME)

	self:AttachToStage()

end

--------------------------------------------------
-- ATTACH TO STAGE
--------------------------------------------------

-- Points the outline and sounds at the current stage's parts.
function GubbyController:AttachToStage()

	highlight.Adornee = gubbyModel:FindFirstChild("Handle") or gubbyModel

	self:AttachSounds()

end

--------------------------------------------------
-- OUTLINE
--------------------------------------------------

function GubbyController:SetupOutline()

	highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1
	highlight.OutlineColor = OUTLINE_COLOR
	highlight.Enabled = false
	highlight.Parent = gubbyModel

	-- The server's ClickDetector only reports hovering within FeedRadius,
	-- so the outline also tells the player they are close enough to feed.
	local clickDetector = gubbyModel:WaitForChild("ClickDetector")

	clickDetector.MouseHoverEnter:Connect(function()

		highlight.Enabled = true

	end)

	clickDetector.MouseHoverLeave:Connect(function()

		highlight.Enabled = false

	end)

end

--------------------------------------------------
-- SOUNDS
--------------------------------------------------

function GubbyController:AttachSounds()

	for soundName, sound in pairs(sounds) do
		sound:Destroy()
		sounds[soundName] = nil
	end

	local soundParent = gubbyModel.PrimaryPart

	if not soundsFolder or not soundParent then
		return
	end

	for _, soundName in ipairs({ "Eat", "Chew", "Burp" }) do

		local sound = soundsFolder:FindFirstChild(soundName)

		if sound and sound:IsA("Sound") then
			-- Parent to Gubby so the sound comes from his position.
			local gubbySound = sound:Clone()
			gubbySound.Parent = soundParent
			sounds[soundName] = gubbySound
		end

	end

end

function GubbyController:PlayEatingSounds()

	eatingSequence += 1
	local sequence = eatingSequence

	if sounds.Chew then
		sounds.Chew:Stop()
	end

	if sounds.Burp then
		sounds.Burp:Stop()
	end

	playThen(sounds.Eat, sequence, function()

		playThen(sounds.Chew, sequence, function()

			if sounds.Burp then
				sounds.Burp.TimePosition = 0
				sounds.Burp:Play()
			end

		end)

	end)

end

--------------------------------------------------
-- FEED ANIMATION
--------------------------------------------------

function GubbyController:ProcessFeedQueue()

	if processingQueue then
		return
	end

	processingQueue = true

	task.spawn(function()

		while #feedQueue > 0 do

			local feed = table.remove(feedQueue, 1)

			self:PlayFeedFlight(feed.Player, feed.FoodId)

			task.wait(GubbyConfig.FeedAnimationInterval)

		end

		processingQueue = false

	end)

end

-- Floats one food from in front of the player to Gubby's mouth.
function GubbyController:PlayFeedFlight(player, foodId)

	local template = foodTemplates[foodId]
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	if not template or not rootPart then
		return
	end

	local towardsGubby = getMouthPosition() - rootPart.Position
	local startPosition = rootPart.Position

	if towardsGubby.Magnitude > 0 then
		startPosition += towardsGubby.Unit * GubbyConfig.FeedStartDistance
	end

	local food = template:Clone()
	food:PivotTo(CFrame.new(startPosition))
	food.Parent = workspace

	task.spawn(function()

		local elapsed = 0

		while elapsed < GubbyConfig.FeedFlightTime do

			elapsed += RunService.RenderStepped:Wait()

			local alpha = math.min(elapsed / GubbyConfig.FeedFlightTime, 1)

			-- Read the mouth every frame so it follows Gubby's animations.
			food:PivotTo(CFrame.new(startPosition:Lerp(getMouthPosition(), alpha)))

		end

		food:Destroy()

		self:PlayEatingSounds()

	end)

end

return GubbyController
