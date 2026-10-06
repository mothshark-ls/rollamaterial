--[[
	ServerBootstrap

	Starts the server services currently required
	by the Phase 1 prototype.

	This script should contain no gameplay logic.
]]

local ServerScriptService = game:GetService(
	"ServerScriptService"
)

local ServicesFolder =
	ServerScriptService:WaitForChild("Services")

local InventoryService =
	require(
		ServicesFolder:WaitForChild(
			"InventoryService"
		)
	)

local FoodService =
	require(
		ServicesFolder:WaitForChild(
			"FoodService"
		)
	)

--------------------------------------------------
-- INITIALIZE
--------------------------------------------------

InventoryService:Init()

FoodService:Init(
	InventoryService
)

--------------------------------------------------
-- START
--------------------------------------------------

InventoryService:Start()

FoodService:Start()