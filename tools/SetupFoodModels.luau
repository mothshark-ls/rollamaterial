--[[
	SetupFoodModels (one-time Studio tool, not game code)

	Paste into Studio's Command Bar (View > Command Bar) and press Enter.

	For every food in ServerStorage.FoodModels:
	1. Turns Parts that use a SpecialMesh into MeshParts.
	2. Wraps foods that are a single Part into a Model.
	3. Sets the Model's PrimaryPart to Root and anchors Root.
	4. Removes joints that point at nothing.
]]

local AssetService = game:GetService("AssetService")
local foodModels = game:GetService("ServerStorage"):WaitForChild("FoodModels")

local function setFoodPartProperties(part)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
end

local function convertToMeshPart(part, specialMesh)
	local ok, meshPart = pcall(function()
		return AssetService:CreateMeshPartAsync(specialMesh.MeshId)
	end)

	if not ok then
		warn("Could not convert " .. part:GetFullName() .. ": " .. tostring(meshPart))
		return part
	end

	meshPart.Name = part.Name
	meshPart.Size = meshPart.MeshSize * specialMesh.Scale
	meshPart.CFrame = part.CFrame * CFrame.new(specialMesh.Offset)
	meshPart.TextureID = specialMesh.TextureId
	meshPart.Color = part.Color
	meshPart.Material = part.Material
	meshPart.Transparency = part.Transparency
	setFoodPartProperties(meshPart)

	for name, value in part:GetAttributes() do
		meshPart:SetAttribute(name, value)
	end

	specialMesh:Destroy()

	for _, child in part:GetChildren() do
		child.Parent = meshPart
	end

	meshPart.Parent = part.Parent
	part:Destroy()

	print("Converted to MeshPart: " .. meshPart:GetFullName())
	return meshPart
end

for _, food in foodModels:GetChildren() do

	-- 1. Convert SpecialMesh parts.
	local specialMeshes = {}
	for _, descendant in food:GetDescendants() do
		if descendant:IsA("SpecialMesh") and descendant.MeshType == Enum.MeshType.FileMesh then
			table.insert(specialMeshes, descendant)
		end
	end

	for _, specialMesh in specialMeshes do
		local part = specialMesh.Parent
		if part:IsA("BasePart") then
			local newPart = convertToMeshPart(part, specialMesh)
			if part == food then
				food = newPart
			end
		end
	end

	-- 2. Wrap single-part foods into a Model.
	local model = food

	if not food:IsA("Model") then
		model = Instance.new("Model")
		model.Name = food.Name

		for name, value in food:GetAttributes() do
			model:SetAttribute(name, value)
			food:SetAttribute(name, nil)
		end

		local root = food:FindFirstChild("Root")
		if root then
			root.Parent = model
		end

		food.Parent = model
		model.Parent = foodModels
		print("Wrapped into Model: " .. model:GetFullName())
	end

	-- 3. Root becomes the anchored PrimaryPart.
	local root = model:FindFirstChild("Root")

	if root and root:IsA("BasePart") then
		setFoodPartProperties(root)
		model.PrimaryPart = root
	else
		warn("No Root part in " .. model:GetFullName())
	end

	-- 4. Remove joints that point at nothing.
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("JointInstance") and (descendant.Part0 == nil or descendant.Part1 == nil) then
			print("Removed broken joint: " .. descendant:GetFullName())
			descendant:Destroy()
		end
	end
end

print("SetupFoodModels finished.")
