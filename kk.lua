
-- Aimbot with Toggle, FOV Slider, TeamCheck, WallCheck, IgnoreGround, ESP, and Advanced GUI
-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Settings
local aimbotEnabled = false
local espEnabled = true
local wallCheckEnabled = true
local teamCheckEnabled = true
local ignoreGroundEnabled = true   -- NEW: ignore grounded players
local fovRadius = 100
local targetPart = "Head"
local floatingIconVisible = true
local guiLocked = false
local panelSize = {Width = 280, Height = 420}  -- increased height for new toggle

-- ESP storage
local espObjects = {}
local floatingIcon = nil
local floatingIconDragging = false
local floatingIconDragStart, floatingIconStartPos

-- FOV Circle
local fovCircle = Drawing and Drawing.new("Circle") or nil
if fovCircle then
    fovCircle.Thickness = 1
    fovCircle.NumSides = 64
    fovCircle.Radius = fovRadius
    fovCircle.Filled = false
    fovCircle.Visible = true
    fovCircle.Color = Color3.fromRGB(255, 255, 0)
end

-- Helper functions
local function isTeammate(player)
    return teamCheckEnabled and LocalPlayer.Team and player.Team == LocalPlayer.Team
end

local function isAlive(character)
    local humanoid = character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function isGrounded(character)
    if not ignoreGroundEnabled then return false end  -- if ignore ground is OFF, we don't skip grounded players
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return true end  -- treat as grounded if no root part (should not happen)
    -- Raycast downwards to check if there's a part within 5 studs
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(rootPart.Position, Vector3.new(0, -5, 0), rayParams)
    return result ~= nil  -- if something is below, they're grounded
end

local function isVisible(part)
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * 1000
    local ray = RaycastParams.new()
    ray.FilterDescendantsInstances = {LocalPlayer.Character}
    ray.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(origin, direction, ray)
    return result and result.Instance and part:IsDescendantOf(result.Instance.Parent)
end

-- ESP Functions
local function createESP(player)
    if espObjects[player] then return end
    local function addESP()
        if not player.Character or not isAlive(player.Character) then return end
        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local box = Instance.new("BoxHandleAdornment")
        box.Size = Vector3.new(4, 6, 2)
        box.Adornee = rootPart
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Color3 = Color3.fromRGB(255, 80, 80)
        box.Transparency = 0.25
        box.Parent = rootPart
        espObjects[player] = box

        -- Clean up when character dies
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            local conn
            conn = humanoid.Died:Connect(function()
                if espObjects[player] then
                    espObjects[player]:Destroy()
                    espObjects[player] = nil
                end
                conn:Disconnect()
            end)
        end
    end

    -- Re-add ESP when character respawns
    player.CharacterAdded:Connect(function()
        if espObjects[player] then
            espObjects[player]:Destroy()
            espObjects[player] = nil
        end
        addESP()
    end)

    if player.Character then
        addESP()
    end
end

local function removeESP(player)
    if espObjects[player] then
        espObjects[player]:Destroy()
        espObjects[player] = nil
    end
end

-- Aimbot targeting (with ignore ground)
local function getClosestTarget()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character or not player.Character:FindFirstChild(targetPart) then continue end
        if not isAlive(player.Character) then continue end
        if isTeammate(player) then continue end
        if isGrounded(player.Character) then continue end  -- skip if grounded and ignoreGround is ON

        local part = player.Character[targetPart]
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if onScreen then
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
            if dist < shortestDistance and dist <= fovRadius then
                if not wallCheckEnabled or isVisible(part) then
                    closestPlayer = player
                    shortestDistance = dist
                end
            end
        end
    end
    return closestPlayer
end

