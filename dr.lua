-- Auto‑refreshing ESP Outline for Track, Checkpoints, Lobby[140] and Environment
-- Run this script ONCE (e.g., in a ServerScript or LocalScript inside StarterPlayerScripts)

local ROOT_INSTANCES = {
	workspace.Lobby:GetChildren()[140],   -- be careful: index 140 must exist
	workspace.Track,
	workspace.Track.Checkpoint0,
	workspace.Track.Checkpoint1,
	workspace.Track.Checkpoint2,
	workspace.Track.Checkpoint3,
	workspace.Track.Checkpoint4,
	workspace.Track.Checkpoint5,
	workspace.Track.Checkpoint6,
	workspace.Track.Checkpoint7,
	workspace.Track.Checkpoint8,
	workspace.Track.Checkpoint9,
	workspace.Track.Checkpoint10,
	workspace.Track.Checkpoint11,
	workspace.Track.Checkpoint12,
	workspace.Track.Checkpoint13,
	workspace.Track.Checkpoint14,
	workspace.Track.Checkpoint15,
	workspace.Track.Checkpoint16,
	workspace.Track.Checkpoint17,
	workspace.Track.Checkpoint18,
	workspace.Track.Checkpoint19,
	workspace.Track.Checkpoint20,
	workspace.Track.Checkpoint21,
	workspace.Track.Checkpoint22,
	workspace.Track.Checkpoint23,
	workspace.Track.Checkpoint24,
	workspace.Track.Checkpoint25,
	workspace.Track.Checkpoint26,
	workspace.Track.Checkpoint27,
	workspace.Track.Checkpoint28,
	workspace.Track.Checkpoint29,
	workspace.Track.Checkpoint30,
	workspace.Track.Checkpoint31,
	workspace.Track.Checkpoint32,
	workspace.Track.Environment,
}

local OUTLINE_COLOR = Color3.fromRGB(255, 50, 50)   -- bright red

-- Helper: adds a Highlight to an instance if it doesn't already have one
local function addHighlight(instance)
	if instance:IsA("BasePart") or instance:IsA("Model") then
		if not instance:FindFirstChildWhichIsA("Highlight") then
			local hl = Instance.new("Highlight")
			hl.FillTransparency = 1
			hl.OutlineTransparency = 0
			hl.OutlineColor = OUTLINE_COLOR
			hl.Parent = instance
		end
	end
end

-- Recursively outline all existing parts/models inside a given root
local function outlineAllDescendants(root)
	if not root then return end
	addHighlight(root)   -- outline the root itself if it's a part/model
	for _, child in ipairs(root:GetDescendants()) do
		addHighlight(child)
	end
end

-- Watch for new objects appearing anywhere under a root and outline them
local function watchForNewObjects(root)
	if not root then return end
	root.DescendantAdded:Connect(function(descendant)
		addHighlight(descendant)
	end)
end

-- Apply to all root instances
for _, root in ipairs(ROOT_INSTANCES) do
	if root then
		outlineAllDescendants(root)   -- initial outline
		watchForNewObjects(root)      -- auto‑refresh on new parts/models
	end
end

print("Auto‑refreshing ESP outlines enabled for all tracked containers.")
