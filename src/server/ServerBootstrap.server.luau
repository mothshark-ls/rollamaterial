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

local GrowthService =
	require(
		ServicesFolder:WaitForChild(
			"GrowthService"
		)
	)

local HungerService =
	require(
		ServicesFolder:WaitForChild(
			"HungerService"
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

GrowthService:Init()

HungerService:Init()

GubbyService:Init(
	InventoryService,
	GrowthService,
	HungerService
)

--------------------------------------------------
-- START
--------------------------------------------------

InventoryService:Start()

FoodService:Start()

GrowthService:Start()

-- Gubby must exist before the hunger timer writes its attribute to him.
GubbyService:Start()

HungerService:Start()
