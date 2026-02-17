-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local settings = {
    aimbot = true,
    esp = true,
    tracers = true,
    fov = 150,
    teamCheck = true -- Change to false if you want to see everyone including teammates
}

-- Drawing FOV Circle
local FOVring = Drawing.new("Circle")
FOVring.Thickness = 1.5
FOVring.Radius = settings.fov
FOVring.Transparency = 1
FOVring.Color = Color3.fromRGB(255,128,128)
FOVring.Filled = false
FOVring.Visible = true
FOVring.Position = Camera.ViewportSize / 2

-- Store ESP and Tracer objects
local espObjects = {}
local tracerObjects = {}

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 150)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundTransparency = 0.5
Frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
Frame.Visible = true

local guiVisible = true
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        guiVisible = not guiVisible
        Frame.Visible = guiVisible
    end
end)

local function createToggle(name, y, state, callback)
    local btn = Instance.new("TextButton", Frame)
    btn.Text = name .. ": " .. (state and "ON" or "OFF")
    btn.Size = UDim2.new(1, -10, 0, 25)
    btn.Position = UDim2.new(0, 5, 0, y)
    btn.BackgroundColor3 = state and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 18
    btn.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
    end)
    return btn
end

-- GUI Buttons
local y = 5
createToggle("Aimbot", y, settings.aimbot, function(v) settings.aimbot = v end); y += 30
createToggle("ESP Boxes", y, settings.esp, function(v) settings.esp = v end); y += 30
createToggle("Tracers", y, settings.tracers, function(v) settings.tracers = v end)

-- Targeting function
local function getClosestTarget()
    local mouse = UserInputService:GetMouseLocation()
    local closest, bestDist = nil, settings.fov
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if not settings.teamCheck or player.Team ~= LocalPlayer.Team then
                local pos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
                if onScreen then
                    local dist = (mouse - Vector2.new(pos.X, pos.Y)).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

-- Create drawing objects for a player
local function createPlayerESP(player)
    if espObjects[player] or tracerObjects[player] then return end

    espObjects[player] = {
        box = Drawing.new("Square"),
        health = Drawing.new("Line")
    }

    tracerObjects[player] = Drawing.new("Line")
end

-- Remove drawings
local function removePlayerAssets(player)
    if espObjects[player] then
        espObjects[player].box:Remove()
        espObjects[player].health:Remove()
        espObjects[player] = nil
    end
    if tracerObjects[player] then
        tracerObjects[player]:Remove()
        tracerObjects[player] = nil
    end
end

-- Setup for existing and future players
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        createPlayerESP(p)
    end
end
Players.PlayerAdded:Connect(createPlayerESP)
Players.PlayerRemoving:Connect(removePlayerAssets)

-- Main Render Loop
RunService.RenderStepped:Connect(function()
    FOVring.Position = Camera.ViewportSize / 2
    FOVring.Visible = settings.aimbot

    -- Aimbot
    if settings.aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosestTarget()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        end
    end

    -- ESP + Tracers
    for player, esp in pairs(espObjects) do
        local char = player.Character
        if player ~= LocalPlayer and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") then
            if not settings.teamCheck or player.Team ~= LocalPlayer.Team then
                local headPos, onScreenHead = Camera:WorldToViewportPoint(char.Head.Position)
                local hrpPos, onScreenHRP = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)

                if onScreenHead or onScreenHRP then
                    local height = math.abs(hrpPos.Y - headPos.Y) * 2
                    local width = height / 1.5
                    local boxPos = Vector2.new(hrpPos.X - width/2, hrpPos.Y - height/2)

                    esp.box.Size = Vector2.new(width, height)
                    esp.box.Position = boxPos
                    esp.box.Color = Color3.fromRGB(255, 0, 0)
                    esp.box.Visible = settings.esp

                    local hpPercent = math.clamp(char.Humanoid.Health / char.Humanoid.MaxHealth, 0, 1)
                    local barHeight = height * hpPercent

                    esp.health.From = Vector2.new(boxPos.X - 5, boxPos.Y + height)
                    esp.health.To = Vector2.new(boxPos.X - 5, boxPos.Y + height - barHeight)
                    esp.health.Color = Color3.fromRGB(255 - (hpPercent * 255), hpPercent * 255, 0)
                    esp.health.Visible = settings.esp
                else
                    esp.box.Visible = false
                    esp.health.Visible = false
                end
            else
                esp.box.Visible = false
                esp.health.Visible = false
            end
        else
            esp.box.Visible = false
            esp.health.Visible = false
        end
    end

    -- Tracers
    for player, line in pairs(tracerObjects) do
        local char = player.Character
        if player ~= LocalPlayer and char and char:FindFirstChild("HumanoidRootPart") then
            if not settings.teamCheck or player.Team ~= LocalPlayer.Team then
                local pos, onScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
                if onScreen and settings.tracers then
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(pos.X, pos.Y)
                    line.Color = Color3.fromRGB(255, 0, 0)
                    line.Thickness = 1
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end

    -- Exit
    if UserInputService:IsKeyDown(Enum.KeyCode.Delete) then
        FOVring:Remove()
        for _, v in pairs(espObjects) do
            v.box:Remove()
            v.health:Remove()
        end
        for _, l in pairs(tracerObjects) do
            l:Remove()
        end
        ScreenGui:Destroy()
        espObjects = {}
        tracerObjects = {}
        warn("Script stopped.")
        return
    end
end)