-- Create Floating Icon (Aimbot Toggle)
local function createFloatingIcon()
    if floatingIcon then floatingIcon:Destroy() end

    local ScreenGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("AimbotUI")
    if not ScreenGui then return end

    floatingIcon = Instance.new("ImageButton")
    floatingIcon.Size = UDim2.new(0, 45, 0, 45)
    floatingIcon.Position = UDim2.new(0, 50, 0, 150) -- default position
    floatingIcon.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    floatingIcon.BackgroundTransparency = 0.2
    floatingIcon.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    floatingIcon.ImageColor3 = Color3.fromRGB(255, 80, 80)
    floatingIcon.Parent = ScreenGui

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = "🎯"
    iconLabel.TextColor3 = Color3.new(1, 1, 1)
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.TextSize = 28
    iconLabel.Parent = floatingIcon

    -- Update color based on aimbot state
    local function updateIconColor()
        if aimbotEnabled then
            floatingIcon.ImageColor3 = Color3.fromRGB(100, 255, 100)
            iconLabel.Text = "🔫"
        else
            floatingIcon.ImageColor3 = Color3.fromRGB(255, 80, 80)
            iconLabel.Text = "🎯"
        end
    end
    updateIconColor()

    floatingIcon.MouseButton1Click:Connect(function()
        aimbotEnabled = not aimbotEnabled
        updateIconColor()
        -- Update main panel button text if it exists
        local panel = ScreenGui:FindFirstChild("MainPanel")
        if panel then
            local aimbotBtn = panel:FindFirstChild("AimbotBtn")
            if aimbotBtn then aimbotBtn.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF") end
        end
    end)

    -- Dragging for floating icon (only when unlocked)
    local function startDrag(input)
        if guiLocked then return end
        floatingIconDragging = true
        floatingIconDragStart = input.Position
        floatingIconStartPos = floatingIcon.Position
    end

    local function updateDrag(input)
        if not floatingIconDragging or guiLocked then return end
        local delta = input.Position - floatingIconDragStart
        floatingIcon.Position = UDim2.new(floatingIconStartPos.X.Scale, floatingIconStartPos.X.Offset + delta.X,
                                          floatingIconStartPos.Y.Scale, floatingIconStartPos.Y.Offset + delta.Y)
    end

    local function endDrag()
        floatingIconDragging = false
    end

    floatingIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            startDrag(input)
        end
    end)
    floatingIcon.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateDrag(input)
        end
    end)
    floatingIcon.InputEnded:Connect(endDrag)
end

