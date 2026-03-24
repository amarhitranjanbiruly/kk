local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Default Settings
local TOGGLE_INFINITE = false 
local MAX_JUMPS = 2           
local TIME_BETWEEN_JUMPS = 0.2

-- 1. CREATE MOVABLE GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomJumpGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 220)
mainFrame.Position = UDim2.new(0.1, 0, 0.5, -110)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true
mainFrame.Draggable = true -- Makes it movable
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "JUMP SETTINGS (Drag Me)"
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Parent = mainFrame

-- 2. INPUT BOXES
local function createInput(name, default, pos)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.Position = UDim2.new(0, 0, 0, pos)
	label.Text = name
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	label.Parent = mainFrame
	
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0.8, 0, 0, 25)
	box.Position = UDim2.new(0.1, 0, 0, pos + 20)
	box.Text = tostring(default)
	box.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	box.TextColor3 = Color3.new(1, 1, 1)
	box.Parent = mainFrame
	return box
end

local jumpBox = createInput("Max Jumps:", MAX_JUMPS, 40)
local delayBox = createInput("Jump Delay:", TIME_BETWEEN_JUMPS, 90)

-- 3. TOGGLE BUTTON
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.8, 0, 0, 40)
toggleButton.Position = UDim2.new(0.1, 0, 0, 160)
toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleButton.Text = "INFINITE: OFF"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = mainFrame

-- Update settings when typing
jumpBox.FocusLost:Connect(function() MAX_JUMPS = tonumber(jumpBox.Text) or 2 end)
delayBox.FocusLost:Connect(function() TIME_BETWEEN_JUMPS = tonumber(delayBox.Text) or 0.2 end)

toggleButton.MouseButton1Click:Connect(function()
	TOGGLE_INFINITE = not TOGGLE_INFINITE
	toggleButton.Text = TOGGLE_INFINITE and "INFINITE: ON" or "INFINITE: OFF"
	toggleButton.BackgroundColor3 = TOGGLE_INFINITE and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

-- 4. JUMP LOGIC (RESPAWN PROOF)
local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local numJumps = 0
	local canJumpAgain = false
	
	local stateConn = humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			numJumps = 0
			canJumpAgain = false
		elseif newState == Enum.HumanoidStateType.Freefall then
			task.wait(TIME_BETWEEN_JUMPS)
			canJumpAgain = true
		elseif newState == Enum.HumanoidStateType.Jumping then
			canJumpAgain = false
			numJumps += 1
		end
	end)

	local jumpReq = UserInputService.JumpRequest:Connect(function()
		if TOGGLE_INFINITE then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		elseif canJumpAgain and numJumps < MAX_JUMPS then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)

	humanoid.Died:Connect(function()
		stateConn:Disconnect()
		jumpReq:Disconnect()
	end)
end

if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)
