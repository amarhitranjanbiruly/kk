local suspectsFolder = workspace:WaitForChild("GAME"):WaitForChild("Suspects")

-- Helper to add a highlight to a model (if it has a Humanoid)
local function addOutline(model)
	if not model:FindFirstChild("Humanoid") then return end
	if model:FindFirstChild("Highlight") then return end
	
	local highlight = Instance.new("Highlight")
	highlight.Parent = model
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = Color3.new(1, 0, 0)  -- red
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

-- Scan all existing NPCs (any depth)
local function scanAll()
	for _, model in ipairs(suspectsFolder:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChild("Humanoid") then
			addOutline(model)
		end
	end
end

-- Watch for new models added anywhere under Suspects
local function watchDescendants()
	suspectsFolder.DescendantAdded:Connect(function(descendant)
		-- If the descendant is a Model with a Humanoid
		if descendant:IsA("Model") and descendant:FindFirstChild("Humanoid") then
			addOutline(descendant)
		end
		-- Also, if something gains a Humanoid later (e.g., a part becomes a rig)
		-- we can watch for Humanoid being added to any model
		if descendant:IsA("Humanoid") and descendant.Parent and descendant.Parent:IsA("Model") then
			addOutline(descendant.Parent)
		end
	end)
end

-- Initial scan
scanAll()
-- Start watching for future changes
watchDescendants()