-- GUI Creation
local function createUI()
    -- Destroy any existing GUI to avoid duplicates
    local existingGui = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("AimbotUI")
    if existingGui then existingGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AimbotUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Main draggable panel
    local mainPanel = Instance.new("Frame")
    mainPanel.Name = "MainPanel"
    mainPanel.Size = UDim2.new(0, panelSize.Width, 0, panelSize.Height)
    mainPanel.Position = UDim2.new(0, 20, 0, 100)
    mainPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainPanel.BackgroundTransparency = 0.2
    mainPanel.BorderSizePixel = 0
    mainPanel.Visible = true
    mainPanel.Parent = ScreenGui

    -- Title bar for dragging
    local dragBar = Instance.new("Frame")
    dragBar.Size = UDim2.new(1, 0, 0, 30)
    dragBar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    dragBar.BorderSizePixel = 0
    dragBar.Parent = mainPanel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "Aimbot Controls"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = dragBar

    -- Lock Button
    local lockBtn = Instance.new("TextButton")
    lockBtn.Size = UDim2.new(0, 40, 1, -4)
    lockBtn.Position = UDim2.new(1, -45, 0, 2)
    lockBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    lockBtn.Text = "🔓"
    lockBtn.TextColor3 = Color3.new(1, 1, 1)
    lockBtn.Font = Enum.Font.SourceSansBold
    lockBtn.TextSize = 18
    lockBtn.Parent = dragBar

    lockBtn.MouseButton1Click:Connect(function()
        guiLocked = not guiLocked
        lockBtn.Text = guiLocked and "🔒" or "🔓"
    end)

    -- Dragging logic (only when unlocked)
    local dragging = false
    local dragInput, dragStart, startPos

    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not guiLocked then
            dragging = true
            dragStart = input.Position
            startPos = mainPanel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging and not guiLocked then
            local delta = input.Position - dragStart
            mainPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- FOV Slider
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Text = "FOV Radius: " .. fovRadius
    sliderLabel.Size = UDim2.new(0, 210, 0, 25)
    sliderLabel.Position = UDim2.new(0, 20, 0, 45)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.TextColor3 = Color3.new(1, 1, 1)
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.TextScaled = true
    sliderLabel.Parent = mainPanel

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0, 210, 0, 15)
    sliderFrame.Position = UDim2.new(0, 20, 0, 75)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = mainPanel

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(fovRadius / 300, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(150, 150, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderFrame

    local function updateFOV(pos)
        local relativeX = math.clamp(pos.X - sliderFrame.AbsolutePosition.X, 0, sliderFrame.AbsoluteSize.X)
        local ratio = relativeX / sliderFrame.AbsoluteSize.X
        fovRadius = math.floor(ratio * 300)
        sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
        sliderLabel.Text = "FOV Radius: " .. fovRadius
        if fovCircle then fovCircle.Radius = fovRadius end
    end

    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateFOV(input.Position)
            local conn
            conn = UIS.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == input.UserInputType then
                    updateFOV(moveInput.Position)
                end
            end)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    conn:Disconnect()
                end
            end)
        end
    end)

    -- Toggle Buttons
    local function makeButton(text, yPos, variable, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 210, 0, 30)
        btn.Position = UDim2.new(0, 20, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 16
        btn.Text = text .. ": " .. (variable and "ON" or "OFF")
        btn.Parent = mainPanel

        btn.MouseButton1Click:Connect(function()
            variable = not variable
            btn.Text = text .. ": " .. (variable and "ON" or "OFF")
            if callback then callback(variable) end
        end)

        return btn, function() return variable end
    end

    local aimbotBtn, getAimbot = makeButton("Aimbot", 110, aimbotEnabled, function(v) aimbotEnabled = v end)
    aimbotBtn.Name = "AimbotBtn"
    local espBtn, getEsp = makeButton("ESP", 145, espEnabled, function(v)
        espEnabled = v
        if not v then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then removeESP(player) end
            end
        else
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then createESP(player) end
            end
        end
    end)
    local wallCheckBtn, getWallCheck = makeButton("Wall Check", 180, wallCheckEnabled, function(v) wallCheckEnabled = v end)
    local teamCheckBtn, getTeamCheck = makeButton("Team Check", 215, teamCheckEnabled, function(v) teamCheckEnabled = v end)
    local ignoreGroundBtn, getIgnoreGround = makeButton("Ignore Ground", 250, ignoreGroundEnabled, function(v) ignoreGroundEnabled = v end)

    -- Floating Icon Toggle Button
    local iconToggleBtn = Instance.new("TextButton")
    iconToggleBtn.Size = UDim2.new(0, 210, 0, 30)
    iconToggleBtn.Position = UDim2.new(0, 20, 0, 285)
    iconToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    iconToggleBtn.TextColor3 = Color3.new(1, 1, 1)
    iconToggleBtn.Font = Enum.Font.SourceSansBold
    iconToggleBtn.TextSize = 16
    iconToggleBtn.Text = "Show Floating Icon: " .. (floatingIconVisible and "ON" or "OFF")
    iconToggleBtn.Parent = mainPanel

    iconToggleBtn.MouseButton1Click:Connect(function()
        floatingIconVisible = not floatingIconVisible
        iconToggleBtn.Text = "Show Floating Icon: " .. (floatingIconVisible and "ON" or "OFF")
        if floatingIconVisible then
            if not floatingIcon or not floatingIcon.Parent then
                createFloatingIcon()
            else
                floatingIcon.Visible = true
            end
        else
            if floatingIcon then floatingIcon.Visible = false end
        end
    end)

    -- Size Slider
    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Text = "Panel Size: " .. math.floor(panelSize.Width) .. "x" .. math.floor(panelSize.Height)
    sizeLabel.Size = UDim2.new(0, 210, 0, 25)
    sizeLabel.Position = UDim2.new(0, 20, 0, 325)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.TextColor3 = Color3.new(1, 1, 1)
    sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    sizeLabel.TextScaled = true
    sizeLabel.Parent = mainPanel

    local sizeSliderFrame = Instance.new("Frame")
    sizeSliderFrame.Size = UDim2.new(0, 210, 0, 15)
    sizeSliderFrame.Position = UDim2.new(0, 20, 0, 355)
    sizeSliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    sizeSliderFrame.BorderSizePixel = 0
    sizeSliderFrame.Parent = mainPanel

    local sizeFill = Instance.new("Frame")
    sizeFill.Size = UDim2.new((panelSize.Width - 200) / 200, 0, 1, 0) -- range 200-400 width
    sizeFill.BackgroundColor3 = Color3.fromRGB(150, 150, 255)
    sizeFill.BorderSizePixel = 0
    sizeFill.Parent = sizeSliderFrame

    local function updateSize(pos)
        local relativeX = math.clamp(pos.X - sizeSliderFrame.AbsolutePosition.X, 0, sizeSliderFrame.AbsoluteSize.X)
        local ratio = relativeX / sizeSliderFrame.AbsoluteSize.X
        local newWidth = 200 + ratio * 200  -- width between 200 and 400
        local newHeight = 250 + ratio * 150 -- height between 250 and 400
        panelSize.Width = newWidth
        panelSize.Height = newHeight
        mainPanel.Size = UDim2.new(0, newWidth, 0, newHeight)
        sizeFill.Size = UDim2.new(ratio, 0, 1, 0)
        sizeLabel.Text = "Panel Size: " .. math.floor(newWidth) .. "x" .. math.floor(newHeight)
    end

    sizeSliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSize(input.Position)
            local conn
            conn = UIS.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == input.UserInputType then
                    updateSize(moveInput.Position)
                end
            end)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    conn:Disconnect()
                end
            end)
        end
    end)

    -- Gear icon to toggle main panel visibility
    local gearIcon = Instance.new("ImageButton")
    gearIcon.Size = UDim2.new(0, 40, 0, 40)
    gearIcon.Position = UDim2.new(1, -50, 0, 20)
    gearIcon.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    gearIcon.BackgroundTransparency = 0.5
    gearIcon.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    gearIcon.Parent = ScreenGui

    local gearLabel = Instance.new("TextLabel")
    gearLabel.Size = UDim2.new(1, 0, 1, 0)
    gearLabel.BackgroundTransparency = 1
    gearLabel.Text = "⚙️"
    gearLabel.TextColor3 = Color3.new(1, 1, 1)
    gearLabel.Font = Enum.Font.SourceSansBold
    gearLabel.TextSize = 24
    gearLabel.Parent = gearIcon

    gearIcon.MouseButton1Click:Connect(function()
        mainPanel.Visible = not mainPanel.Visible
    end)

    -- Initial creation of floating icon if visible
    if floatingIconVisible then
        createFloatingIcon()
    end
end

-- Initialize GUI
createUI()

-- Handle new players and ESP
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        if espEnabled then createESP(player) end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- Apply ESP to existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and espEnabled then
        createESP(player)
    end
end

-- Update FOV circle position each frame
RunService.RenderStepped:Connect(function()
    if fovCircle then
        local screenSize = Camera.ViewportSize
        fovCircle.Position = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
        fovCircle.Radius = fovRadius
    end
end)

-- Aimbot loop
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local target = getClosestTarget()
        if target and target.Character and target.Character:FindFirstChild(targetPart) then
            local targetPos = target.Character[targetPart].Position
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        end
    end
end)
