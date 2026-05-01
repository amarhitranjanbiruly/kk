local function isPlayer(model)
	-- Returns true if the model is a player character
	return game.Players:GetPlayerFromCharacter(model) ~= nil
end

local function addOutline(model)
	-- Must have a Humanoid, must NOT be a player, and no existing Highlight
	if not model:FindFirstChild("Humanoid") then return end
	if isPlayer(model) then return end
	if model:FindFirstChild("Highlight") then return end
	
	local name = model.Name
	local firstChar = string.sub(name, 1, 1):lower()
	
	local outlineColor
	if firstChar == "g" then
		outlineColor = Color3.new(1, 0, 0)   -- Red
	else
		outlineColor = Color3.new(0, 1, 0)   -- Green (default)
	end
	
	local highlight = Instance.new("Highlight")
	highlight.Parent = model
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = outlineColor
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

-- Scan all existing models in workspace (any depth)
local function scanAll()
	for _, model in ipairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChild("Humanoid") then
			addOutline(model)
		end
	end
end

-- Watch for new models added anywhere in workspace
local function watchDescendants()
	workspace.DescendantAdded:Connect(function(descendant)
		-- Case: new Model with Humanoid appears
		if descendant:IsA("Model") and descendant:FindFirstChild("Humanoid") then
			addOutline(descendant)
		end
		-- Case: a Humanoid is added to an existing Model
		if descendant:IsA("Humanoid") and descendant.Parent and descendant.Parent:IsA("Model") then
			addOutline(descendant.Parent)
		end
	end)
end

scanAll()
watchDescendants()
