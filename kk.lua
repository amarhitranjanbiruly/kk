local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local maxDistance = 100
local updateInterval = 50 -- 50ms = smooth + good performance
local maxRAMLimitMB = 5000 -- 5GB RAM limit (for safety)

local espLoops = {}

--// Function to monitor RAM and pause ESP if usage too high
local function getMemoryUsageMB()
	return collectgarbage("count") / 1024
end

local function checkRAMLimit()
	if getMemoryUsageMB() > maxRAMLimitMB then
		warn("[ESP] Memory usage too high, pausing ESP updates!")
		task.wait(1)
		return true
	end
	return false
end

--// Hybrid visibility check (angle + ray for long range)
local function isVisible(targetPart, targetCharacter)
	if not targetPart then return false end
	local origin = Camera.CFrame.Position
	local direction = (targetPart.Position - origin)
	local distance = direction.Magnitude

	-- Short-range check: use angle instead of raycast
	if distance < 40 then
		local viewDir = Camera.CFrame.LookVector
		local dot = viewDir:Dot(direction.Unit)
		return dot > 0.2 -- visible if roughly in front
	end

	-- Long-range: use raycast
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local result = Workspace:Raycast(origin, direction.Unit * distance, raycastParams)
	if not result then return true end
	return result.Instance and result.Instance:IsDescendantOf(targetCharacter)
end

--// ESP creator
local function createESP(player)
	if espLoops[player] then
		espLoops[player].active = false
	end

	local box = Drawing.new("Square")
	local line = Drawing.new("Line")
	local healthBar = Drawing.new("Line")
	local nameText = Drawing.new("Text")
	local distText = Drawing.new("Text")

	box.Thickness = 2
	box.Filled = false
	box.Transparency = 1

	healthBar.Thickness = 2
	healthBar.Color = Color3.fromRGB(0, 255, 0)
	healthBar.Transparency = 1

	line.Thickness = 1
	line.Transparency = 1

	nameText.Size = 13
	nameText.Center = true
	nameText.Outline = true
	nameText.Transparency = 1

	distText.Size = 13
	distText.Center = true
	distText.Outline = true
	distText.Transparency = 1
	distText.Color = Color3.fromRGB(0, 255, 0)

	local loopData = { active = true }
	espLoops[player] = loopData

	task.spawn(function()
		while loopData.active and player and player.Parent do
			if checkRAMLimit() then continue end

			local char = player.Character
			local head = char and char:FindFirstChild("Head")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")

			if head and hrp and humanoid and humanoid.Health > 0 then
				local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
				if distance <= maxDistance then
					local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
					if onScreen then
						local feetPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
						local height = math.abs(headPos.Y - feetPos.Y)
						local width = height / 2
						width = math.clamp(width, 10, 250)
						height = math.clamp(height, 20, 500)

						local screenSize = Camera.ViewportSize
						local topCenter = Vector2.new(screenSize.X / 2, 0)

						local enemy = player.Team ~= LocalPlayer.Team
						local visible = isVisible(head, char)
						local lineColor = visible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

						line.Visible = enemy
						line.From = topCenter
						line.To = Vector2.new(headPos.X, headPos.Y)
						line.Color = lineColor

						box.Size = Vector2.new(width, height)
						box.Position = Vector2.new(headPos.X - width / 2, headPos.Y - height / 2)
						box.Color = enemy and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 150, 255)
						box.Visible = true

						local hpRatio = humanoid.Health / humanoid.MaxHealth
						healthBar.From = Vector2.new(box.Position.X - 6, box.Position.Y + height)
						healthBar.To = Vector2.new(box.Position.X - 6, box.Position.Y + height * (1 - hpRatio))
						healthBar.Visible = true

						nameText.Text = player.Name
						nameText.Position = Vector2.new(headPos.X, box.Position.Y + height + 10)
						nameText.Color = box.Color
						nameText.Visible = true

						distText.Text = string.format("%dm", math.floor(distance))
						distText.Position = Vector2.new(headPos.X, box.Position.Y - 15)
						distText.Visible = true

					else
						box.Visible = false
						line.Visible = false
						healthBar.Visible = false
						nameText.Visible = false
						distText.Visible = false
					end
				else
					box.Visible = false
					line.Visible = false
					healthBar.Visible = false
					nameText.Visible = false
					distText.Visible = false
				end
			else
				box.Visible = false
				line.Visible = false
				healthBar.Visible = false
				nameText.Visible = false
				distText.Visible = false
			end
			task.wait(updateInterval / 1000)
		end

		box:Remove()
		line:Remove()
		healthBar:Remove()
		nameText:Remove()
		distText:Remove()
	end)
end

--// Apply ESP to players
local function applyESP(player)
	if player ~= LocalPlayer then
		createESP(player)
		player.CharacterAdded:Connect(function()
			task.wait(1)
			createESP(player)
		end)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	applyESP(player)
end

Players.PlayerAdded:Connect(applyESP)
Players.PlayerRemoving:Connect(function(player)
	if espLoops[player] then
		espLoops[player].active = false
		espLoops[player] = nil
	end
end)
