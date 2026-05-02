--[[
    MOVABLE BUTTON WITH DRAG HANDLE
    - Drag the top bar to move the button.
    - Click the main button to run your custom action.
    - Place this script in a LocalScript (e.g., inside StarterGui).
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Create GUI container
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MovableButtonGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main frame that holds everything
local frame = Instance.new("Frame")
frame.Name = "MovableFrame"
frame.BackgroundColor3 = Color3.fromRGB(41, 128, 185)
frame.BackgroundTransparency = 0
frame.BorderSizePixel = 0
frame.Size = UDim2.new(0, 200, 0, 80)
frame.Parent = screenGui

-- Round corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

-- Drag handle (top bar)
local dragHandle = Instance.new("TextButton")
dragHandle.Name = "DragHandle"
dragHandle.BackgroundColor3 = Color3.fromRGB(30, 110, 160)
dragHandle.BackgroundTransparency = 0
dragHandle.BorderSizePixel = 0
dragHandle.Size = UDim2.new(1, 0, 0, 25)
dragHandle.Position = UDim2.new(0, 0, 0, 0)
dragHandle.Text = "⋮⋮  DRAG  ⋮⋮"
dragHandle.TextColor3 = Color3.new(1, 1, 1)
dragHandle.TextSize = 14
dragHandle.Font = Enum.Font.GothamBold
dragHandle.AutoButtonColor = true
dragHandle.Parent = frame

-- Handle corners (only top corners round, but we'll keep it simple)
local handleCorner = Instance.new("UICorner")
handleCorner.CornerRadius = UDim.new(0, 10)
handleCorner.Parent = dragHandle

-- Main action button (the rest of the frame)
local actionButton = Instance.new("TextButton")
actionButton.Name = "ActionButton"
actionButton.BackgroundColor3 = Color3.fromRGB(41, 128, 185)
actionButton.BackgroundTransparency = 0
actionButton.BorderSizePixel = 0
actionButton.Size = UDim2.new(1, 0, 1, -25)
actionButton.Position = UDim2.new(0, 0, 0, 25)
actionButton.Text = "⚡ EXECUTE ⚡"
actionButton.TextColor3 = Color3.new(1, 1, 1)
actionButton.TextSize = 18
actionButton.Font = Enum.Font.GothamBold
actionButton.AutoButtonColor = true
actionButton.Parent = frame

-- Round bottom corners (so only the action button's bottom is rounded)
local actionCorner = Instance.new("UICorner")
actionCorner.CornerRadius = UDim.new(0, 10)
actionCorner.Parent = actionButton

-- Hover effect on action button (optional)
actionButton.MouseEnter:Connect(function()
    local tween = TweenService:Create(actionButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(52, 152, 219)})
    tween:Play()
end)
actionButton.MouseLeave:Connect(function()
    local tween = TweenService:Create(actionButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(41, 128, 185)})
    tween:Play()
end)

-- Center the button initially
local function centerFrame()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local screenSize = camera.ViewportSize
    local frameSize = frame.AbsoluteSize
    if frameSize.X == 0 then
        task.wait()
        frameSize = frame.AbsoluteSize
    end
    local x = (screenSize.X / 2) - (frameSize.X / 2)
    local y = (screenSize.Y / 2) - (frameSize.Y / 2)
    frame.Position = UDim2.fromOffset(x, y)
end

frame.Parent = screenGui
task.wait(0.1)
centerFrame()

-- ===== DRAG LOGIC FOR THE HANDLE =====
local dragging = false
local dragStartMousePos = nil
local dragStartFramePos = nil
local dragThreshold = 3

local function cleanupDrag()
    -- No extra connections to clean here; we'll handle within InputChanged/Ended
end

-- Use dragHandle's InputBegan/Changed/Ended
dragHandle.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        dragStartMousePos = UserInputService:GetMouseLocation()
        dragStartFramePos = frame.Position
        -- Change handle color to show active drag
        dragHandle.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local currentMousePos = UserInputService:GetMouseLocation()
        local delta = currentMousePos - dragStartMousePos
        local newXOffset = dragStartFramePos.X.Offset + delta.X
        local newYOffset = dragStartFramePos.Y.Offset + delta.Y
        
        -- Clamp to screen edges
        local screenSize = workspace.CurrentCamera.ViewportSize
        local frameSize = frame.AbsoluteSize
        local maxX = screenSize.X - frameSize.X
        local maxY = screenSize.Y - frameSize.Y
        newXOffset = math.clamp(newXOffset, 0, maxX)
        newYOffset = math.clamp(newYOffset, 0, maxY)
        
        frame.Position = UDim2.fromOffset(newXOffset, newYOffset)
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            dragging = false
            dragHandle.BackgroundColor3 = Color3.fromRGB(30, 110, 160)
        end
        dragging = false
    end
end)

-- We need a separate connection to start dragging after threshold
-- Because InputBegan sets `dragging = false`, and we need to set it to true after movement
local moveConn
dragHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        moveConn = UserInputService.InputChanged:Connect(function(changeInput)
            if changeInput.UserInputType == Enum.UserInputType.MouseMovement or changeInput.UserInputType == Enum.UserInputType.Touch then
                if not dragging and dragStartMousePos then
                    local distance = (UserInputService:GetMouseLocation() - dragStartMousePos).Magnitude
                    if distance >= dragThreshold then
                        dragging = true
                    end
                end
            end
        end)
    end
end)

