-- ============================================================
-- CONFIGURATION
-- ============================================================
local ENTITIES_FOLDER = workspace:WaitForChild("Entities")   -- all NPCs/players go here
local MAX_SIZE = Vector3.new(2048, 2048, 2048)               -- size of the targeted hurtbox
local UPDATE_INTERVAL = 0                                  -- how often to refresh (lower = more responsive)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

if not RunService:IsClient() then return end   -- LocalScript only

local localPlayer = Players.LocalPlayer
if not localPlayer then return end

local Camera = workspace.CurrentCamera
local originalSizes = {}   -- cache original sizes for every part

-- Returns the hurtbox part closest to the camera, and its distance.
-- Ignores the local player's own character.
local function getClosestHurtbox()
	local cameraPos = Camera.CFrame.Position
	local bestPart = nil
	local bestDist = math.huge

	-- Iterate over every entity in Entities folder
	for _, entity in ipairs(ENTITIES_FOLDER:GetChildren()) do
		-- Skip if it's the local player's character (so you don't target yourself)
		if entity == localPlayer.Character then
			continue
		end

		local hurtboxes = entity:FindFirstChild("Hurtboxes")
		if hurtboxes then
			-- Check every part inside Hurtboxes
			for _, part in ipairs(hurtboxes:GetChildren()) do
				if part:IsA("BasePart") then
					local dist = (part.Position - cameraPos).Magnitude
					if dist < bestDist then
						bestDist = dist
						bestPart = part
					end
				end
			end
		end
	end

	return bestPart, bestDist
end

-- Reset all hurtboxes to original size, then enlarge the closest one
local function updateSizes()
	local targetPart = getClosestHurtbox()

	-- Reset EVERY hurtbox to its stored original size
	for _, entity in ipairs(ENTITIES_FOLDER:GetChildren()) do
		local hurtboxes = entity:FindFirstChild("Hurtboxes")
		if hurtboxes then
			for _, part in ipairs(hurtboxes:GetChildren()) do
				if part:IsA("BasePart") then
					if not originalSizes[part] then
						originalSizes[part] = part.Size
					end
					part.Size = originalSizes[part]
				end
			end
		end
	end

	-- If we found a target, set it to MAX_SIZE
	if targetPart then
		targetPart.Size = MAX_SIZE
	end
end

-- React to new entities being added (they'll be processed on next loop)
ENTITIES_FOLDER.ChildAdded:Connect(function() end)

-- Main update loop
task.spawn(function()
	while true do
		task.wait(UPDATE_INTERVAL)
		updateSizes()
	end
end)
