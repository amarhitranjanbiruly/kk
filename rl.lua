local Entities = workspace:WaitForChild("Entities")  -- Your main folder
local TARGET_SIZE = Vector3.new(1000, 1000, 1000)     -- Set your custom size here

-- ============================================
-- 1. FUNCTION: Resize a single part safely
-- ============================================
local function resizePart(part)
	if part:IsA("BasePart") and part.Parent and part.Parent.Name == "Hurtboxes" then
		if part.Size ~= TARGET_SIZE then  -- Avoid unnecessary writes
			part.Size = TARGET_SIZE
			-- print("Resized:", part.Parent.Parent.Name, "->", part.Name) -- Debug
		end
	end
end

-- ============================================
-- 2. FUNCTION: Set up a watcher for ONE model
-- ============================================
local function setupHurtboxWatcher(model)
	if not model:IsA("Model") then return end
	
	-- --- A) Resize hurtboxes that already exist right now ---
	local hurtboxes = model:FindFirstChild("Hurtboxes")
	if hurtboxes then
		for _, part in ipairs(hurtboxes:GetChildren()) do
			resizePart(part)
		end
	end
	
	-- --- B) Watch for NEW hurtboxes added to this model later ---
	model.DescendantAdded:Connect(function(descendant)
		-- If a new part appears, check if it's inside a "Hurtboxes" folder
		if descendant:IsA("BasePart") then
			-- Climb up the parent chain to find the Hurtboxes folder
			local parent = descendant.Parent
			if parent and parent.Name == "Hurtboxes" then
				resizePart(descendant)
			end
		end
	end)
end

-- ============================================
-- 3. PROCESS: Existing entities
-- ============================================
for _, child in ipairs(Entities:GetChildren()) do
	setupHurtboxWatcher(child)
end

-- ============================================
-- 4. DETECT: New entities added later
-- ============================================
Entities.ChildAdded:Connect(setupHurtboxWatcher)

-- ============================================
-- 5. AUTO-REFRESH: Periodic safety check
--    (Runs every 5 seconds to enforce the size)
-- ============================================
task.spawn(function()
	while true do
		task.wait(5)  -- Check every 5 seconds (lower = more CPU, higher = slower reaction)
		
		-- Loop through ALL models in Entities
		for _, model in ipairs(Entities:GetChildren()) do
			if model:IsA("Model") then
				local hurtboxes = model:FindFirstChild("Hurtboxes")
				if hurtboxes then
					for _, part in ipairs(hurtboxes:GetChildren()) do
						if part:IsA("BasePart") and part.Size ~= TARGET_SIZE then
							part.Size = TARGET_SIZE
							-- print("Auto-refresh fixed:", model.Name, part.Name)
						end
					end
				end
			end
		end
	end
end)
