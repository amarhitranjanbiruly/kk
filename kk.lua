local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local maxDistance = 200
local maxRAMLimitMB = 5000

local espDrawings = {}
local visibilityCache = {} 
local lastCheckTick = 0

-- Performance Fix: Reuse RaycastParams
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function isMemoryTooHigh()
    if tick() - lastCheckTick < 1 then return false end
    lastCheckTick = tick()

    local memMB = collectgarbage("count") / 1024
    if memMB > maxRAMLimitMB then
        warn("[ESP] Memory usage too high, pausing ESP updates!")
        return true
    end
    return false
end

local function isVisible(targetPart, targetCharacter, player)
    if not targetPart then return false end
    
    -- Performance Fix: Throttle visibility checks to stop stuttering
    local now = tick()
    if visibilityCache[player] and (now - visibilityCache[player].lastUpdate) < 0.1 then
        return visibilityCache[player].visible
    end

    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local distance = direction.Magnitude

    if distance < 40 then
        local viewDir = Camera.CFrame.LookVector
        local dot = viewDir:Dot(direction.Unit)
        local isVis = dot > 0.2
        visibilityCache[player] = {visible = isVis, lastUpdate = now}
        return isVis
    end

    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
    local result = Workspace:Raycast(origin, direction, raycastParams)
    local isVis = (result == nil)
    
    visibilityCache[player] = {visible = isVis, lastUpdate = now}
    return isVis
end

local function createESP(player)
    if espDrawings[player] then
        for _, drawing in pairs(espDrawings[player]) do
            drawing:Remove()
        end
    end

    local drawings = {
        box = Drawing.new("Square"),
        line = Drawing.new("Line"),
        healthBar = Drawing.new("Line"),
        nameText = Drawing.new("Text"),
        distText = Drawing.new("Text")
    }

    drawings.box.Thickness = 2
    drawings.box.Filled = false
    drawings.box.Transparency = 1

    drawings.healthBar.Thickness = 2
    drawings.healthBar.Color = Color3.fromRGB(0, 255, 0)
    drawings.healthBar.Transparency = 1

    drawings.line.Thickness = 1
    drawings.line.Transparency = 1

    drawings.nameText.Size = 13
    drawings.nameText.Center = true
    drawings.nameText.Outline = true
    drawings.nameText.Transparency = 1

    drawings.distText.Size = 13
    drawings.distText.Center = true
    drawings.distText.Outline = true
    drawings.distText.Transparency = 1
    drawings.distText.Color = Color3.fromRGB(0, 255, 0)

    espDrawings[player] = drawings
end

local function removeESP(player)
    if espDrawings[player] then
        for _, drawing in pairs(espDrawings[player]) do
            drawing:Remove()
        end
        espDrawings[player] = nil
        visibilityCache[player] = nil
    end
end

RunService.RenderStepped:Connect(function()
    if isMemoryTooHigh() then
        for _, drawings in pairs(espDrawings) do
            for _, drawing in pairs(drawings) do
                drawing.Visible = false
            end
        end
        return
    end

    local screenCenter = Camera.ViewportSize / 2
    local camPos = Camera.CFrame.Position

    for player, drawings in pairs(espDrawings) do
        if player == LocalPlayer then continue end

        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")

        if not (head and hrp and humanoid and humanoid.Health > 0) then
            for _, drawing in pairs(drawings) do
                drawing.Visible = false
            end
            continue
        end

        local distance = (camPos - hrp.Position).Magnitude
        if distance > maxDistance then
            for _, drawing in pairs(drawings) do
                drawing.Visible = false
            end
            continue
        end

        local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then
            for _, drawing in pairs(drawings) do
                drawing.Visible = false
            end
            continue
        end

        local feetPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local height = math.abs(headPos.Y - feetPos.Y)
        local width = math.clamp(height / 2, 10, 250)
        height = math.clamp(height, 20, 500)

        local enemy = player.Team ~= LocalPlayer.Team
        local visible = isVisible(head, char, player)

        -- Tracer (Fixed: Starting from TOP of screen)
        drawings.line.Visible = enemy
        drawings.line.From = Vector2.new(screenCenter.X, 0) 
        drawings.line.To = Vector2.new(headPos.X, headPos.Y)
        drawings.line.Color = visible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

        -- Box
        drawings.box.Size = Vector2.new(width, height)
        drawings.box.Position = Vector2.new(headPos.X - width / 2, headPos.Y)
        drawings.box.Color = enemy and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 150, 255)
        drawings.box.Visible = true

        -- Health bar
        local hpRatio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        drawings.healthBar.From = Vector2.new(drawings.box.Position.X - 6, drawings.box.Position.Y + height)
        drawings.healthBar.To = Vector2.new(drawings.box.Position.X - 6, drawings.box.Position.Y + height * (1 - hpRatio))
        drawings.healthBar.Visible = true

        -- Name
        drawings.nameText.Text = player.Name
        drawings.nameText.Position = Vector2.new(headPos.X, drawings.box.Position.Y + height + 2)
        drawings.nameText.Color = drawings.box.Color
        drawings.nameText.Visible = true

        -- Distance
        drawings.distText.Text = string.format("[%dm]", math.floor(distance))
        drawings.distText.Position = Vector2.new(headPos.X, drawings.box.Position.Y - 15)
        drawings.distText.Visible = true
    end
end)

local function onPlayerAdded(player)
    if player ~= LocalPlayer then
        createESP(player)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(removeESP)
