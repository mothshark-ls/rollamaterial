--[[
	FoodController

	Makes every food in Workspace.Food bob up and down and spin slowly.

	This only moves the food on this player's screen. The server still
	owns where each food is, when it spawns and who collects it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FoodController = {}

--------------------------------------------------
-- FOLDERS
--------------------------------------------------

local FoodFolder = workspace:WaitForChild("Food")

local FoodConfig = require(
	ReplicatedStorage
		:WaitForChild("Shared")
		:WaitForChild("Config")
		:WaitForChild("FoodConfig")
)

--------------------------------------------------
-- STATE
--------------------------------------------------

-- Food model -> { BaseCFrame, Phase }
local hoveringFood = {}

--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function startHovering(food)

	if not food:IsA("Model") then
		return
	end

	hoveringFood[food] = {
		BaseCFrame = food:GetPivot(),

		-- Random offset so foods don't all bob in sync.
		Phase = math.random() * math.pi * 2,
	}

end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

function FoodController:Init()

end

--------------------------------------------------
-- START
--------------------------------------------------

function FoodController:Start()

	for _, food in ipairs(FoodFolder:GetChildren()) do
		startHovering(food)
	end

	FoodFolder.ChildAdded:Connect(startHovering)

	FoodFolder.ChildRemoved:Connect(function(food)

		hoveringFood[food] = nil

	end)

	RunService.RenderStepped:Connect(function()

		local now = os.clock()
		local bobSpeed = math.pi * 2 / FoodConfig.BobPeriod
		local spinSpeed = math.rad(FoodConfig.SpinSpeed)

		for food, hover in pairs(hoveringFood) do

			local bob = math.sin(now * bobSpeed + hover.Phase) * FoodConfig.BobHeight
			local spin = now * spinSpeed + hover.Phase

			food:PivotTo(
				hover.BaseCFrame
					* CFrame.new(0, bob, 0)
					* CFrame.Angles(0, spin, 0)
			)

		end

	end)

end

return FoodController
