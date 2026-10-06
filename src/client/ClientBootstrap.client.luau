--[[
	ClientBootstrap

	Starts the client controllers.

	Controllers only handle presentation (animations, effects, sounds).
	All gameplay decisions are made by the server.

	This script should contain no gameplay logic.
]]

local Players = game:GetService("Players")

local ControllersFolder =
	Players.LocalPlayer
		:WaitForChild("PlayerScripts")
		:WaitForChild("Controllers")

local FoodController =
	require(
		ControllersFolder:WaitForChild(
			"FoodController"
		)
	)

local GubbyController =
	require(
		ControllersFolder:WaitForChild(
			"GubbyController"
		)
	)

--------------------------------------------------
-- INITIALIZE
--------------------------------------------------

FoodController:Init()

GubbyController:Init()

--------------------------------------------------
-- START
--------------------------------------------------

FoodController:Start()

GubbyController:Start()
