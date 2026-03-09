local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local MiniFrame = Instance.new("Frame")
local MiniBtn = Instance.new("TextButton")
local OpenBtn = Instance.new("TextButton")
local ListFrame = Instance.new("ScrollingFrame")
local SpeedInput = Instance.new("TextBox")
local TimerInput = Instance.new("TextBox")
local WaitRoundInput = Instance.new("TextBox")
local AddBtn = Instance.new("TextButton")
local ModeBtn = Instance.new("TextButton")
local RunBtn = Instance.new("TextButton")
local StopBtn = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
local ListLayout = Instance.new("UIListLayout")

-- Setup GUI Window
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "GeminiPathBot_V3"

MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 250, 0, 540) -- Adjusted height
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.BorderSizePixel = 0

-- Minimize Logic
MiniBtn.Parent = MainFrame
MiniBtn.Size = UDim2.new(0, 30, 0, 30)
MiniBtn.Position = UDim2.new(1, -35, 0, 5)
MiniBtn.Text = "-"
MiniBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MiniBtn.TextColor3 = Color3.new(1, 1, 1)
MiniBtn.MouseButton1Click:Connect(function()
    MiniFrame.Position = MainFrame.Position
    MainFrame.Visible = false
    MiniFrame.Visible = true
end)

MiniFrame.Parent = ScreenGui
MiniFrame.Size = UDim2.new(0, 80, 0, 35)
MiniFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MiniFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MiniFrame.Visible = false
MiniFrame.Active = true
MiniFrame.Draggable = true

OpenBtn.Parent = MiniFrame
OpenBtn.Size = UDim2.new(1, 0, 1, 0)
OpenBtn.Text = "OPEN"
OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
OpenBtn.TextColor3 = Color3.new(1, 1, 1)
OpenBtn.BorderSizePixel = 0
OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Position = MiniFrame.Position
    MainFrame.Visible = true
    MiniFrame.Visible = false
end)

-- UI Helper Function
local function createInput(obj, placeholder, pos, size, default)
    obj.Parent = MainFrame
    obj.Size = size or UDim2.new(0.42, 0, 0, 30)
    obj.Position = pos
    obj.PlaceholderText = placeholder
    obj.Text = default
    obj.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    obj.TextColor3 = Color3.new(1, 1, 1)
    obj.BorderSizePixel = 0
end

-- Inputs (Shifted layout)
createInput(SpeedInput, "Fly Speed", UDim2.new(0.05, 0, 0.05, 0), nil, "50")
createInput(TimerInput, "Start In (s)", UDim2.new(0.53, 0, 0.05, 0), nil, "0")
createInput(WaitRoundInput, "Wait After Round", UDim2.new(0.05, 0, 0.12, 0), UDim2.new(0.9, 0, 0, 30), "5")

StatusLabel.Parent = MainFrame
StatusLabel.Size = UDim2.new(0.9, 0, 0, 25)
StatusLabel.Position = UDim2.new(0.05, 0, 0.19, 0)
StatusLabel.Text = "Status: Idle"
StatusLabel.TextColor3 = Color3.new(1, 1, 0)
StatusLabel.BackgroundTransparency = 1

ListFrame.Parent = MainFrame
ListFrame.Size = UDim2.new(0.9, 0, 0.25, 0)
ListFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
ListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ListLayout.Parent = ListFrame

local savedCoords = {}
local isRunning = false
local travelMode = "Fly"
local currentTween = nil

