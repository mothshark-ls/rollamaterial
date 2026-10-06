local GubbyConfig = {

	--------------------------------------------------
	-- STAGES
	--------------------------------------------------

	-- Ordered from smallest to largest. Id matches a Model in
	-- ServerStorage.GubbyStages. RequiredFood is the shared food total
	-- needed to reach the stage.
	Stages = {

		{
			Id = "Tiny",
			RequiredFood = 0,
		},

		{
			Id = "Small",
			RequiredFood = 10,
		},

	},

	--------------------------------------------------
	-- HUNGER
	--------------------------------------------------

	-- Seconds on the hunger timer when a run starts.
	HungerStartTime = 30,

	-- Seconds added to the hunger timer per food unit fed.
	SecondsPerFood = 1,

	--------------------------------------------------
	-- FEEDING
	--------------------------------------------------

	-- Click range: distance in studs from the player's HumanoidRootPart
	-- to Gubby's Root that allows clicking to feed. Also controls when
	-- the hover outline shows.
	FeedRadius = 40,

	-- Food units fed per click.
	FeedPerClick = 1,

	--------------------------------------------------
	-- FEED ANIMATION (client)
	--------------------------------------------------

	-- Studs in front of the player, towards Gubby, where food appears.
	FeedStartDistance = 2,

	-- Seconds for a food to float from the player to Gubby's mouth.
	FeedFlightTime = 0.4,

	-- Seconds between each queued food starting its flight.
	FeedAnimationInterval = 0.12,

}

return GubbyConfig