dragHandle.InputEnded:Connect(function()
    if moveConn then moveConn:Disconnect() end
end)

-- ===== CUSTOM ACTION SECTION =====
-- Replace the code inside this function with your own logic.
local function executeCustomAction()
    -- ************* YOUR SCRIPT GOES HERE *************
  -- Paste into Command Bar while sitting in your car
local player = game.Players.LocalPlayer
local character = player.Character
if not character then return warn("No character") end

local humanoid = character:FindFirstChild("Humanoid")
local seat = humanoid and humanoid.SeatPart
if not seat then return warn("You are not sitting in a car") end

-- Find the car model
local car = seat.Parent
while car and car ~= workspace do
    if car:IsA("Model") and car:FindFirstChildWhichIsA("VehicleSeat") then break end
    car = car.Parent
end
if not car or car == workspace then return warn("Could not find car model") end

print("Found car:", car.Name)

-- Ensure car has a PrimaryPart
if not car.PrimaryPart then
    local part = car:FindFirstChildWhichIsA("BasePart")
    if part then 
        car.PrimaryPart = part 
    else 
        return error("Car has no BasePart")
    end
end

-- 🧠 Detect which game mode is active
local checkpointsFolder = workspace:FindFirstChild("HighwayRace_solo_ServerCheckpoints")
local mode = "solo"
if not checkpointsFolder then
    checkpointsFolder = workspace:FindFirstChild("HighwayRace_ServerCheckpoints")
    mode = "normal"
end
if not checkpointsFolder then
    return warn("No checkpoints folder found (HighwayRace_solo_ServerCheckpoints or HighwayRace_ServerCheckpoints)")
end

print("Detected mode:", mode, "→ using folder:", checkpointsFolder.Name)

-- Build checkpoint list from 1 to 27 + ServerFinishLine
local checkpoints = {}
for i = 1, 27 do
    local cp = checkpointsFolder:FindFirstChild(tostring(i))
    if cp then
        table.insert(checkpoints, cp)
    else
        warn("Checkpoint", i, "missing in", checkpointsFolder.Name)
    end
end
local finishLine = checkpointsFolder:FindFirstChild("ServerFinishLine")
if finishLine then
    table.insert(checkpoints, finishLine)
else
    warn("ServerFinishLine missing in", checkpointsFolder.Name)
end

if #checkpoints == 0 then
    return warn("No checkpoints found")
end

-- Teleport function (raises car by 2 studs)
local function teleport(target)
    local raise = 2
    if target:IsA("BasePart") then
        car:SetPrimaryPartCFrame(target.CFrame + Vector3.new(0, raise, 0))
        print("Teleported to", target.Name)
    elseif target:IsA("Model") and target.PrimaryPart then
        car:SetPrimaryPartCFrame(target.PrimaryPart.CFrame + Vector3.new(0, raise, 0))
        print("Teleported to model", target.Name)
    else
        warn("Invalid target:", target)
    end
end

-- Start teleporting
for _, cp in ipairs(checkpoints) do
    if cp then
        teleport(cp)
    end
    task.wait(0.5)
end

print("✅ All checkpoints visited in", mode, "mode!")
    
    -- ************* END OF CUSTOM SCRIPT AREA *************
end

-- Connect the main button click (not the drag handle)
actionButton.MouseButton1Click:Connect(executeCustomAction)

-- Optional: expose functions for external control
_G.MovableButton = {
    setCustomAction = function(func)
        if type(func) == "function" then
            executeCustomAction = func
            print("Custom action updated.")
        else
            warn("New action must be a function.")
        end
    end,
    getFrame = function() return frame end,
    center = centerFrame
}

print("Movable button ready! Drag the top bar to move, click the big area to execute your script.")
