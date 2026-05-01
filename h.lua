-- ========== NPCs in workspace.GAME.Suspects ==========
local suspectsFolder = workspace:WaitForChild("GAME"):WaitForChild("Suspects")

local function addOutlineToNPC(model)
	if not model:FindFirstChild("Humanoid") then return end
	if model:FindFirstChild("Highlight") then return end
	
	-- Determine color based on first letter of model name
	local name = model.Name
	if #name == 0 then return end
	local firstChar = string.sub(name, 1, 1):lower()  -- case-insensitive
	
	local outlineColor
	if firstChar == "c" then
		outlineColor = Color3.new(0, 1, 0)   -- Green
	elseif firstChar == "s" then
		outlineColor = Color3.new(1, 0, 0)   -- Red
	else
		-- Optional: skip NPCs that don't start with c or s
		return
		-- Or use a default color: outlineColor = Color3.new(1, 1, 0) -- yellow
	end
	
	local highlight = Instance.new("Highlight")
	highlight.Parent = model
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = outlineColor
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function scanNPCs()
	for _, model in ipairs(suspectsFolder:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChild("Humanoid") then
			addOutlineToNPC(model)
		end
	end
end

local function watchNPCs()
	suspectsFolder.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Model") and descendant:FindFirstChild("Humanoid") then
			addOutlineToNPC(descendant)
		end
		if descendant:IsA("Humanoid") and descendant.Parent and descendant.Parent:IsA("Model") then
			addOutlineToNPC(descendant.Parent)
		end
	end)
end

-- ========== (Optional) Traps in workspace.Traps ==========
local trapsFolder = workspace:FindFirstChild("Traps")
if trapsFolder then
	local function addOutlineToTrap(obj)
		if obj:FindFirstChild("Highlight") then return end
		if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
		-- Skip parts inside a Model (avoid double outline)
		if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") then return end
		
		local highlight = Instance.new("Highlight")
		highlight.Parent = obj
		highlight.FillTransparency = 1
		highlight.OutlineTransparency = 0
		highlight.OutlineColor = Color3.new(1, 1, 0)  -- Yellow
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	end
	
	local function scanTraps()
		for _, obj in ipairs(trapsFolder:GetDescendants()) do
			addOutlineToTrap(obj)
		end
	end
	
	local function watchTraps()
		trapsFolder.DescendantAdded:Connect(addOutlineToTrap)
	end
	
	scanTraps()
	watchTraps()
else
	warn("workspace.Traps not found – skipping trap outlines")
end

-- ========== RUN NPC OUTLINING ==========
scanNPCs()
watchNPCs()
