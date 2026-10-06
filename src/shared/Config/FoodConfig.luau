--[[
	FoodConfig

	All food design numbers. Every value here is a placeholder until the
	food roster and balance are decided.
]]

local FoodConfig = {}

--------------------------------------------------
-- FOODS
--------------------------------------------------

-- Keyed by FoodId. Each model in ServerStorage.FoodModels has a matching
-- FoodId attribute.
FoodConfig.Foods = {

	Apple = {
		FoodValue = 1,
		Rarity = "Common",
	},

	Orange = {
		FoodValue = 1,
		Rarity = "Common",
	},

	Pear = {
		FoodValue = 2,
		Rarity = "Common",
	},

	BloxyCola = {
		FoodValue = 2,
		Rarity = "Uncommon",
	},

	Taco = {
		FoodValue = 3,
		Rarity = "Uncommon",
	},

	Cheeseburger = {
		FoodValue = 3,
		Rarity = "Uncommon",
	},

	Pizza = {
		FoodValue = 5,
		Rarity = "Rare",
	},

	Watermelon = {
		FoodValue = 5,
		Rarity = "Rare",
	},

}

--------------------------------------------------
-- SPAWNING
--------------------------------------------------

-- Spawn chance of each rarity. A rarity is rolled first, then a random
-- food of that rarity, so adding foods never changes rarity odds.
FoodConfig.RarityWeights = {
	Common = 70,
	Uncommon = 25,
	Rare = 5,
}

-- Settings for each zone, chosen by the zone part's ZoneType attribute.
-- MaxFood: food the zone is kept full at.
-- SpawnDelay: seconds between each spawn while the zone refills.
FoodConfig.ZoneTypes = {

	Short = {
		MaxFood = 5,
		SpawnDelay = 1,
	},

	Long = {
		MaxFood = 12,
		SpawnDelay = 0.5,
	},

}

--------------------------------------------------
-- PICKUP AND CARRYING
--------------------------------------------------

-- Distance in studs from the player's HumanoidRootPart to a food's Root.
FoodConfig.PickupRadius = 5

-- How much food a player can carry before upgrades.
FoodConfig.StartingCapacity = 15

return FoodConfig
