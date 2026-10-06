--[[
	GrowthService

	Converts a Gubby food total into a growth stage. Stage thresholds
	live in GubbyConfig.Stages, ordered from smallest to largest.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GubbyConfig = require(
	ReplicatedStorage
		:WaitForChild("Shared")
		:WaitForChild("Config")
		:WaitForChild("GubbyConfig")
)

local GrowthService = {}

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

function GrowthService:Init()

end

--------------------------------------------------
-- START
--------------------------------------------------

function GrowthService:Start()

end

--------------------------------------------------
-- GET STAGE FOR FOOD
--------------------------------------------------

-- Returns the highest stage whose RequiredFood has been reached.
function GrowthService:GetStageForFood(food)

	local currentStage = GubbyConfig.Stages[1]

	for _, stage in ipairs(GubbyConfig.Stages) do

		if food >= stage.RequiredFood then
			currentStage = stage
		end

	end

	return currentStage

end

return GrowthService
