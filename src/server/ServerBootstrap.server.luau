--[[
	ServerBootstrap

	Starts the server services.

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

local GubbyService =
	require(
		ServicesFolder:WaitForChild(
			"GubbyService"
		)
	)

--------------------------------------------------
-- INITIALIZE
--------------------------------------------------

InventoryService:Init()

FoodService:Init(
	InventoryService
)

GubbyService:Init(
	InventoryService
)

--------------------------------------------------
-- START
--------------------------------------------------

InventoryService:Start()

FoodService:Start()

GubbyService:Start()