local function refreshList()
    for _, child in pairs(ListFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    for i, pos in ipairs(savedCoords) do
        local item = Instance.new("Frame")
        item.Size = UDim2.new(0.95, 0, 0, 35)
        item.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        item.BorderSizePixel = 0
        item.Parent = ListFrame
        
        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.new(0.75, 0, 1, 0)
        tpBtn.BackgroundTransparency = 1
        
        local displayX = math.floor(pos.X + 0.5)
        local displayY = math.floor(pos.Y + 0.5)
        local displayZ = math.floor(pos.Z + 0.5)
        
        tpBtn.Text = string.format("P%d: %d, %d, %d", i, displayX, displayY, displayZ)
        tpBtn.TextColor3 = Color3.new(1, 1, 1)
        tpBtn.TextScaled = true 
        tpBtn.Parent = item
        
        tpBtn.MouseButton1Click:Connect(function()
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(pos) end
        end)
        
        local del = Instance.new("TextButton")
        del.Size = UDim2.new(0.2, 0, 0.8, 0)
        del.Position = UDim2.new(0.78, 0, 0.1, 0)
        del.Text = "X"
        del.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        del.TextColor3 = Color3.new(1, 1, 1)
        del.BorderSizePixel = 0
        del.Parent = item
        del.MouseButton1Click:Connect(function() table.remove(savedCoords, i) refreshList() end)
    end
end

ModeBtn.Parent = MainFrame
ModeBtn.Size = UDim2.new(0.8, 0, 0, 35)
ModeBtn.Position = UDim2.new(0.1, 0, 0.53, 0)
ModeBtn.Text = "MODE: FLY"
ModeBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
ModeBtn.TextColor3 = Color3.new(1, 1, 1)
ModeBtn.MouseButton1Click:Connect(function()
    travelMode = (travelMode == "Fly") and "TP" or "Fly"
    ModeBtn.Text = "MODE: " .. travelMode:upper()
    ModeBtn.BackgroundColor3 = travelMode == "Fly" and Color3.fromRGB(100, 50, 150) or Color3.fromRGB(150, 50, 100)
end)

AddBtn.Parent = MainFrame
AddBtn.Size = UDim2.new(0.8, 0, 0, 35)
AddBtn.Position = UDim2.new(0.1, 0, 0.62, 0)
AddBtn.Text = "Add Current Position"
AddBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
AddBtn.TextColor3 = Color3.new(1, 1, 1)
AddBtn.MouseButton1Click:Connect(function() 
    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then table.insert(savedCoords, hrp.Position) refreshList() end
end)

RunBtn.Parent = MainFrame
RunBtn.Size = UDim2.new(0.8, 0, 0, 40)
RunBtn.Position = UDim2.new(0.1, 0, 0.73, 0)
RunBtn.Text = "START BOT"
RunBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
RunBtn.TextColor3 = Color3.new(1, 1, 1)
RunBtn.MouseButton1Click:Connect(function()
    if #savedCoords == 0 then StatusLabel.Text = "Add coords first!" return end
    if isRunning then return end
    isRunning = true
    local initialWait = tonumber(TimerInput.Text) or 0
    for i = initialWait, 1, -1 do
        if not isRunning then break end
        StatusLabel.Text = "Starting in: " .. i .. "s"
        task.wait(1)
    end
    while isRunning do
        for i, target in ipairs(savedCoords) do
            if not isRunning then break end
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then break end
            StatusLabel.Text = "Moving to Point: " .. i
            if travelMode == "Fly" then
                local flySpeed = tonumber(SpeedInput.Text) or 50
                local dist = (hrp.Position - target).Magnitude
                currentTween = game:GetService("TweenService"):Create(hrp, TweenInfo.new(dist/flySpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(target)})
                currentTween:Play()
                currentTween.Completed:Wait()
            else
                hrp.CFrame = CFrame.new(target)
                task.wait(0.1)
            end
        end
        if isRunning then
            local roundWait = tonumber(WaitRoundInput.Text) or 0
            for i = roundWait, 1, -1 do
                if not isRunning then break end
                StatusLabel.Text = "Waiting: " .. i .. "s"
                task.wait(1)
            end
        end
    end
end)

StopBtn.Parent = MainFrame
StopBtn.Size = UDim2.new(0.8, 0, 0, 40)
StopBtn.Position = UDim2.new(0.1, 0, 0.85, 0)
StopBtn.Text = "STOP"
StopBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
StopBtn.TextColor3 = Color3.new(1, 1, 1)
StopBtn.MouseButton1Click:Connect(function() isRunning = false if currentTween then currentTween:Cancel() end StatusLabel.Text = "Status: Stopped" end)

-- Anti-collision Logic
game:GetService("RunService").Stepped:Connect(function()
    if isRunning and game.Players.LocalPlayer.Character then
        for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)
